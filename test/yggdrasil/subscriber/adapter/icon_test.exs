defmodule Yggdrasil.Subscriber.Adapter.IconTest do
  use ExUnit.Case, async: true

  alias Icon.RPC.Identity
  alias Icon.WebSocket.Router

  @moduletag capture_log: true

  describe "block subscription" do
    setup do
      bypass = Bypass.open()
      router = Router.start(channel: :block, bypass: bypass)
      identity = Identity.new(node: router.host)
      on_exit(fn -> Router.stop(router) end)

      channel = [
        name: %{source: :block, identity: identity},
        adapter: :icon
      ]

      {:ok, router: router, bypass: bypass, channel: channel}
    end

    test "subscribes/unsubscribes to/from the block channel", %{
      bypass: bypass,
      router: router,
      channel: channel
    } do
      Bypass.expect(bypass, "POST", "/api/v3", fn conn ->
        Plug.Conn.resp(conn, 200, block(42))
      end)

      assert :ok = Yggdrasil.subscribe(channel)
      assert_receive {:Y_CONNECTED, _}, 1_000

      _router = block_events(router, [42, 43])

      assert_receive {:Y_EVENT, _, %{"height" => "0x2a"}}, 1_000
      assert_receive {:Y_EVENT, _, %{"height" => "0x2b"}}, 1_000

      assert :ok = Yggdrasil.unsubscribe(channel)
      assert_receive {:Y_DISCONNECTED, _}, 1_000
    end
  end

  describe "event subscription" do
    setup do
      bypass = Bypass.open()
      router = Router.start(channel: :event, bypass: bypass)
      identity = Identity.new(node: router.host)
      on_exit(fn -> Router.stop(router) end)

      channel = [
        name: %{
          source: :event,
          identity: identity,
          data: %{
            event: "SomeEvent(int)"
          }
        },
        adapter: :icon
      ]

      {:ok, router: router, bypass: bypass, channel: channel}
    end

    test "subscribes/unsubscribes to/from the event channel", %{
      bypass: bypass,
      router: router,
      channel: channel
    } do
      Bypass.expect(bypass, "POST", "/api/v3", fn conn ->
        Plug.Conn.resp(conn, 200, block(42))
      end)

      assert :ok = Yggdrasil.subscribe(channel)
      assert_receive {:Y_CONNECTED, _}, 1_000

      _router = events(router, [42, 43])

      assert_receive {:Y_EVENT, _, %{"height" => "0x2a"}}, 1_000
      assert_receive {:Y_EVENT, _, %{"height" => "0x2b"}}, 1_000

      assert :ok = Yggdrasil.unsubscribe(channel)
      assert_receive {:Y_DISCONNECTED, _}, 1_000
    end
  end

  @spec block(pos_integer()) :: binary()
  defp block(height) when is_integer(height) and height > 0 do
    %{
      "jsonrpc" => "2.0",
      "id" => :erlang.system_time(:microsecond),
      "result" => %{
        "block_hash" =>
          "d579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
        "confirmed_transaction_list" => [
          %{
            "data" => %{
              "result" => %{
                "coveredByFee" => "0x0",
                "coveredByOverIssuedICX" => "0x2ee0",
                "issue" => "0x0"
              }
            },
            "dataType" => "base",
            "timestamp" => "0x5d629b9b5d886",
            "txHash" =>
              "0x75e553dcd57853e6c96428c4fede49209a3055fc905db757baa470c1e94f736d",
            "version" => "0x3"
          }
        ],
        "height" => height,
        "merkle_tree_root_hash" =>
          "0xce5aa42a762ee88a32fc2a792dfb5975858a71a8abf4ec51fb1218e3b827aa01",
        "peer_id" => "hxb97c82a5577a0a436f51a41421ad2d3b28da3f25",
        "prev_block_hash" =>
          "0xfe8138afd24512cc0e9f4da8df350300a759a480f15c8a00b04b2d753ea62ac3",
        "signature" => "",
        "time_stamp" => 1_642_849_581_258_886,
        "version" => "2.0"
      }
    }
    |> Jason.encode!()
  end

  @spec events(Router.t(), pos_integer()) :: Router.t()
  defp events(router, heights) do
    events =
      Enum.map(heights, fn x ->
        {:ok, height} = Icon.Schema.Types.Integer.dump(x)

        hash =
          :sha
          |> :crypto.hash(:crypto.strong_rand_bytes(42))
          |> Base.encode16(case: :lower)

        %{
          "hash" => "0x#{hash}",
          "height" => height,
          "index" => "0x0",
          "events" => ["0x0"]
        }
      end)

    Router.trigger_message(router, events)
  end

  @spec block_events(Router.t(), pos_integer()) :: Router.t()
  defp block_events(router, heights) do
    events =
      Enum.map(heights, fn x ->
        {:ok, height} = Icon.Schema.Types.Integer.dump(x)

        hash =
          :sha
          |> :crypto.hash(:crypto.strong_rand_bytes(42))
          |> Base.encode16(case: :lower)

        %{
          "hash" => "0x#{hash}",
          "height" => height
        }
      end)

    Router.trigger_message(router, events)
  end
end
