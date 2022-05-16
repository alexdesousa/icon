defmodule Yggdrasil.Subscriber.Adapter.Icon.WebSocketTest do
  use ExUnit.Case, async: true

  alias Icon.WebSocket.Router
  alias Yggdrasil.Subscriber.Adapter.Icon.WebSocket

  setup do
    %Router{url: url} = router = Router.start()

    {:ok, url: url, router: router}
  end

  test "when websocket is connected, sends connected message", %{url: url} do
    assert {:ok, _websocket} = WebSocket.start_link(1, url, [])
    assert_receive {:websocket, _}
    assert_receive {:"$gen_cast", :connected}
  end

  test "when websocket is terminated, sends disconnected message", %{url: url} do
    assert {:ok, websocket} = WebSocket.start_link(1, url, [])
    assert_receive {:websocket, _}
    assert_receive {:"$gen_cast", :connected}
    assert :ok = WebSocket.stop(websocket)
    assert_receive {:"$gen_cast", {:disconnected, {:local, :normal}}}
  end

  test "sends frames when received", %{url: url, router: router} do
    assert {:ok, websocket} = WebSocket.start_link(1, url, [])
    :ok = WebSocket.initialize(websocket, {:text, ~s({"height":"0x2a"})})
    _router = Router.trigger_message(router, %{"height" => "0x2a"})
    assert_receive {:"$gen_cast", :connected}
    assert_receive {:"$gen_cast", {:frame, ~s({"code":0})}}
    assert_receive {:"$gen_cast", {:frame, ~s({"height":"0x2a"})}}
  end
end
