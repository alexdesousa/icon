defmodule Icon.Stream.WebSocket do
  @moduledoc """
  This module defines an event producer that connects via websockets to an
  Icon node.

  ### Automatic Reconnections

  When the websocket gets disconnected from the ICON node, it will attempt to
  reconnect. If this immediate reconnection is not successful, then it will
  wait some time and try again. This waiting time is calculated using
  exponential backoff, to avoid overload the ICON node on reconnection:

  $$backoff(i) = 2^{i-2} * random(1, slot), i \\in [0, 3], slot = 10$$

  where `i` is incremented every time the process tries to reconnect until it
  reaches the maximum value.

  ### Buffering

  When the current buffer is full (see `Icon.Stream`), the process will stop
  the connection and wait for the buffer to have at least 50% space left.

  ### States

  The following finite state machine shows how the websocket process handles
  different connection states:

  ```mermaid
  graph TD
      %% Initialization
      start(Start) -- HTTP 1.1 connection --> connecting{Is it connected?}
      connecting -- Yes --> upgrade(Upgrade websocket)
      connecting -- No --> backoff(Wait for X seconds)
      backoff --> start

      %% Upgrade
      upgrade --> upgrading{Is it upgraded?}
      upgrading -- Yes --> initialize(Setup connection)
      upgrading -- No --> disconnect(Disconnect)
      disconnect --> backoff

      %% Initialization
      initialize --> initializing{Is it ready?}
      initializing -- Yes --> consume(Consume messages)
      initializing -- No --> disconnect

      %% Consuming
      consume --> consuming(Receive event)
      consuming --> sending{Are there any process waiting for events?}
      sending -- Yes --> send(Send event)
      sending -- No --> buffer{Is buffer full?}
      send --> reconnect

      %% Buffer not full
      buffer -- No --> buffering(Buffer event)
      buffering --> reconnect{Is disconnected?}
      reconnect -- Yes --> buffer_state{Is buffer at 50% capacity or less?}
      reconnect -- No --> consume
      buffer_state -- Yes --> start
      buffer_state --> sending

      %% Buffer full
      buffer -- Yes --> wait(Disconnect)
      wait --> sending
  ```
  """
  use GenStage

  require Logger
  import Bitwise

  alias __MODULE__, as: State

  @max_backoff_increments 3
  @backoff_slot_size 10

  @typedoc false
  @type status ::
          :starting
          | :connecting
          | :upgrading
          | :initializing
          | :setting_up
          | :consuming
          | :waiting
          | :terminating

  @doc false
  @enforce_keys [
    :stream,
    :status,
    :debug,
    :caller,
    :backoff,
    :backoff_retries
  ]
  defstruct stream: nil,
            pending_demand: 0,
            status: :starting,
            conn: nil,
            ref: nil,
            websocket: nil,
            debug: false,
            caller: nil,
            backoff: 0,
            backoff_retries: 0

  @typedoc false
  @type t :: %State{
          # Event stream fiels
          stream: Icon.Stream.t(),
          pending_demand: pending_demand :: non_neg_integer(),
          # Connection status fields
          status: status :: status(),
          conn: http_connection :: nil | Mint.Connection.t(),
          ref: http_connection_reference :: nil | Mint.Types.request_ref(),
          websocket: websocket_connection :: nil | Mint.WebSocket.t(),
          # Debug fields
          debug: debug :: boolean(),
          caller: caller :: pid(),
          # Backoff fields
          backoff: backoff_timeout :: non_neg_integer(),
          backoff_retries: backoff_retries :: non_neg_integer()
        }

  @doc """
  Starts an Icon event producer given an Icon `stream`. Optionally, it can
  receive some `GenServer` `options`.
  """
  @spec start_link(Icon.Stream.t()) :: GenServer.on_start()
  @spec start_link(Icon.Stream.t(), GenServer.options()) :: GenServer.on_start()
  def start_link(stream, options \\ [])

  def start_link(stream, options) do
    {debug, options} = Keyword.pop(options, :debug, false)

    state =
      struct(State,
        caller: self(),
        stream: stream,
        debug: debug
      )

    GenStage.start_link(__MODULE__, state, options)
  end

  @doc """
  Stops a `websocket`. Optionally, a `reason` and `timeout` can be provided,
  otherwise it will default to `:normal` and `:infinity` respectively.
  """
  @spec stop(GenServer.server()) :: :ok
  @spec stop(GenServer.server(), any()) :: :ok
  @spec stop(GenServer.server(), any(), timeout()) :: :ok
  defdelegate stop(websocket, reason \\ :normal, timeout \\ :infinity),
    to: GenServer

  ####################
  # Callback functions

  @impl GenStage
  def init(%State{} = state) do
    {:producer, schedule_connection(state)}
  end

  @impl GenStage
  def handle_demand(amount, %State{} = state)
      when amount > 0 do
    {new_state, demanded} = demand(state, amount)

    {:noreply, demanded, new_state}
  end

  @impl GenStage
  def handle_info(:connect, %State{status: :connecting} = state) do
    {:noreply, [], connect(state)}
  end

  def handle_info({tag, _, _} = message, %State{status: :upgrading} = state)
      when tag in [:tcp, :ssl] do
    new_state =
      state
      |> upgrade(message)
      |> initialize()

    {:noreply, [], new_state}
  end

  def handle_info({tag, _, _} = message, %State{} = state)
      when tag in [:tcp, :ssl] do
    {new_state, demanded} =
      state
      |> listen(message)
      |> demand()

    {:noreply, demanded, new_state}
  end

  def handle_info({tag, _}, %State{status: status} = state)
      when tag in [:tcp_closed, :ssl_closed] and
             status not in [:waiting, :terminating] do
    new_state =
      state
      |> disconnect()
      |> schedule_connection()

    {:noreply, [], new_state}
  end

  def handle_info({tag, _}, %State{status: :waiting} = state)
      when tag in [:tcp_closed, :ssl_closed] do
    {:noreply, [], wait(state)}
  end

  def handle_info(_, %State{status: status} = state)
      when status in [:waiting, :terminating] do
    {:noreply, [], state}
  end

  @impl GenStage
  def terminate(reason, %State{} = state) do
    terminating(reason, state)

    :ok
  end

  ############################
  # Debugging helper functions

  @spec change_status(t(), status()) :: t()
  defp change_status(state, status)

  defp change_status(%State{status: status} = state, status) do
    state
  end

  defp change_status(%State{debug: true, caller: caller} = state, status) do
    send(caller, {:"$icon_websocket", status})
    %State{state | status: status}
  end

  defp change_status(%State{} = state, status) do
    %State{state | status: status}
  end

  #############################
  # Scheduling helper functions

  @spec schedule_connection(t()) :: t()
  defp schedule_connection(state)

  defp schedule_connection(%State{conn: nil, backoff_retries: retries} = state) do
    increments =
      if retries > @max_backoff_increments do
        @max_backoff_increments
      else
        retries
      end

    new_backoff_timeout =
      (2 <<< (increments - 2)) * Enum.random(1..@backoff_slot_size) * 1_000

    %State{state | backoff: new_backoff_timeout}
    |> do_schedule_connection()
  end

  @spec do_schedule_connection(t()) :: t()
  defp do_schedule_connection(
         %State{
           backoff: backoff_timeout,
           backoff_retries: retries
         } = state
       ) do
    Process.send_after(self(), :connect, backoff_timeout)

    %State{state | backoff_retries: retries + 1}
    |> change_status(:connecting)
  end

  @spec maybe_schedule_connection(t()) :: t()
  defp maybe_schedule_connection(state)

  defp maybe_schedule_connection(
         %State{
           status: :waiting,
           conn: nil,
           stream: stream
         } = state
       ) do
    if Icon.Stream.check_space_left(stream) >= 0.5 do
      schedule_connection(state)
    else
      state
    end
  end

  defp maybe_schedule_connection(%State{} = state) do
    state
  end

  #############################
  # Connection helper functions

  @spec connect(t()) :: t()
  defp connect(state)

  defp connect(
         %State{
           status: :connecting,
           stream: stream
         } = state
       ) do
    uri = Icon.Stream.to_uri(stream)
    options = [protocols: [:http1]]

    with {:ok, conn} <-
           Mint.HTTP.connect(scheme(uri), uri.host, uri.port, options),
         {:ok, conn, ref} <-
           Mint.WebSocket.upgrade(ws_scheme(uri), conn, uri.path, []) do
      log_connected()

      %State{
        state
        | conn: conn,
          ref: ref,
          websocket: nil,
          backoff: 0,
          backoff_retries: 0
      }
      |> change_status(:upgrading)
    else
      {:error, _} ->
        disconnect(state)

      {:error, conn, _} ->
        disconnect(%State{state | conn: conn})
    end
  end

  @spec scheme(URI.t()) :: :http | :https
  defp scheme(uri)
  defp scheme(%URI{scheme: "https"} = _uri), do: :https
  defp scheme(%URI{} = _uri), do: :http

  @spec ws_scheme(URI.t()) :: :ws | :wss
  defp ws_scheme(uri)
  defp ws_scheme(%URI{scheme: "https"} = _uri), do: :wss
  defp ws_scheme(%URI{} = _uri), do: :ws

  ################################
  # Disconnection helper functions

  @spec disconnect(t()) :: t()
  defp disconnect(state)

  defp disconnect(%State{conn: nil} = state) do
    log_disconnected()

    %State{
      state
      | conn: nil,
        ref: nil,
        websocket: nil
    }
    |> change_status(:connecting)
  end

  defp disconnect(%State{conn: conn} = state) do
    Mint.HTTP.close(conn)

    disconnect(%State{state | conn: nil})
  end

  @spec terminating(any(), t()) :: t()
  defp terminating(reason, state)

  defp terminating(reason, %State{conn: nil} = state) do
    log_terminated(reason)

    %State{
      state
      | conn: nil,
        ref: nil,
        websocket: nil
    }
    |> change_status(:terminating)
  end

  defp terminating(reason, %State{conn: conn} = state) do
    Mint.HTTP.close(conn)

    terminating(reason, %State{state | conn: nil})
  end

  ##########################
  # Upgrade helper functions

  @spec upgrade(t(), any()) :: t()
  defp upgrade(state, message)

  defp upgrade(
         %State{
           conn: conn,
           ref: ref,
           status: :upgrading
         } = state,
         message
       ) do
    with {:ok, conn,
          [
            {:status, ^ref, status},
            {:headers, ^ref, headers},
            {:done, ^ref}
          ]} <-
           Mint.WebSocket.stream(conn, message),
         {:ok, conn, websocket} <-
           Mint.WebSocket.new(conn, ref, status, headers) do
      log_upgraded()

      %State{
        state
        | conn: conn,
          websocket: websocket
      }
      |> change_status(:initializing)
    else
      {:error, conn, _, _} ->
        disconnect(%State{state | conn: conn})

      :unknown ->
        disconnect(state)
    end
  end

  #################################
  # Initialization helper functions

  @spec initialize(t()) :: t()
  defp initialize(state)

  defp initialize(
         %State{
           stream: stream,
           conn: conn,
           ref: ref,
           websocket: websocket,
           status: :initializing
         } = state
       ) do
    message = {:text, Icon.Stream.encode(stream)}

    with {:ok, websocket, data} <- Mint.WebSocket.encode(websocket, message),
         {:ok, conn} <- Mint.WebSocket.stream_request_body(conn, ref, data) do
      %State{
        state
        | conn: conn,
          websocket: websocket
      }
      |> change_status(:setting_up)
    else
      {:error, %Mint.WebSocket{} = _websocket, _} ->
        disconnect(state)

      {:error, conn, _} ->
        disconnect(%State{state | conn: conn})

      :error ->
        disconnect(state)
    end
  end

  ############################
  # Listening helper functions

  @spec listen(t(), any()) :: t()
  defp listen(state, message)

  defp listen(%State{} = state, message) do
    case decode(state, message) do
      {:ok, new_state, [%{"code" => 0} | messages]} ->
        log_listening()

        new_state
        |> change_status(:consuming)
        |> handle_messages(messages)

      {:ok, new_state, [%{"code" => _} = error | _messages]} ->
        log_error(error)

        new_state
        |> disconnect()
        |> schedule_connection()

      {:ok, new_state, messages} ->
        handle_messages(new_state, messages)

      {:error, new_state} ->
        new_state
    end
  end

  @spec decode(t(), any()) ::
          {:ok, t(), any()}
          | {:error, t()}
  defp decode(
         %State{conn: conn, ref: ref, websocket: websocket} = state,
         message
       ) do
    with {:ok, conn, [{:data, ^ref, data}]} <-
           Mint.WebSocket.stream(conn, message),
         {:ok, websocket, frames} <-
           Mint.WebSocket.decode(websocket, data) do
      new_state = %State{
        state
        | conn: conn,
          websocket: websocket
      }

      {:ok, new_state, decode_frames(frames)}
    else
      {:error, conn, _, _} ->
        new_state = disconnect(%State{state | conn: conn})
        {:error, new_state}

      _ ->
        new_state = disconnect(state)
        {:error, new_state}
    end
  end

  @spec decode_frames([Mint.WebSocket.frame()]) :: [map()]
  defp decode_frames(frames, acc \\ [])

  defp decode_frames([], acc) do
    Enum.reverse(acc)
  end

  defp decode_frames([{:text, data} | rest], acc) do
    decoded = Jason.decode!(data)

    decode_frames(rest, [decoded | acc])
  end

  defp decode_frames([_ | rest], acc) do
    decode_frames(rest, acc)
  end

  @spec handle_messages(t(), [map()]) :: t()
  defp handle_messages(state, events)

  defp handle_messages(
         %State{status: :consuming, stream: stream} = state,
         events
       ) do
    Icon.Stream.put(stream, events)

    if Icon.Stream.is_full?(stream), do: wait(state), else: state
  end

  ##########################
  # Waiting helper functions

  @spec wait(t()) :: t()
  defp wait(state)

  defp wait(%State{conn: nil} = state) do
    log_wait()

    %State{
      state
      | conn: nil,
        ref: nil,
        websocket: nil
    }
    |> change_status(:waiting)
  end

  defp wait(%State{conn: conn} = state) do
    Mint.HTTP.close(conn)

    wait(%State{state | conn: nil})
  end

  #########################
  # Demand helper functions

  @spec demand(t()) :: {t(), [map()]}
  @spec demand(t(), nil | pos_integer()) :: {t(), [map()]}
  defp demand(state, amount \\ nil)

  defp demand(%State{pending_demand: pending_demand} = state, nil) do
    %State{state | pending_demand: 0}
    |> demand(pending_demand)
  end

  defp demand(%State{stream: stream} = state, amount) do
    demand = Icon.Stream.pop(stream, amount)
    fulfilled_demand = length(demand)

    new_state =
      %State{state | pending_demand: amount - fulfilled_demand}
      |> maybe_schedule_connection()

    {new_state, demand}
  end

  ##########################
  # Logging helper functions

  @spec log_connected() :: :ok
  defp log_connected do
    Logger.debug("Connected to Icon node")
  end

  @spec log_upgraded() :: :ok
  defp log_upgraded do
    Logger.debug("Upgraded connection to websocket")
  end

  @spec log_listening() :: :ok
  defp log_listening do
    Logger.debug("Listening to Icon node events")
  end

  @spec log_wait() :: :ok
  defp log_wait do
    Logger.debug("Waiting for consumers (buffer is full)")
  end

  @spec log_error(map()) :: :ok
  defp log_error(error)

  defp log_error(%{"code" => code} = reason) do
    error = Icon.Schema.Error.new(code: code, message: reason["message"])
    Logger.warn("Error message received: #{inspect(error)}")
  end

  @spec log_disconnected() :: :ok
  defp log_disconnected do
    Logger.warn("Disconnected to Icon node")
  end

  @spec log_terminated(any()) :: :ok
  defp log_terminated(reason)

  defp log_terminated(:normal) do
    Logger.debug("Terminated websocket connection with Icon node")
  end

  defp log_terminated(reason) do
    Logger.warn(
      "Terminated websocket connection with Icon node due to: #{inspect(reason)}"
    )
  end
end
