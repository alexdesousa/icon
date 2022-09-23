defmodule Icon.Stream.Consumer.PublisherTest do
  use ExUnit.Case, async: true

  alias Icon.Stream.Consumer.Publisher
  alias Icon.Stream.Streamer
  alias Icon.Stream.WebSocket

  @moduletag :capture_log

  describe "for events" do
    setup do
      streamer = Streamer.start()

      assert {:ok, stream} =
               Icon.Stream.new_block_stream([],
                 from_height: 0,
                 identity: streamer.identity
               )

      assert :ok =
               Phoenix.PubSub.subscribe(
                 Icon.Stream.PubSub,
                 Publisher.generate_channel(stream)
               )

      assert {:ok, _producer} = WebSocket.start_link(stream, debug: true)
      assert_receive {:"$websocket", websocket}, 1_000
      assert_receive {:"$icon_websocket", :setting_up}, 500

      assert :ok = Streamer.send_message(websocket, %{"code" => 0})
      assert_receive {:"$websocket", :sent, {:text, _}}, 500
      assert_receive {:"$icon_websocket", :consuming}, 500

      {:ok, stream: stream, websocket: websocket}
    end

    test "should publish the messages it receives into the Phoenix channel", %{
      stream: stream,
      websocket: websocket
    } do
      assert {:ok, _consumer} = Publisher.start_link(stream)

      event = %{
        "height" => "0x0",
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"
      }

      assert :ok = Streamer.send_message(websocket, event)
      assert_receive {:"$websocket", :sent, {:text, _}}, 500

      assert_receive {:"$ICON", ^event}, 500
    end
  end
end
