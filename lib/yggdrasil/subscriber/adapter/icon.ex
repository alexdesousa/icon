defmodule Yggdrasil.Subscriber.Adapter.Icon do
  @moduledoc """
  Yggdrasil publisher adapter for Icon. The name of the channel should be a
  map with:

  - `:source` - Either `:block` or `:event` (required).
  - `:identity` - `Icon.RPC.Identity` instance pointed to the right network.
  - `:data` - Data for the subscription.

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
  use WebSockex
  use Yggdrasil.Subscriber.Adapter

  require Logger

  alias __MODULE__, as: State
  alias Icon.RPC.Identity
  alias Icon.Schema
  alias Yggdrasil.Channel
  alias Yggdrasil.Subscriber.Manager
  alias Yggdrasil.Subscriber.Publisher

  @doc false
  defstruct url: nil,
            channel: nil,
            state: :initializing,
            height: nil

  @typedoc false
  @type t :: %State{
          url: url :: binary(),
          channel: channel :: Channel.t(),
          state: state :: :initializing | :connected | :disconnected,
          height: height :: nil | pos_integer()
        }

  ################################
  # Yggdrasil Subscriber callbacks

  @impl Yggdrasil.Subscriber.Adapter
  def start_link(channel, options \\ [])

  def start_link(%Channel{} = channel, options) do
    state = gen_state(channel)
    options = Keyword.put_new(options, :handle_initial_conn_failure, true)

    WebSockex.start_link(state.url, __MODULE__, state, options)
  end

  #####################
  # WebSockex callbacks

  @impl WebSockex
  def handle_connect(%WebSockex.Conn{}, %State{channel: channel} = state) do
    Manager.connected(channel)
    initialize()
    connected(state)

    {:ok, %{add_height(state) | state: :connected}}
  end

  @impl WebSockex
  def handle_info(call, state)

  def handle_info(:init, %State{} = state) do
    {:reply, initial_message(state), state}
  end

  @impl WebSockex
  def handle_frame(frame, state)

  def handle_frame(
        {:text, frame},
        %State{channel: %Channel{} = channel} = state
      ) do
    case Jason.decode(frame) do
      {:ok, %{"code" => 0}} ->
        {:ok, state}

      {:ok, %{"code" => code, "message" => message}} ->
        crash(state, Schema.Error.new(code: code, message: message))

      {:ok, decoded} ->
        Publisher.notify(channel, decoded)
        {:ok, state}

      {:error, _} ->
        reason = "cannot decode channel message"
        crash(state, Schema.Error.new(code: -32_000, message: reason))
    end
  end

  def handle_frame(_, %State{} = state) do
    {:ok, state}
  end

  @impl WebSockex
  def handle_disconnect(status, state)

  def handle_disconnect(status, %State{state: :initializing} = state) do
    retry(status, state)
    {:reconnect, state}
  end

  def handle_disconnect(status, %State{state: :disconnected} = state) do
    retry(status, state)
    {:reconnect, state}
  end

  def handle_disconnect(
        status,
        %State{channel: channel, state: :connected} = state
      ) do
    Manager.disconnected(channel)
    disconnected(status, state)

    {:reconnect, %{state | state: :disconnected}}
  end

  @impl WebSockex
  def terminate(reason, state)

  def terminate(reason, %State{state: :initializing} = state) do
    terminated(reason, state)
    :ok
  end

  def terminate(reason, %State{state: :disconnected} = state) do
    terminated(reason, state)
    :ok
  end

  def terminate(
        reason,
        %State{state: :connected, channel: %Channel{} = channel} = state
      ) do
    Manager.disconnected(channel)
    terminated(reason, state)
    :ok
  end

  #########
  # Helpers

  @spec gen_state(Channel.t()) :: State.t()
  defp gen_state(channel)

  defp gen_state(%Channel{name: %{source: _}, adapter: :icon} = channel) do
    %State{
      url: endpoint(channel),
      channel: channel
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

  @spec initialize() :: :ok
  defp initialize do
    Process.send_after(self(), :init, 0)
    :ok
  end

  @spec add_height(State.t()) :: State.t() | no_return()
  defp add_height(state)

  defp add_height(%State{channel: %Channel{name: info}} = state) do
    identity = info[:identity] || Identity.new()

    case Icon.get_block(identity) do
      {:ok, %Schema.Types.Block{height: height}} ->
        %{state | height: height}

      {:error, %Schema.Error{} = error} ->
        crash(state, error)
    end
  end

  @spec initial_message(State.t()) :: WebSockex.frame()
  defp initial_message(state)

  defp initial_message(%State{
         height: height,
         channel: %Channel{name: %{source: :block}} = channel
       }) do
    build_block_message(height, channel)
  end

  defp initial_message(%State{
         height: height,
         channel: %Channel{name: %{source: :event}} = channel
       }) do
    build_event_message(height, channel)
  end

  @spec build_block_message(pos_integer(), Channel.t()) :: any()
  defp build_block_message(height, channel)

  defp build_block_message(height, %Channel{} = _channel) do
    {:ok, height} = Icon.Schema.Types.Integer.dump(height)
    {:text, Jason.encode!(%{height: height})}
  end

  @spec build_event_message(pos_integer(), Channel.t()) :: any()
  defp build_event_message(height, channel)

  defp build_event_message(height, %Channel{name: %{data: %{event: event}}}) do
    {:ok, height} = Icon.Schema.Types.Integer.dump(height)
    {:text, Jason.encode!(%{height: height, event: event})}
  end

  #################
  # Logging helpers

  @spec connected(State.t()) :: :ok
  defp connected(%State{channel: channel, url: url}) do
    Logger.info(fn ->
      "#{__MODULE__} subscribed to #{inspect(channel)} (#{url})"
    end)

    :ok
  end

  @spec disconnected(WebSockex.connection_status_map(), State.t()) :: :ok
  defp disconnected(%{reason: reason}, %State{channel: channel, url: url}) do
    Logger.warn(fn ->
      "#{__MODULE__} unsubscribed from #{inspect(channel)} (#{url}) " <>
        "due to #{inspect(reason)}"
    end)

    :ok
  end

  @spec retry(WebSockex.connection_status_map(), State.t()) :: :ok
  defp retry(
         %{reason: reason, attempt_number: retry},
         %State{channel: channel, url: url}
       ) do
    Logger.warn(fn ->
      "#{__MODULE__} still unsubscribed from #{inspect(channel)} (#{url}) " <>
        "due to #{inspect(reason)} [retry: #{retry}]"
    end)

    :ok
  end

  @spec crash(State.t(), Schema.Error.t()) :: no_return()
  defp crash(
         %State{channel: channel, url: url},
         %Schema.Error{message: message, reason: reason}
       ) do
    Manager.disconnected(channel)

    Logger.error(fn ->
      "#{__MODULE__} cannot get the current block heigh " <>
        "for #{inspect(channel)} (#{url}) " <>
        "due to #{message} [reason: #{reason}]"
    end)

    raise RuntimeError,
      message: "cannot get current block height due to #{message} [#{reason}]"
  end

  @spec terminated(WebSockex.close_reason(), State.t()) :: :ok
  defp terminated(reason, state)

  defp terminated(:normal, %State{channel: channel, url: url}) do
    Logger.info(fn ->
      "#{__MODULE__} stopped for #{inspect(channel)} (#{url})"
    end)
  end

  defp terminated(reason, %State{channel: channel, url: url}) do
    Logger.warn(fn ->
      "#{__MODULE__} stopped for #{inspect(channel)} (#{url}) " <>
        "due to #{inspect(reason)}"
    end)
  end
end
