defmodule Yggdrasil.Subscriber.Adapter.IconTest do
  use ExUnit.Case, async: true

  alias Icon.RPC.Identity
  alias Icon.Schema.Types.Block.Tick
  alias Icon.Schema.Types.EventLog
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
        result = result(%{"height" => 42})
        Plug.Conn.resp(conn, 200, result)
      end)

      assert :ok = Yggdrasil.subscribe(channel)
      assert_receive {:Y_CONNECTED, _}, 1_000

      notification = %{
        "height" => "0x2a",
        "hash" =>
          "0x75e553dcd57853e6c96428c4fede49209a3055fc905db757baa470c1e94f736d"
      }

      _router = Router.trigger_message(router, notification)

      assert_receive {:Y_EVENT, _, %Tick{height: 42}}, 1_000

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
      tx_hash =
        "0xf8773bc17c4b84753a8dbb7bcf663c5a7b90d84770949d2966857fe1106ee5e9"

      Bypass.expect(bypass, "POST", "/api/v3", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        result =
          case Jason.decode!(body) do
            %{"method" => "icx_getLastBlock"} ->
              result(%{"height" => 42})

            %{"method" => "icx_getBlockByHeight"} ->
              result(%{
                "height" => "0x29",
                "confirmed_transaction_list" => [
                  %{"txHash" => tx_hash}
                ]
              })

            %{"method" => "icx_getTransactionResult"} ->
              result(%{
                "txHash" => tx_hash,
                "eventLogs" => [
                  %{
                    "scoreAddress" =>
                      "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                    "indexed" => [
                      "SomeEvent(int)",
                      "0x2a"
                    ],
                    "data" => []
                  }
                ]
              })
          end

        Plug.Conn.resp(conn, 200, result)
      end)

      assert :ok = Yggdrasil.subscribe(channel)
      assert_receive {:Y_CONNECTED, _}, 1_000

      notification = %{
        "height" => "0x2a",
        "hash" =>
          "0x75e553dcd57853e6c96428c4fede49209a3055fc905db757baa470c1e94f736d",
        "index" => "0x0",
        "events" => ["0x0"]
      }

      _router = Router.trigger_message(router, notification)

      assert_receive {:Y_EVENT, _, %EventLog{}}, 1_000

      assert :ok = Yggdrasil.unsubscribe(channel)
      assert_receive {:Y_DISCONNECTED, _}, 1_000
    end
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
end
