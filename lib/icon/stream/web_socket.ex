defmodule Icon.Stream.WebSocket do
  @moduledoc """
  This module defines an event producer that connects via websockets to an
  Icon node.
  """
  use GenServer

  require Logger

  alias __MODULE__, as: State
  alias Icon.RPC.Identity
  alias Icon.Schema
  alias Icon.Schema.Types.Block.Tick

  @sources [:block, :event]
  @max_buffer_size 1_000

  @typedoc """
  Source of the events.
  """
  @type source ::
          :block
          | :event

  @typedoc false
  @type status ::
          :connecting
          | :upgrading
          | :initializing
          | :setting_up
          | :consuming
          | :waiting
          | :terminating

  @doc false
  defstruct status: :connecting,
            buffer: [],
            max_buffer_size: @max_buffer_size,
            height: 0,
            identity: nil,
            source: nil,
            conn: nil,
            ref: nil,
            websocket: nil

  @typedoc false
  @type t :: %State{
          identity: identity :: Identity.t(),
          source: source :: source(),
          status: status :: status(),
          buffer: buffer :: :queue.queue(Tick.t()),
          max_buffer_size: max_buffer_size :: pos_integer(),
          height: block_height :: non_neg_integer(),
          conn: http_connection :: nil | Mint.Connection.t(),
          ref: http_connection_reference :: nil | Mint.Types.request_ref(),
          websocket: websocket_connection :: nil | Mint.WebSocket.t()
        }

  @doc """
  Starts an Icon event producer given an `identity` and the `source` of the
  events. Optionally, it can receive some `GenServer` `options`.
  """
  @spec start_link(Identity.t(), source()) :: GenServer.on_start()
  @spec start_link(Identity.t(), source(), GenServer.options()) ::
          GenServer.on_start()
  def start_link(identity, source, options \\ [])

  def start_link(%Identity{} = identity, source, options)
      when source in @sources do
    state = %State{
      identity: identity,
      source: source,
      buffer: :queue.new()
    }

    GenServer.start_link(__MODULE__, state, options)
  end

  @doc """
  Gets an `amount` of ticks from a `websocket`. The `amount` of ticks defaults
  to `1`.
  """
  @spec get(GenServer.server()) :: [Tick.t()]
  @spec get(GenServer.server(), pos_integer()) :: [Tick.t()]
  def get(websocket, amount \\ 1)

  def get(websocket, amount) do
    GenServer.call(websocket, {:demand, amount})
  end

  @doc """
  Stops a `websocket`. Optionally, a `reason` and `timeout` can be provided,
  otherwise it will default to `:normal` and `:infinity` respectively.
  """
  @spec stop(GenServer.server()) :: :ok
  @spec stop(GenServer.server(), any()) :: :ok
  @spec stop(GenServer.server(), any(), GenServer.timeout()) :: :ok
  defdelegate stop(websocket, reason \\ :normal, timeout \\ :infinity),
    to: GenServer

  ####################
  # Callback functions

  @impl GenServer
  def init(%State{} = state) do
    {:ok, schedule_connection(state)}
  end

  @impl GenServer
  def handle_call({:demand, amount}, _from, %State{} = state)
      when amount > 0 do
    {new_state, demanded} = demand(state, amount)

    {:reply, demanded, new_state}
  end

  @impl GenServer
  def handle_info(:connect, %State{status: :connecting} = state) do
    {:noreply, connect(state)}
  end

  def handle_info({tag, _, _} = message, %State{status: :upgrading} = state)
      when tag in [:tcp, :ssl] do
    new_state =
      state
      |> upgrade(message)
      |> initialize()

    {:noreply, new_state}
  end

  def handle_info({tag, _, _} = message, %State{} = state)
      when tag in [:tcp, :ssl] do
    {:noreply, listen(state, message)}
  end

  def handle_info({tag, _}, %State{status: status} = state)
      when tag in [:tcp_closed, :ssl_closed] and
             status not in [:waiting, :terminating] do
    new_state =
      state
      |> disconnect()
      |> schedule_connection()

    {:noreply, new_state}
  end

  def handle_info({tag, _}, %State{status: status} = state)
      when tag in [:tcp_closed, :ssl_closed] and
             status in [:waiting, :terminating] do
    {:noreply, wait(state)}
  end

  def handle_info(_, %State{status: status} = state)
      when status in [:waiting, :terminating] do
    {:noreply, state}
  end

  @impl GenServer
  def terminate(reason, %State{} = state) do
    disconnect(state)
    log_terminated(reason)

    :ok
  end

  #############################
  # Scheduling helper functions

  @spec schedule_connection(t()) :: t()
  defp schedule_connection(state)

  defp schedule_connection(%State{conn: nil} = state) do
    # TODO: backoff
    Process.send_after(self(), :connect, 0)

    %State{state | status: :connecting}
  end

  @spec maybe_schedule_connection(t()) :: t()
  defp maybe_schedule_connection(state)

  defp maybe_schedule_connection(
         %State{
           status: :waiting,
           conn: nil,
           buffer: buffer,
           max_buffer_size: max_buffer_size
         } = state
       ) do
    if :queue.len(buffer) <= max_buffer_size / 2 do
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
           identity: %Identity{} = identity,
           source: source,
           status: :connecting
         } = state
       ) do
    uri = endpoint_uri(identity, source)
    options = [protocols: [:http1]]

    with {:ok, conn} <-
           Mint.HTTP.connect(scheme(uri), uri.host, uri.port, options),
         {:ok, conn, ref} <-
           Mint.WebSocket.upgrade(ws_scheme(uri), conn, uri.path, []) do
      log_connected()

      %State{
        state
        | status: :upgrading,
          conn: conn,
          ref: ref,
          websocket: nil
      }
    else
      {:error, _} ->
        disconnect(state)

      {:error, conn, _} ->
        disconnect(%State{state | conn: conn})
    end
  end

  @spec endpoint_uri(Identity.t(), source()) :: URI.t()
  defp endpoint_uri(%Identity{node: node}, source) do
    url = "#{node}/api/v3/icon_dex/#{source}"
    URI.parse(url)
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
      | status: :connecting,
        conn: nil,
        ref: nil,
        websocket: nil
    }
  end

  defp disconnect(%State{conn: conn} = state) do
    Mint.HTTP.close(conn)

    disconnect(%State{state | conn: nil})
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
        | status: :initializing,
          conn: conn,
          websocket: websocket
      }
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
           conn: conn,
           ref: ref,
           websocket: websocket,
           status: :initializing
         } = state
       ) do
    with {:ok, message} <- initial_message(state),
         {:ok, websocket, data} <- Mint.WebSocket.encode(websocket, message),
         {:ok, conn} <- Mint.WebSocket.stream_request_body(conn, ref, data) do
      %State{
        state
        | status: :setting_up,
          conn: conn,
          websocket: websocket
      }
    else
      {:error, %Mint.WebSocket{} = _websocket, _} ->
        disconnect(state)

      {:error, conn, _} ->
        disconnect(%State{state | conn: conn})

      :error ->
        disconnect(state)
    end
  end

  @spec initial_message(t()) ::
          {:ok, Mint.WebSocket.frame()}
          | :error
  defp initial_message(state)

  defp initial_message(%State{height: height}) do
    request = %{
      height: Schema.Type.dump!(Schema.Types.Integer, height)
    }

    {:ok, {:text, Jason.encode!(request)}}
  end

  ############################
  # Listening helper functions

  @spec listen(t(), any()) :: t()
  defp listen(state, message)

  defp listen(%State{} = state, message) do
    case decode(state, message) do
      {:ok, new_state, [%{"code" => 0} | messages]} ->
        log_listening()
        handle_messages(%State{new_state | status: :consuming}, messages)

      {:ok, new_state, [%{"code" => _, "message" => _} = error | _messages]} ->
        log_error(error)
        disconnect(new_state)

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

  @spec decode_frames([Mint.WebSocket.frame()]) :: [Tick.t() | map()]
  defp decode_frames(frames, acc \\ [])

  defp decode_frames([], acc) do
    Enum.reverse(acc)
  end

  defp decode_frames([{:text, "{\"code\":" <> _ = data} | rest], acc) do
    decoded = Jason.decode!(data)

    decode_frames(rest, [decoded | acc])
  end

  defp decode_frames([{:text, data} | rest], acc) do
    event = Jason.decode!(data)

    Tick
    |> Schema.generate()
    |> Schema.new(event)
    |> Schema.load()
    |> Schema.apply(into: Tick)
    |> case do
      {:ok, %Tick{} = tick} ->
        decode_frames(rest, [tick | acc])

      {:error, reason} ->
        log_error(reason)
        decode_frames(rest, acc)
    end
  end

  defp decode_frames([_ | rest], acc) do
    decode_frames(rest, acc)
  end

  @spec handle_messages(t(), [Tick.t()]) :: t()
  defp handle_messages(state, frames)

  defp handle_messages(
         %State{buffer: buffer, max_buffer_size: max_buffer_size} = state,
         []
       ) do
    if :queue.len(buffer) >= max_buffer_size do
      wait(state)
    else
      state
    end
  end

  defp handle_messages(
         %State{status: :consuming, buffer: buffer} = state,
         [%Tick{} = message | rest]
       ) do
    new_buffer = :queue.in(message, buffer)
    new_state = %State{state | buffer: new_buffer}
    handle_messages(new_state, rest)
  end

  ##########################
  # Waiting helper functions

  @spec wait(t()) :: t()
  defp wait(state)

  defp wait(%State{conn: nil} = state) do
    log_wait()

    %State{
      state
      | status: :waiting,
        conn: nil,
        ref: nil,
        websocket: nil
    }
  end

  defp wait(%State{conn: conn} = state) do
    Mint.HTTP.close(conn)

    wait(%State{state | conn: nil})
  end

  #########################
  # Demand helper functions

  @spec demand(t(), pos_integer()) :: {t(), [Tick.t()]}
  defp demand(state, amount)

  defp demand(%State{buffer: buffer, height: height} = state, amount) do
    buffer_size = :queue.len(buffer)
    amount = if buffer_size >= amount, do: amount, else: buffer_size

    {demand, new_buffer} = :queue.split(amount, buffer)

    new_height =
      case :queue.peek_r(demand) do
        :empty ->
          height

        {:value, %Tick{height: height}} ->
          height
      end

    new_state = %State{
      state
      | buffer: new_buffer,
        height: new_height
    }

    {maybe_schedule_connection(new_state), :queue.to_list(demand)}
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

  defp log_error(%{"code" => code, "message" => message}) do
    error = Icon.Schema.Error.new(code: code, message: message)
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
