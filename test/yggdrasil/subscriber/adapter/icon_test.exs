defmodule Yggdrasil.Subscriber.Adapter.IconTest do
  use ExUnit.Case, async: true

  alias Icon.RPC.Identity
  alias Icon.Schema.Types.Block.Tick
  alias Yggdrasil.Backend
  alias Yggdrasil.Subscriber.Adapter.Icon, as: Subscriber
  alias Yggdrasil.Subscriber.Manager
  alias Yggdrasil.Subscriber.Publisher

  @moduletag capture_log: true

  defmodule WebSocketMock do
    use GenServer

    defstruct test_pid: nil,
              url: nil,
              subscriber: nil

    ##########
    # Contract

    def start_link(url, _options) do
      state = %__MODULE__{
        url: url,
        subscriber: self()
      }

      GenServer.start_link(__MODULE__, state, [])
    end

    def stop(pid) do
      if Process.alive?(pid),
        do: GenServer.stop(pid),
        else: :ok
    end

    def initialize(pid, message) do
      GenServer.cast(pid, {:init, message})
    end

    ##############
    # Test helpers

    def register(pid) do
      GenServer.call(pid, {:register, self()})
    end

    def trigger_connected(pid) do
      GenServer.call(pid, :connected)
    end

    def trigger_disconnected(pid, reason) do
      GenServer.call(pid, {:disconnected, reason})
    end

    def trigger_frame(pid, message) do
      GenServer.call(pid, {:frame, message})
    end

    ###########
    # Callbacks

    @impl GenServer
    def init(%__MODULE__{} = state) do
      {:ok, state}
    end

    @impl GenServer
    def handle_call({:register, pid}, _from, %__MODULE__{} = state) do
      {:reply, :ok, %{state | test_pid: pid}}
    end

    def handle_call(:connected, _from, %__MODULE__{} = state) do
      Subscriber.send_connected(state.subscriber)
      {:reply, :ok, state}
    end

    def handle_call({:disconnected, reason}, _from, %__MODULE__{} = state) do
      Subscriber.send_disconnected(state.subscriber, reason)
      {:reply, :ok, state}
    end

    def handle_call({:frame, frame}, _from, %__MODULE__{} = state) do
      Subscriber.send_frame(state.subscriber, frame)
      {:reply, :ok, state}
    end

    @impl GenServer
    def handle_cast({:init, _} = message, %__MODULE__{} = state) do
      send(state.test_pid, message)
      {:noreply, state}
    end
  end

  setup do
    Yggdrasil.Config.Icon.put_websocket_module(WebSocketMock)

    bypass = Bypass.open()
    identity = Identity.new(node: "http://localhost:#{bypass.port}")

    assert {:ok, channel} =
             Yggdrasil.gen_channel(
               name: %{source: :block, identity: identity},
               adapter: :icon
             )

    # Subscribes to the channel
    Backend.subscribe(channel)

    via_tuple = ExReg.local({Manager, channel})
    {:ok, _manager} = Manager.start_link(channel, self(), name: via_tuple)

    via_tuple = ExReg.local({Publisher, channel})
    {:ok, _publisher} = Publisher.start_link(channel, name: via_tuple)

    {:ok, bypass: bypass, channel: channel}
  end

  test "initializes the connection when connects to server", %{
    bypass: bypass,
    channel: channel
  } do
    Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
      result = result(%{"height" => 42})
      Plug.Conn.resp(conn, 200, result)
    end)

    assert {:ok, pid} = Subscriber.start_link(channel)

    websocket = get_websocket(pid)
    :ok = WebSocketMock.register(websocket)
    :ok = WebSocketMock.trigger_connected(websocket)

    assert_receive {:init, {:text, message}}
    assert {:ok, %{"height" => "0x2a"}} = Jason.decode(message)
  end

  test "goes to backoff when there's an error on initialization", %{
    bypass: bypass,
    channel: channel
  } do
    Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
      result =
        error(%{
          "code" => -32_000,
          "message" => "Server error"
        })

      Plug.Conn.resp(conn, 400, result)
    end)

    assert {:ok, pid} = Subscriber.start_link(channel)

    assert %Subscriber{
             retries: 1,
             backoff: 0,
             status: :disconnected,
             websocket: nil
           } = get_state(pid)
  end

  test "when websocket accepts the initialization, sets the state as connected",
       %{
         bypass: bypass,
         channel: channel
       } do
    Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
      result = result(%{"height" => 42})
      Plug.Conn.resp(conn, 200, result)
    end)

    assert {:ok, pid} = Subscriber.start_link(channel)

    websocket = get_websocket(pid)
    :ok = WebSocketMock.register(websocket)
    :ok = WebSocketMock.trigger_connected(websocket)
    assert_receive {:init, {:text, _message}}

    :ok = WebSocketMock.trigger_frame(websocket, {:text, ~s({"code":0})})
    assert_receive {:Y_CONNECTED, ^channel}

    assert %Subscriber{
             retries: 0,
             backoff: 0,
             status: :connected,
             websocket: ^websocket
           } = get_state(pid)
  end

  test "when websocket disconnected, sets the state as disconnected",
       %{
         bypass: bypass,
         channel: channel
       } do
    Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
      result = result(%{"height" => 42})
      Plug.Conn.resp(conn, 200, result)
    end)

    assert {:ok, pid} = Subscriber.start_link(channel)

    websocket = get_websocket(pid)
    :ok = WebSocketMock.register(websocket)
    :ok = WebSocketMock.trigger_connected(websocket)
    assert_receive {:init, {:text, _message}}

    :ok = WebSocketMock.trigger_frame(websocket, {:text, ~s({"code":0})})
    assert_receive {:Y_CONNECTED, ^channel}

    :ok = WebSocketMock.trigger_disconnected(websocket, :shutdown)
    assert_receive {:Y_DISCONNECTED, ^channel}

    assert %Subscriber{
             retries: 1,
             backoff: 0,
             status: :disconnected,
             websocket: nil
           } = get_state(pid)
  end

  test "when websocket gets invalid frame, sets the state as disconnected",
       %{
         bypass: bypass,
         channel: channel
       } do
    Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
      result = result(%{"height" => 42})
      Plug.Conn.resp(conn, 200, result)
    end)

    assert {:ok, pid} = Subscriber.start_link(channel)

    websocket = get_websocket(pid)
    :ok = WebSocketMock.register(websocket)
    :ok = WebSocketMock.trigger_connected(websocket)
    assert_receive {:init, {:text, _message}}

    :ok = WebSocketMock.trigger_frame(websocket, {:text, ~s({"code":0})})
    assert_receive {:Y_CONNECTED, ^channel}

    :ok = WebSocketMock.trigger_frame(websocket, {:text, ~s(invalid)})

    assert_receive {:Y_DISCONNECTED, ^channel}

    assert %Subscriber{
             retries: 1,
             backoff: 0,
             status: :disconnected,
             websocket: nil
           } = get_state(pid)
  end

  test "when websocket disconnected, does not send disconnect message on termination",
       %{
         bypass: bypass,
         channel: channel
       } do
    Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
      result = result(%{"height" => 42})
      Plug.Conn.resp(conn, 200, result)
    end)

    assert {:ok, pid} = Subscriber.start_link(channel)

    websocket = get_websocket(pid)
    :ok = WebSocketMock.register(websocket)
    :ok = WebSocketMock.trigger_connected(websocket)
    assert_receive {:init, {:text, _message}}

    :ok = Subscriber.stop(pid)

    refute_receive {:Y_DISCONNECTED, ^channel}
  end

  test "when websocket connected, sends disconnect message on termination",
       %{
         bypass: bypass,
         channel: channel
       } do
    Process.flag(:trap_exit, true)

    Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
      result = result(%{"height" => 42})
      Plug.Conn.resp(conn, 200, result)
    end)

    assert {:ok, pid} = Subscriber.start_link(channel)

    websocket = get_websocket(pid)
    :ok = WebSocketMock.register(websocket)
    :ok = WebSocketMock.trigger_connected(websocket)
    assert_receive {:init, {:text, _message}}

    :ok = WebSocketMock.trigger_frame(websocket, {:text, ~s({"code":0})})
    assert_receive {:Y_CONNECTED, ^channel}

    :ok = Subscriber.stop(pid, :shutdown)

    assert_receive {:Y_DISCONNECTED, ^channel}
  end

  test "when websocket crashes, enters in backoff", %{
    bypass: bypass,
    channel: channel
  } do
    Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
      result = result(%{"height" => 42})
      Plug.Conn.resp(conn, 200, result)
    end)

    assert {:ok, pid} = Subscriber.start_link(channel)

    websocket = get_websocket(pid)
    :ok = WebSocketMock.register(websocket)
    :ok = WebSocketMock.trigger_connected(websocket)
    assert_receive {:init, {:text, _message}}

    :ok = WebSocketMock.trigger_frame(websocket, {:text, ~s({"code":0})})
    assert_receive {:Y_CONNECTED, ^channel}

    Process.exit(websocket, :shutdown)

    assert_receive {:Y_DISCONNECTED, ^channel}

    assert %Subscriber{
             retries: 1,
             backoff: 0,
             status: :disconnected,
             websocket: nil
           } = get_state(pid)
  end

  test "when websocket sends notification, publishes it", %{
    bypass: bypass,
    channel: channel
  } do
    Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
      result = result(%{"height" => 42})
      Plug.Conn.resp(conn, 200, result)
    end)

    assert {:ok, pid} = Subscriber.start_link(channel)

    websocket = get_websocket(pid)
    :ok = WebSocketMock.register(websocket)
    :ok = WebSocketMock.trigger_connected(websocket)
    assert_receive {:init, {:text, _message}}

    :ok = WebSocketMock.trigger_frame(websocket, {:text, ~s({"code":0})})
    assert_receive {:Y_CONNECTED, ^channel}

    :ok = WebSocketMock.trigger_frame(websocket, {:text, ~s({"height":"0x2b"})})

    assert_receive {:Y_EVENT, ^channel, %Tick{height: 43}}, 10_000
  end

  @spec result(any()) :: binary()
  defp result(payload) do
    %{
      "jsonrpc" => "2.0",
      "id" => :erlang.system_time(:microsecond),
      "result" => payload
    }
    |> Jason.encode!()
  end

  @spec error(any()) :: binary()
  defp error(payload) do
    %{
      "jsonrpc" => "2.0",
      "id" => :erlang.system_time(:microsecond),
      "error" => payload
    }
    |> Jason.encode!()
  end

  @spec get_websocket(pid()) :: nil | pid()
  defp get_websocket(pid) do
    get_state(pid).websocket
  end

  @spec get_state(pid()) :: Subscriber.t()
  defp get_state(pid) do
    :sys.get_state(pid)
  end
end
