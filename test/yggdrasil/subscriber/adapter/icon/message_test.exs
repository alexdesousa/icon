defmodule Yggdrasil.Subscriber.Adapter.Icon.MessageTest do
  use ExUnit.Case, async: true

  alias Icon.RPC.Identity
  alias Icon.Schema.Error
  alias Icon.Schema.Types.Block.Tick
  alias Icon.Schema.Types.EventLog
  alias Yggdrasil.Channel
  alias Yggdrasil.Subscriber.Adapter.Icon.Message

  describe "publish/2" do
    setup do
      bypass = Bypass.open()

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            addr: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
            event: "Transfer(Address,Address,int)"
          },
          identity: Identity.new(node: "http://localhost:#{bypass.port}")
        }
      }

      {:ok, bypass: bypass, channel: channel}
    end

    test "succeeds on correct websocket setup", %{
      channel: channel
    } do
      %Task{ref: ref} = Message.publish(channel, ~s({"code":0}))
      assert_receive {^ref, :ok}
    end

    test "fails on error websocket setup", %{
      channel: channel
    } do
      message = ~s({"code":-32000, "message":"error"})
      %Task{ref: ref} = Message.publish(channel, message)
      assert_receive {^ref, {:error, %Error{code: -32_000, message: "error"}}}
    end

    test "fails on decoding error", %{
      channel: channel
    } do
      message = ~s({)
      %Task{ref: ref} = Message.publish(channel, message)

      assert_receive {^ref,
                      {:error,
                       %Error{
                         code: -32_000,
                         message: "cannot decode channel message"
                       }}}
    end
  end

  describe "decode/2 for block" do
    setup do
      bypass = Bypass.open()

      channel = %Channel{
        name: %{
          source: :block,
          data: [
            %{
              addr: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
              event: "Transfer(Address,Address,int)"
            }
          ],
          identity: Identity.new(node: "http://localhost:#{bypass.port}")
        }
      }

      {:ok, bypass: bypass, channel: channel}
    end

    test "filters event logs correctly", %{
      bypass: bypass,
      channel: channel
    } do
      # Target data
      block_height = "0x29"

      tx_hash =
        "0xf8773bc17c4b84753a8dbb7bcf663c5a7b90d84770949d2966857fe1106ee5e9"

      target_transaction = %{"txHash" => tx_hash}

      target_event_log = %{
        "scoreAddress" => Enum.at(channel.name.data, 0).addr,
        "indexed" => [
          Enum.at(channel.name.data, 0).event,
          "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
          "hx2e243ad926ac48d15156756fce28314357d49d83"
        ],
        "data" => [
          "0x2a"
        ]
      }

      # Server mock
      block = %{
        "block_hash" =>
          "0x4ec23aec0d1834981ac6793537b9358dfa0d9ce5b4237a550b62e1b63bb84ee6",
        "height" => block_height,
        "confirmed_transaction_list" => [
          %{
            "txHash" =>
              "0xf8773bc17c4b84753a8dbb7bcf663c5a7b90d84770949d2966857fe1106ee5e9"
          },
          target_transaction
        ]
      }

      transaction = %{
        "txHash" => tx_hash,
        "eventLogs" => [
          %{
            "scoreAddress" => "cx2609b924e33ef00b648a409245c7ea394c467824",
            "indexed" => ["Event()"],
            "data" => []
          },
          target_event_log
        ]
      }

      Bypass.expect(bypass, "POST", "/api/v3", fn conn ->
        {:ok, payload, conn} = Plug.Conn.read_body(conn)

        result =
          case Jason.decode(payload) do
            {:ok, %{"method" => "icx_getBlockByHeight"}} ->
              result(block)

            {:ok, %{"method" => "icx_getTransactionResult"}} ->
              result(transaction)
          end

        Plug.Conn.resp(conn, 200, result)
      end)

      # Actual test
      notification = %{
        "height" => "0x2a",
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
        "indexes" => [
          [
            "0x1"
          ]
        ],
        "events" => [
          [
            ["0x1"]
          ]
        ]
      }

      assert {
               :ok,
               [
                 %Tick{
                   hash:
                     "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
                   height: 42
                 },
                 %EventLog{
                   header: "Transfer(Address,Address,int)",
                   indexed: [
                     "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
                     "hx2e243ad926ac48d15156756fce28314357d49d83"
                   ],
                   data: [
                     42
                   ]
                 }
               ]
             } = Message.decode(channel, notification)
    end

    test "errors when tick cannot be decoded", %{
      channel: channel
    } do
      notification = %{
        "height" => "invalid",
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"
      }

      assert {
               :error,
               %Error{
                 code: -32_602,
                 reason: :invalid_params,
                 message: "height is invalid"
               }
             } = Message.decode(channel, notification)
    end

    test "errors when it cannot decode transaction index", %{
      bypass: bypass,
      channel: channel
    } do
      block_height = "0x29"

      block = %{
        "block_hash" =>
          "0x4ec23aec0d1834981ac6793537b9358dfa0d9ce5b4237a550b62e1b63bb84ee6",
        "height" => block_height,
        "confirmed_transaction_list" => []
      }

      Bypass.expect(bypass, "POST", "/api/v3", fn conn ->
        result = result(block)
        Plug.Conn.resp(conn, 200, result)
      end)

      notification = %{
        "height" => "0x2a",
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
        "indexes" => [["invalid"]],
        "events" => [[["0x1"]]]
      }

      assert {
               :error,
               %Error{
                 code: -32_000,
                 reason: :server_error,
                 message: "cannot decode information in notification"
               }
             } = Message.decode(channel, notification)
    end

    test "errors when it cannot get block", %{
      bypass: bypass,
      channel: channel
    } do
      Bypass.expect(bypass, "POST", "/api/v3", fn conn ->
        Plug.Conn.resp(conn, 500, "")
      end)

      notification = %{
        "height" => "0x2a",
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
        "indexes" => [["0x1"]],
        "events" => [[["0x1"]]]
      }

      assert {
               :error,
               %Error{
                 code: -31_000,
                 reason: :system_error,
                 message: "System error"
               }
             } = Message.decode(channel, notification)
    end

    test "errors when it cannot find transaction in block", %{
      bypass: bypass,
      channel: channel
    } do
      block_height = "0x29"

      block = %{
        "block_hash" =>
          "0x4ec23aec0d1834981ac6793537b9358dfa0d9ce5b4237a550b62e1b63bb84ee6",
        "height" => block_height,
        "confirmed_transaction_list" => []
      }

      Bypass.expect(bypass, "POST", "/api/v3", fn conn ->
        result = result(block)
        Plug.Conn.resp(conn, 200, result)
      end)

      notification = %{
        "height" => "0x2a",
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
        "indexes" => [["0x1"]],
        "events" => [[["0x1"]]]
      }

      assert {
               :error,
               %Error{
                 code: -32_000,
                 reason: :server_error,
                 message:
                   "cannot find the transaction index 1 on block with height 41"
               }
             } = Message.decode(channel, notification)
    end
  end

  describe "decode/2 for event" do
    setup do
      bypass = Bypass.open()

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            addr: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
            event: "Transfer(Address,Address,int)"
          },
          identity: Identity.new(node: "http://localhost:#{bypass.port}")
        }
      }

      {:ok, bypass: bypass, channel: channel}
    end

    test "filters event logs correctly", %{
      bypass: bypass,
      channel: channel
    } do
      # Target data
      block_height = "0x29"

      tx_hash =
        "0xf8773bc17c4b84753a8dbb7bcf663c5a7b90d84770949d2966857fe1106ee5e9"

      target_transaction = %{"txHash" => tx_hash}

      target_event_log = %{
        "scoreAddress" => channel.name.data.addr,
        "indexed" => [
          channel.name.data.event,
          "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
          "hx2e243ad926ac48d15156756fce28314357d49d83"
        ],
        "data" => [
          "0x2a"
        ]
      }

      # Server mock
      block = %{
        "block_hash" =>
          "0x4ec23aec0d1834981ac6793537b9358dfa0d9ce5b4237a550b62e1b63bb84ee6",
        "height" => block_height,
        "confirmed_transaction_list" => [
          %{
            "txHash" =>
              "0xf8773bc17c4b84753a8dbb7bcf663c5a7b90d84770949d2966857fe1106ee5e9"
          },
          target_transaction
        ]
      }

      transaction = %{
        "txHash" => tx_hash,
        "eventLogs" => [
          %{
            "scoreAddress" => "cx2609b924e33ef00b648a409245c7ea394c467824",
            "indexed" => ["Event()"],
            "data" => []
          },
          target_event_log
        ]
      }

      Bypass.expect(bypass, "POST", "/api/v3", fn conn ->
        {:ok, payload, conn} = Plug.Conn.read_body(conn)

        result =
          case Jason.decode(payload) do
            {:ok, %{"method" => "icx_getBlockByHeight"}} ->
              result(block)

            {:ok, %{"method" => "icx_getTransactionResult"}} ->
              result(transaction)
          end

        Plug.Conn.resp(conn, 200, result)
      end)

      # Actual test
      notification = %{
        "height" => "0x2a",
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
        "index" => "0x1",
        "events" => [
          "0x1"
        ]
      }

      assert {
               :ok,
               [
                 %EventLog{
                   header: "Transfer(Address,Address,int)",
                   indexed: [
                     "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
                     "hx2e243ad926ac48d15156756fce28314357d49d83"
                   ],
                   data: [
                     42
                   ]
                 }
               ]
             } = Message.decode(channel, notification)
    end

    test "errors when it cannot decode index", %{
      channel: channel
    } do
      notification = %{
        "height" => "0x2a",
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
        "index" => "invalid",
        "events" => [
          "0x1"
        ]
      }

      assert {
               :error,
               %Error{
                 code: -32_000,
                 reason: :server_error,
                 message: "cannot decode information in notification"
               }
             } = Message.decode(channel, notification)
    end

    test "errors when there's no transaction index", %{
      channel: channel
    } do
      notification = %{
        "height" => "0x2a",
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
        "events" => [
          "0x1"
        ]
      }

      assert {
               :error,
               %Error{
                 code: -32_000,
                 reason: :server_error,
                 message: "cannot decode information in notification"
               }
             } = Message.decode(channel, notification)
    end

    test "errors when it cannot decode events", %{
      channel: channel
    } do
      notification = %{
        "height" => "0x2a",
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
        "index" => "0x1",
        "events" => [
          "invalid"
        ]
      }

      assert {
               :error,
               %Error{
                 code: -32_000,
                 reason: :server_error,
                 message: "cannot decode information in notification"
               }
             } = Message.decode(channel, notification)
    end

    test "errors when there are no events", %{
      channel: channel
    } do
      notification = %{
        "height" => "0x2a",
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
        "index" => "0x1"
      }

      assert {
               :error,
               %Error{
                 code: -32_000,
                 reason: :server_error,
                 message: "cannot decode information in notification"
               }
             } = Message.decode(channel, notification)
    end

    test "errors when it cannot decode height", %{
      channel: channel
    } do
      notification = %{
        "height" => "invalid",
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
        "index" => "0x1",
        "events" => [
          "0x1"
        ]
      }

      assert {
               :error,
               %Error{
                 code: -32_000,
                 reason: :server_error,
                 message: "cannot decode information in notification"
               }
             } = Message.decode(channel, notification)
    end

    test "errors when there's no height", %{
      channel: channel
    } do
      notification = %{
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
        "index" => "0x1",
        "events" => [
          "0x1"
        ]
      }

      assert {
               :error,
               %Error{
                 code: -32_000,
                 reason: :server_error,
                 message: "cannot decode information in notification"
               }
             } = Message.decode(channel, notification)
    end

    test "errors when it cannot get block", %{
      bypass: bypass,
      channel: channel
    } do
      Bypass.expect(bypass, "POST", "/api/v3", fn conn ->
        Plug.Conn.resp(conn, 500, "")
      end)

      notification = %{
        "height" => "0x2a",
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
        "index" => "0x1",
        "events" => [
          "0x1"
        ]
      }

      assert {
               :error,
               %Error{
                 code: -31_000,
                 reason: :system_error,
                 message: "System error"
               }
             } = Message.decode(channel, notification)
    end

    test "errors when it cannot find transaction in block", %{
      bypass: bypass,
      channel: channel
    } do
      block_height = "0x29"

      block = %{
        "block_hash" =>
          "0x4ec23aec0d1834981ac6793537b9358dfa0d9ce5b4237a550b62e1b63bb84ee6",
        "height" => block_height,
        "confirmed_transaction_list" => []
      }

      Bypass.expect(bypass, "POST", "/api/v3", fn conn ->
        result = result(block)
        Plug.Conn.resp(conn, 200, result)
      end)

      notification = %{
        "height" => "0x2a",
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
        "index" => "0x1",
        "events" => [
          "0x1"
        ]
      }

      assert {
               :error,
               %Error{
                 code: -32_000,
                 reason: :server_error,
                 message:
                   "cannot find the transaction index 1 on block with height 41"
               }
             } = Message.decode(channel, notification)
    end

    test "errors when it cannot find the transaction", %{
      bypass: bypass,
      channel: channel
    } do
      block_height = "0x29"

      tx_hash =
        "0xf8773bc17c4b84753a8dbb7bcf663c5a7b90d84770949d2966857fe1106ee5e9"

      target_transaction = %{"txHash" => tx_hash}

      # Server mock
      block = %{
        "block_hash" =>
          "0x4ec23aec0d1834981ac6793537b9358dfa0d9ce5b4237a550b62e1b63bb84ee6",
        "height" => block_height,
        "confirmed_transaction_list" => [
          %{
            "txHash" =>
              "0xf8773bc17c4b84753a8dbb7bcf663c5a7b90d84770949d2966857fe1106ee5e9"
          },
          target_transaction
        ]
      }

      Bypass.expect(bypass, "POST", "/api/v3", fn conn ->
        {:ok, payload, conn} = Plug.Conn.read_body(conn)

        case Jason.decode(payload) do
          {:ok, %{"method" => "icx_getBlockByHeight"}} ->
            Plug.Conn.resp(conn, 200, result(block))

          {:ok, %{"method" => "icx_getTransactionResult"}} ->
            Plug.Conn.resp(conn, 500, "")
        end
      end)

      notification = %{
        "height" => "0x2a",
        "hash" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
        "index" => "0x1",
        "events" => [
          "0x1"
        ]
      }

      assert {
               :error,
               %Error{
                 code: -31_000,
                 reason: :system_error,
                 message: "System error"
               }
             } = Message.decode(channel, notification)
    end
  end

  describe "encode/2 for block" do
    test "sets height" do
      height = 42
      channel = %Channel{name: %{source: :block}}

      assert {:text, data} = Message.encode(height, channel)

      assert %{"height" => "0x2a"} = Jason.decode!(data)
    end

    test "sets events" do
      height = 42

      channel = %Channel{
        name: %{
          source: :block,
          data: [
            %{
              addr: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
              event: "Transfer(Address,Address,int)",
              indexed: [
                nil,
                "hxbe258ceb872e08851f1f59694dac2558708ece11"
              ],
              data: [
                42
              ]
            }
          ]
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{
               "height" => "0x2a",
               "eventFilters" => [
                 %{
                   "addr" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                   "event" => "Transfer(Address,Address,int)",
                   "indexed" => [
                     nil,
                     "hxbe258ceb872e08851f1f59694dac2558708ece11"
                   ],
                   "data" => [
                     "0x2a"
                   ]
                 }
               ]
             } = Jason.decode!(data)
    end

    test "raises error when event is missing" do
      height = 42

      channel = %Channel{
        name: %{
          source: :block,
          data: [
            %{
              addr: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
            }
          ]
        }
      }

      assert_raise ArgumentError, fn ->
        Message.encode(height, channel)
      end
    end
  end

  describe "encode/2 for event" do
    test "sets height" do
      height = 42
      channel = %Channel{name: %{source: :event, data: %{event: "Event()"}}}

      assert {:text, data} = Message.encode(height, channel)

      assert %{"height" => "0x2a"} = Jason.decode!(data)
    end

    test "sets addr" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event()",
            addr: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"addr" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"} =
               Jason.decode!(data)
    end

    test "sets integer indexed value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(int)",
            indexed: [42]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"indexed" => ["0x2a"]} = Jason.decode!(data)
    end

    test "sets string indexed value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(str)",
            indexed: ["hello"]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"indexed" => ["hello"]} = Jason.decode!(data)
    end

    test "sets bytes indexed value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(bytes)",
            indexed: ["hello"]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"indexed" => ["0x68656c6c6f"]} = Jason.decode!(data)
    end

    test "sets bool indexed value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(bool)",
            indexed: [true]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"indexed" => ["0x1"]} = Jason.decode!(data)
    end

    test "sets address indexed value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(Address)",
            indexed: ["hxbe258ceb872e08851f1f59694dac2558708ece11"]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"indexed" => ["hxbe258ceb872e08851f1f59694dac2558708ece11"]} =
               Jason.decode!(data)
    end

    test "sets nil indexed value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(Address)",
            indexed: [nil]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)
      assert %{"indexed" => [nil]} = Jason.decode!(data)
    end

    test "sets integer data value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(int)",
            indexed: [],
            data: [42]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"data" => ["0x2a"]} = Jason.decode!(data)
    end

    test "sets string data value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(str)",
            indexed: [],
            data: ["hello"]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"data" => ["hello"]} = Jason.decode!(data)
    end

    test "sets bytes data value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(bytes)",
            indexed: [],
            data: ["hello"]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"data" => ["0x68656c6c6f"]} = Jason.decode!(data)
    end

    test "sets bool data value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(bool)",
            indexed: [],
            data: [true]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"data" => ["0x1"]} = Jason.decode!(data)
    end

    test "sets address data value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(Address)",
            indexed: [],
            data: ["hxbe258ceb872e08851f1f59694dac2558708ece11"]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"data" => ["hxbe258ceb872e08851f1f59694dac2558708ece11"]} =
               Jason.decode!(data)
    end

    test "sets nil data value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(Address)",
            indexed: [],
            data: [nil]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)
      assert %{"data" => [nil]} = Jason.decode!(data)
    end
  end

  @spec result(any()) :: binary()
  defp result(result) do
    %{
      "jsonrpc" => "2.0",
      "id" => :erlang.system_time(:microsecond),
      "result" => result
    }
    |> Jason.encode!()
  end
end
