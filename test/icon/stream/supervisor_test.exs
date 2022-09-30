defmodule Icon.Stream.SupervisorTest do
  use ExUnit.Case, async: true

  alias Icon.Stream.Consumer.Publisher
  alias Icon.Stream.Streamer

  @moduletag :capture_log

  describe "for stages" do
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

      {:ok, stream: stream}
    end

    test "should publish the messages it receives into the Phoenix channel", %{
      stream: stream
    } do
      assert {:ok, _supervisor} = Icon.Stream.Supervisor.start_link(stream)
      assert_receive {:"$websocket", websocket}, 1_000

      assert :ok = Streamer.send_message(websocket, %{"code" => 0})
      assert_receive {:"$websocket", :sent, {:text, _}}, 500

      event = %{
        "height" => "0x0",
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"
      }

      assert :ok = Streamer.send_message(websocket, event)
      assert_receive {:"$websocket", :sent, {:text, _}}, 500

      expected = %{
        height: 0,
        hash:
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"
      }

      assert_receive {:"$ICON", ^expected}, 500
    end

    test "should terminate supervisor when the stream is terminated", %{
      stream: stream
    } do
      assert {:ok, supervisor} = Icon.Stream.Supervisor.start_link(stream)
      assert_receive {:"$websocket", _websocket}, 1_000

      Process.monitor(supervisor)
      Process.flag(:trap_exit, true)
      Process.exit(stream, :shutdown)

      assert_receive {:DOWN, _, :process, ^supervisor, :shutdown}, 1_000
    end

    test "should not start a supervisor if the stream is not alive", %{
      stream: stream
    } do
      Process.monitor(stream)
      Process.flag(:trap_exit, true)
      Process.exit(stream, :shutdown)

      assert_receive {:DOWN, _, :process, ^stream, :shutdown}, 1_000

      assert {:error, {:shutdown, "Stream is dead"}} =
               Icon.Stream.Supervisor.start_link(stream)
    end
  end
end
