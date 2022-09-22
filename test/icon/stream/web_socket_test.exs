defmodule Icon.Stream.WebsocketTest do
  use ExUnit.Case, async: true

  alias Icon.Stream.Streamer
  alias Icon.Stream.WebSocket

  @moduletag :capture_log

  describe "for events" do
    setup do
      streamer = Streamer.start()

      {:ok, stream} =
        Icon.Stream.new_block_stream([],
          max_buffer_size: 1,
          from_height: 0,
          identity: streamer.identity
        )

      {:ok, streamer: streamer, stream: stream}
    end

    test "should set connecting status on start", %{
      stream: stream
    } do
      assert {:ok, _} = WebSocket.start_link(stream, debug: true)
      assert_receive {:"$icon_websocket", :connecting}
    end

    test "should set setting_up status the websocket", %{
      stream: stream
    } do
      assert {:ok, producer} = WebSocket.start_link(stream, debug: true)
      assert_receive {:"$websocket", _websocket_pid}, 1_000
      assert_receive {:"$icon_websocket", :connecting}
      assert_receive {:"$icon_websocket", :upgrading}
      assert_receive {:"$icon_websocket", :initializing}
      assert_receive {:"$icon_websocket", :setting_up}

      assert %GenStage{
               state: %WebSocket{status: :setting_up}
             } = :sys.get_state(producer)
    end

    test "should change to consuming state after setting up the connection", %{
      stream: stream
    } do
      assert {:ok, producer} = WebSocket.start_link(stream, debug: true)
      assert_receive {:"$websocket", websocket_pid}, 1_000
      assert_receive {:"$icon_websocket", :connecting}
      assert_receive {:"$icon_websocket", :upgrading}
      assert_receive {:"$icon_websocket", :initializing}
      assert_receive {:"$icon_websocket", :setting_up}

      assert :ok = Streamer.send_message(websocket_pid, %{"code" => 0})
      assert_receive {:"$websocket", :sent, {:text, _}}

      assert_receive {:"$icon_websocket", :consuming}

      assert %GenStage{
               state: %WebSocket{status: :consuming}
             } = :sys.get_state(producer)
    end

    test "should change to connecting state after failing to setup the connection",
         %{
           stream: stream
         } do
      assert {:ok, _producer} = WebSocket.start_link(stream, debug: true)
      assert_receive {:"$websocket", websocket_pid}, 1_000
      assert_receive {:"$icon_websocket", :connecting}
      assert_receive {:"$icon_websocket", :upgrading}
      assert_receive {:"$icon_websocket", :initializing}
      assert_receive {:"$icon_websocket", :setting_up}

      assert :ok = Streamer.send_message(websocket_pid, %{"code" => -32_000})
      assert_receive {:"$websocket", :sent, {:text, _}}

      assert_receive {:"$icon_websocket", :connecting}
      assert_receive {:"$icon_websocket", :upgrading}
      assert_receive {:"$icon_websocket", :initializing}
      assert_receive {:"$icon_websocket", :setting_up}
    end

    test "should change to waiting state when buffer is full", %{
      stream: stream
    } do
      assert {:ok, _producer} = WebSocket.start_link(stream, debug: true)
      assert_receive {:"$websocket", websocket_pid}, 1_000
      assert_receive {:"$icon_websocket", :connecting}
      assert_receive {:"$icon_websocket", :upgrading}
      assert_receive {:"$icon_websocket", :initializing}
      assert_receive {:"$icon_websocket", :setting_up}

      assert :ok = Streamer.send_message(websocket_pid, %{"code" => 0})
      assert_receive {:"$websocket", :sent, {:text, _}}

      assert :ok =
               Streamer.send_message(websocket_pid, %{
                 "height" => "0x0",
                 "hash" =>
                   "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"
               })

      assert_receive {:"$websocket", :sent, {:text, _}}

      assert_receive {:"$icon_websocket", :waiting}
    end

    test "should change from waiting to consuming state when buffer has space again",
         %{
           stream: stream
         } do
      assert {:ok, producer} = WebSocket.start_link(stream, debug: true)
      assert_receive {:"$websocket", websocket_pid}, 1_000
      assert_receive {:"$icon_websocket", :connecting}
      assert_receive {:"$icon_websocket", :upgrading}
      assert_receive {:"$icon_websocket", :initializing}
      assert_receive {:"$icon_websocket", :setting_up}

      assert :ok = Streamer.send_message(websocket_pid, %{"code" => 0})
      assert_receive {:"$websocket", :sent, {:text, _}}

      assert :ok =
               Streamer.send_message(websocket_pid, %{
                 "height" => "0x0",
                 "hash" =>
                   "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"
               })

      assert_receive {:"$websocket", :sent, {:text, _}}
      assert_receive {:"$icon_websocket", :waiting}

      assert [_] =
               [{producer, max_demand: 1}]
               |> GenStage.stream()
               |> Enum.take(1)

      assert_receive {:"$websocket", websocket_pid}, 1_000
      assert_receive {:"$icon_websocket", :connecting}
      assert_receive {:"$icon_websocket", :upgrading}
      assert_receive {:"$icon_websocket", :initializing}
      assert_receive {:"$icon_websocket", :setting_up}

      assert :ok = Streamer.send_message(websocket_pid, %{"code" => 0})
      assert_receive {:"$websocket", :sent, {:text, _}}

      assert_receive {:"$icon_websocket", :consuming}
    end

    test "should change from any state to terminating when the process is stopped",
         %{
           stream: stream
         } do
      assert {:ok, producer} = WebSocket.start_link(stream, debug: true)
      assert_receive {:"$websocket", _websocket_pid}, 1_000
      assert_receive {:"$icon_websocket", :connecting}

      assert :ok = WebSocket.stop(producer)
      assert_receive {:"$icon_websocket", :terminating}
    end

    test "should reconnect when connection dies", %{
      stream: stream
    } do
      assert {:ok, _producer} = WebSocket.start_link(stream, debug: true)
      assert_receive {:"$websocket", websocket_pid}, 1_000
      assert_receive {:"$icon_websocket", :connecting}
      assert_receive {:"$icon_websocket", :upgrading}
      assert_receive {:"$icon_websocket", :initializing}
      assert_receive {:"$icon_websocket", :setting_up}

      assert :ok = Streamer.send_message(websocket_pid, %{"code" => 0})
      assert_receive {:"$websocket", :sent, {:text, _}}
      assert_receive {:"$icon_websocket", :consuming}

      GenServer.stop(websocket_pid)

      assert_receive {:"$icon_websocket", :connecting}
    end
  end
end
