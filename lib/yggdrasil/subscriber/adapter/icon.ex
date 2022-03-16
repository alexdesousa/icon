defmodule Yggdrasil.Subscriber.Adapter.Icon do
  @moduledoc """
  Yggdrasil publisher adapter for Icon. The name of the channel should be a
  map with:

  - `:source` - Either `:block` or `:event` (required).
  - `:identity` - `Icon.RPC.Identity` instance pointed to the right network.
  - `:data` - Data for the subscription.
  - `:from_height` - Height to start receiving messages. Defaults to `:latest`.

  > **Important**: We need to be careful when using `from_height` in the channel
  > because `Yggdrasil` will restart the synchronization process from the
  > chosen height if the process crashes.

  e.g. given a proper channel name, then we can subscribe to ICON 2.0 `:block`
  websocket:
  ```
  iex(1)> Yggdrasil.subscribe(name: %{source: :block}, adapter: :icon)
  :ok
  iex(4)> flush()
  {:Y_CONNECTED, %Yggdrasil.Channel{name: %{source: :block}, (...)}}
  ```

  after that, we'll start receiving messages like the following:
  ```
  iex(6)> flush()
  {:Y_EVENT, %Yggdrasil.Channel{name: %{source: :block}, (...)}, %Yggdrasil.Icon.Block{hash: "0x...", (...)}}
  ```

  Finally, when we're done, we can unsubscribe from the channel:
  ```
  iex(7)> Yggdrasil.unsubscribe(name: %{source: :block}, adapter: :icon)
  :ok
  iex(8)> flush()
  {:Y_DISCONNECTED, %Yggdrasil.Channel{name: %{source: :block}, (...)}}
  ```
  """
  use GenServer
  use Bitwise
  use Yggdrasil.Subscriber.Adapter

  require Logger

  alias __MODULE__, as: State
  alias Icon.RPC.Identity
  alias Icon.Schema
  alias Icon.Schema.Types.Block.Tick
  alias Yggdrasil.Channel
  alias Yggdrasil.Config.Icon, as: Config
  alias Yggdrasil.Subscriber.Adapter.Icon.Message
  alias Yggdrasil.Subscriber.Manager

  @doc false
  defstruct url: nil,
            channel: nil,
            websocket: nil,
            module: nil,
            status: :disconnected,
            height: :latest,
            retries: 0,
            backoff: 0

  @typedoc false
  @type t :: %State{
          url: url :: binary(),
          channel: channel :: Channel.t(),
          websocket: websocket :: nil | WebSockex.client(),
          module: module :: module(),
          status: status :: :connected | :disconnected,
          height: height :: :latest | pos_integer(),
          retries: retries :: non_neg_integer(),
          backoff: backoff :: non_neg_integer()
        }

  ############
  # Public API

  @doc """
  Informs the `subscriber` process that the websocket is connected.
  """
  @spec send_connected(GenServer.server()) :: :ok
  def send_connected(subscriber) do
    GenServer.cast(subscriber, :connected)
  end

  @doc """
  Informs the `subscriber` of a new `frame`.
  """
  @spec send_frame(GenServer.server(), WebSockex.frame()) :: :ok
  def send_frame(subscriber, frame) do
    GenServer.cast(subscriber, {:frame, frame})
  end

  @doc """
  Informs the `subscriber` process that the websocket is disconnected.
  """
  @spec send_disconnected(GenServer.server(), term()) :: :ok
  def send_disconnected(subscriber, reason) do
    GenServer.cast(subscriber, {:disconnected, reason})
  end

  ################################
  # Yggdrasil Subscriber callbacks

  @impl Yggdrasil.Subscriber.Adapter
  def start_link(channel, options \\ [])

  def start_link(%Channel{} = channel, options) do
    GenServer.start_link(__MODULE__, channel, options)
  end

  @spec stop(GenServer.server()) :: :ok
  @spec stop(GenServer.server(), term()) :: :ok
  @spec stop(GenServer.server(), term(), :infinity | non_neg_integer()) :: :ok
  defdelegate stop(subscriber, reason \\ :normal, timeout \\ :infinity),
    to: GenServer

  #####################
  # GenServer callbacks

  @impl GenServer
  def init(%Channel{} = channel) do
    Process.flag(:trap_exit, true)
    state = gen_state(channel)
    log_started(state)

    {:ok, state, {:continue, :init}}
  end

  @impl GenServer
  def handle_continue(continue, state)

  def handle_continue(:init, %State{} = state) do
    initialize(state)
  end

  def handle_continue(:connected, %State{} = state) do
    connected(state)
  end

  def handle_continue({:backoff, reason}, %State{} = state) do
    backoff(reason, state)
  end

  @impl GenServer
  def handle_cast(
        :connected,
        %State{
          websocket: websocket,
          height: height,
          channel: channel,
          module: module
        } = state
      ) do
    message = Message.encode(height, channel)
    module.initialize(websocket, message)
    {:noreply, state}
  end

  def handle_cast({:frame, {:text, frame}}, %State{channel: channel} = state) do
    Message.publish(channel, frame)
    {:noreply, state}
  end

  def handle_cast({:disconnected, reason}, %State{} = state) do
    {:noreply, state, {:continue, {:backoff, reason}}}
  end

  @impl GenServer
  def handle_info(msg, state)

  def handle_info(:timeout, %State{} = state) do
    {:noreply, state, {:continue, :init}}
  end

  def handle_info({ref, :connected}, %State{} = state)
      when is_reference(ref) do
    {:noreply, state, {:continue, :connected}}
  end

  def handle_info({ref, {:ok, %Tick{height: height}}}, %State{} = state)
      when is_reference(ref) and is_integer(height) and height > 0 do
    {:noreply, %{state | height: height}}
  end

  def handle_info({ref, {:error, %Schema.Error{} = error}}, %State{} = state)
      when is_reference(ref) do
    {:noreply, state, {:continue, {:backoff, error}}}
  end

  def handle_info(
        {:DOWN, _, :process, websocket, reason},
        %State{websocket: websocket} = state
      ) do
    {:noreply, state, {:continue, {:backoff, reason}}}
  end

  def handle_info(_, %State{} = state) do
    {:noreply, state}
  end

  ##########################
  # State management helpers

  @spec initialize(t()) ::
          {:noreply, t()}
          | {:noreply, t(), {:continue, {:backoff, term()}}}
  defp initialize(state)

  defp initialize(%State{status: :disconnected, module: module} = state) do
    with {:ok, %State{url: url} = state} <- add_height(state),
         {:ok, websocket} <- module.start_link(url, []) do
      Process.monitor(websocket)
      state = %{state | websocket: websocket}
      {:noreply, state}
    else
      {:error, reason} ->
        {:noreply, state, {:continue, {:backoff, reason}}}
    end
  end

  @spec connected(t()) :: {:noreply, t()}
  defp connected(state)

  defp connected(%State{channel: channel, status: :disconnected} = state) do
    Manager.connected(channel)
    log_connected(state)
    {:noreply, %{state | status: :connected, retries: 0, backoff: 0}}
  end

  @spec backoff(term(), t()) :: {:noreply, t()}
  defp backoff(reason, state)

  defp backoff(
         reason,
         %State{
           channel: channel,
           module: module,
           websocket: websocket,
           status: :connected
         } = state
       ) do
    Manager.disconnected(channel)
    module.stop(websocket)
    log_disconnected(reason, state)

    new_state = %{state | websocket: nil, status: :disconnected}

    backoff(reason, new_state)
  end

  defp backoff(reason, %State{status: :disconnected, retries: current} = state) do
    max_retries = Config.max_retries!()
    slot_size = Config.slot_size!()

    padding = 2

    retries =
      if current >= max_retries,
        do: max_retries - padding,
        else: current - padding

    new_backoff = (2 <<< retries) * Enum.random(1..slot_size) * 1_000
    new_state = %{state | retries: current + 1, backoff: new_backoff}

    Process.send_after(self(), :timeout, new_backoff)

    log_retry(reason, new_state)

    {:noreply, new_state}
  end

  @impl GenServer
  def terminate(reason, state)

  def terminate(reason, %State{status: :disconnected} = state) do
    log_terminated(reason, state)
    :ok
  end

  def terminate(
        reason,
        %State{status: :connected, channel: channel} = state
      ) do
    Manager.disconnected(channel)
    log_terminated(reason, state)
    :ok
  end

  ########################
  # Initialization helpers

  @spec gen_state(Channel.t()) :: State.t()
  defp gen_state(channel)

  defp gen_state(%Channel{name: %{source: _}, adapter: :icon} = channel) do
    %State{
      url: endpoint(channel),
      channel: channel,
      module: Config.websocket_module!()
    }
  end

  @spec endpoint(Channel.t()) :: binary()
  defp endpoint(channel)

  defp endpoint(%Channel{name: %{source: source} = info}) do
    %Identity{node: node} = info[:identity] || Identity.new()

    "#{node}/api/v3/icon_dex/#{source}"
    |> URI.parse()
    |> case do
      %URI{scheme: "http"} = uri ->
        URI.to_string(%{uri | scheme: "ws"})

      %URI{scheme: "https"} = uri ->
        URI.to_string(%{uri | scheme: "wss"})
    end
  end

  @spec add_height(State.t()) :: {:ok, State.t()} | {:error, Schema.Error.t()}
  defp add_height(state)

  defp add_height(
         %State{
           height: :latest,
           channel: %Channel{name: %{from_height: height}}
         } = state
       )
       when is_integer(height) do
    {:ok, %{state | height: height}}
  end

  defp add_height(
         %State{
           height: height,
           channel: %Channel{name: %{source: :block}}
         } = state
       )
       when is_integer(height) and height > 0 do
    {:ok, state}
  end

  defp add_height(%State{channel: %Channel{name: info}} = state) do
    identity = info[:identity] || Identity.new()

    case Icon.get_block(identity) do
      {:ok, %Schema.Types.Block{height: height}} ->
        {:ok, %{state | height: height}}

      {:error, _} = error ->
        error
    end
  end

  #################
  # Logging helpers

  @spec log_started(State.t()) :: :ok
  defp log_started(%State{channel: channel, url: url}) do
    Logger.debug(fn ->
      "Started #{__MODULE__} for #{inspect(channel)} (#{url})"
    end)

    :ok
  end

  @spec log_connected(State.t()) :: :ok
  defp log_connected(%State{channel: channel, url: url}) do
    Logger.debug(fn ->
      "Connected #{__MODULE__} for #{inspect(channel)} (#{url})"
    end)

    :ok
  end

  @spec log_disconnected(term(), State.t()) :: :ok
  defp log_disconnected(reason, %State{channel: channel, url: url}) do
    Logger.warn(fn ->
      "Disconnected #{__MODULE__} for #{inspect(channel)} (#{url}) " <>
        "due to #{inspect(reason)}"
    end)

    :ok
  end

  @spec log_retry(term(), State.t()) :: :ok
  defp log_retry(_reason, %State{backoff: 0}), do: :ok

  defp log_retry(
         reason,
         %State{channel: channel, url: url, retries: retries, backoff: backoff}
       ) do
    Logger.warn(fn ->
      "#{__MODULE__} still unsubscribed from #{inspect(channel)} (#{url}) " <>
        "due to #{inspect(reason)} [retry: #{retries}, backoff: #{backoff} ms]"
    end)

    :ok
  end

  @spec log_terminated(WebSockex.close_reason(), State.t()) :: :ok
  defp log_terminated(reason, state)

  defp log_terminated(:normal, %State{channel: channel, url: url}) do
    Logger.info(fn ->
      "Stopped #{__MODULE__} for #{inspect(channel)} (#{url})"
    end)
  end

  defp log_terminated(reason, %State{channel: channel, url: url}) do
    Logger.warn(fn ->
      "Stopped #{__MODULE__} for #{inspect(channel)} (#{url}) " <>
        "due to #{inspect(reason)}"
    end)
  end
end
