defmodule IconTest do
  use ExUnit.Case, async: true

  alias Icon.RPC.Identity
  alias Icon.Schema.{Error, Types.Block, Types.Transaction}

  describe "get_block/2" do
    setup do
      bypass = Bypass.open()
      identity = Identity.new(node: "http://localhost:#{bypass.port}")

      {:ok, bypass: bypass, identity: identity}
    end

    test "when no hash or height is provided, returns latest block", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
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
            "height" => 3_153_751,
            "merkle_tree_root_hash" =>
              "0xce5aa42a762ee88a32fc2a792dfb5975858a71a8abf4ec51fb1218e3b827aa01",
            "peer_id" => "hxb97c82a5577a0a436f51a41421ad2d3b28da3f25",
            "prev_block_hash" =>
              "0xfe8138afd24512cc0e9f4da8df350300a759a480f15c8a00b04b2d753ea62ac3",
            "signature" => "",
            "time_stamp" => 1_642_849_581_258_886,
            "version" => "2.0"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {
               :ok,
               %Block{
                 block_hash:
                   "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                 confirmed_transaction_list: [
                   %Transaction{
                     data: %{
                       result: %{
                         coveredByFee: 0,
                         coveredByOverIssuedICX: 12_000,
                         issue: 0
                       }
                     },
                     dataType: :base,
                     timestamp: ~U[2022-01-22 11:06:21.258886Z],
                     txHash:
                       "0x75e553dcd57853e6c96428c4fede49209a3055fc905db757baa470c1e94f736d",
                     version: 3
                   }
                 ],
                 height: 3_153_751,
                 merkle_tree_root_hash:
                   "0xce5aa42a762ee88a32fc2a792dfb5975858a71a8abf4ec51fb1218e3b827aa01",
                 peer_id: "hxb97c82a5577a0a436f51a41421ad2d3b28da3f25",
                 prev_block_hash:
                   "0xfe8138afd24512cc0e9f4da8df350300a759a480f15c8a00b04b2d753ea62ac3",
                 signature: nil,
                 time_stamp: ~U[2022-01-22 11:06:21.258886Z],
                 version: "2.0"
               }
             } = Icon.get_block(identity)
    end

    test "when height is provided, returns block by height", %{
      identity: identity,
      bypass: bypass
    } do
      height = 42

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
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
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {
               :ok,
               %Block{
                 block_hash:
                   "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                 confirmed_transaction_list: [
                   %Transaction{
                     data: %{
                       result: %{
                         coveredByFee: 0,
                         coveredByOverIssuedICX: 12_000,
                         issue: 0
                       }
                     },
                     dataType: :base,
                     timestamp: ~U[2022-01-22 11:06:21.258886Z],
                     txHash:
                       "0x75e553dcd57853e6c96428c4fede49209a3055fc905db757baa470c1e94f736d",
                     version: 3
                   }
                 ],
                 height: ^height,
                 merkle_tree_root_hash:
                   "0xce5aa42a762ee88a32fc2a792dfb5975858a71a8abf4ec51fb1218e3b827aa01",
                 peer_id: "hxb97c82a5577a0a436f51a41421ad2d3b28da3f25",
                 prev_block_hash:
                   "0xfe8138afd24512cc0e9f4da8df350300a759a480f15c8a00b04b2d753ea62ac3",
                 signature: nil,
                 time_stamp: ~U[2022-01-22 11:06:21.258886Z],
                 version: "2.0"
               }
             } = Icon.get_block(identity, height)
    end

    test "when hash is provided, returns block by hash", %{
      identity: identity,
      bypass: bypass
    } do
      hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "block_hash" => hash,
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
            "height" => 3_153_751,
            "merkle_tree_root_hash" =>
              "0xce5aa42a762ee88a32fc2a792dfb5975858a71a8abf4ec51fb1218e3b827aa01",
            "peer_id" => "hxb97c82a5577a0a436f51a41421ad2d3b28da3f25",
            "prev_block_hash" =>
              "0xfe8138afd24512cc0e9f4da8df350300a759a480f15c8a00b04b2d753ea62ac3",
            "signature" => "",
            "time_stamp" => 1_642_849_581_258_886,
            "version" => "2.0"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {
               :ok,
               %Block{
                 block_hash: ^hash,
                 confirmed_transaction_list: [
                   %Transaction{
                     data: %{
                       result: %{
                         coveredByFee: 0,
                         coveredByOverIssuedICX: 12_000,
                         issue: 0
                       }
                     },
                     dataType: :base,
                     timestamp: ~U[2022-01-22 11:06:21.258886Z],
                     txHash:
                       "0x75e553dcd57853e6c96428c4fede49209a3055fc905db757baa470c1e94f736d",
                     version: 3
                   }
                 ],
                 height: 3_153_751,
                 merkle_tree_root_hash:
                   "0xce5aa42a762ee88a32fc2a792dfb5975858a71a8abf4ec51fb1218e3b827aa01",
                 peer_id: "hxb97c82a5577a0a436f51a41421ad2d3b28da3f25",
                 prev_block_hash:
                   "0xfe8138afd24512cc0e9f4da8df350300a759a480f15c8a00b04b2d753ea62ac3",
                 signature: nil,
                 time_stamp: ~U[2022-01-22 11:06:21.258886Z],
                 version: "2.0"
               }
             } = Icon.get_block(identity, hash)
    end

    test "when the block is not valid, returns error", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast block"
              }} = Icon.get_block(identity)
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} = Icon.get_block(identity)
    end
  end

  describe "get_balance/1" do
    setup do
      bypass = Bypass.open()

      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity =
        Identity.new(
          private_key: private_key,
          node: "http://localhost:#{bypass.port}"
        )

      {:ok, bypass: bypass, identity: identity}
    end

    test "when the request is successful, returns own balance in loop", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("0x2a")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, 42} = Icon.get_balance(identity)
    end

    test "when the balance is not valid, returns error", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast balance to loop"
              }} = Icon.get_balance(identity)
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} = Icon.get_balance(identity)
    end
  end

  describe "get_balance/2" do
    setup do
      bypass = Bypass.open()
      identity = Identity.new(node: "http://localhost:#{bypass.port}")
      wallet = "hxfd7e4560ba363f5aabd32caac7317feeee70ea57"

      {:ok, bypass: bypass, identity: identity, wallet: wallet}
    end

    test "when the request is successful, returns own balance in loop", %{
      wallet: wallet,
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("0x2a")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, 42} = Icon.get_balance(identity, wallet)
    end

    test "when the balance is not valid, returns error", %{
      wallet: wallet,
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast balance to loop"
              }} = Icon.get_balance(identity, wallet)
    end

    test "when server responds with an error, errors", %{
      wallet: wallet,
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} = Icon.get_balance(identity, wallet)
    end
  end

  describe "get_total_supply/1" do
    setup do
      bypass = Bypass.open()
      identity = Identity.new(node: "http://localhost:#{bypass.port}")

      {:ok, bypass: bypass, identity: identity}
    end

    test "when the request is successful, returns own ICX total supply in loop",
         %{
           identity: identity,
           bypass: bypass
         } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("0x2a")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, 42} = Icon.get_total_supply(identity)
    end

    test "when the total supply is not valid, returns error", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast total supply to loop"
              }} = Icon.get_total_supply(identity)
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} = Icon.get_total_supply(identity)
    end
  end

  describe "call/5" do
    setup do
      bypass = Bypass.open()

      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity =
        Identity.new(
          private_key: private_key,
          node: "http://localhost:#{bypass.port}"
        )

      {:ok, bypass: bypass, identity: identity}
    end

    test "when the call is successful (without params), returns the raw value",
         %{
           identity: identity,
           bypass: bypass
         } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("0x2a")

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, "0x2a"} =
               Icon.call(
                 identity,
                 "cx2e243ad926ac48d15156756fce28314357d49d83",
                 "method"
               )
    end

    test "when the call is successful (without params) and response schema, returns value",
         %{
           identity: identity,
           bypass: bypass
         } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("0x2a")

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, 42} =
               Icon.call(
                 identity,
                 "cx2e243ad926ac48d15156756fce28314357d49d83",
                 "method",
                 nil,
                 response_schema: :integer
               )
    end

    test "when the call is successful (with params), returns raw value", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("0x1")

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, "0x1"} =
               Icon.call(
                 identity,
                 "cx2e243ad926ac48d15156756fce28314357d49d83",
                 "transfer",
                 %{
                   from: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
                   to: "hx2e243ad926ac48d15156756fce28314357d49d83",
                   amount: 1_000_000_000_000_000_000
                 },
                 call_schema: %{
                   from: {:eoa_address, required: true},
                   to: {:eoa_address, required: true},
                   amount: {:loop, required: true}
                 }
               )
    end

    test "when the call is successful (with params) and response schema, returns value",
         %{
           identity: identity,
           bypass: bypass
         } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("0x1")

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, true} =
               Icon.call(
                 identity,
                 "cx2e243ad926ac48d15156756fce28314357d49d83",
                 "transfer",
                 %{
                   from: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
                   to: "hx2e243ad926ac48d15156756fce28314357d49d83",
                   amount: 1_000_000_000_000_000_000
                 },
                 call_schema: %{
                   from: {:eoa_address, required: true},
                   to: {:eoa_address, required: true},
                   amount: {:loop, required: true}
                 },
                 response_schema: :boolean
               )
    end

    test "when the response is invalid, returns error", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast call response"
              }} =
               Icon.call(
                 identity,
                 "cx2e243ad926ac48d15156756fce28314357d49d83",
                 "method",
                 nil,
                 response_schema: :integer
               )
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} =
               Icon.call(
                 identity,
                 "cx2e243ad926ac48d15156756fce28314357d49d83",
                 "method"
               )
    end
  end

  describe "get_transaction_result/2" do
    setup do
      bypass = Bypass.open()
      identity = Identity.new(node: "http://localhost:#{bypass.port}")

      hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      {:ok, bypass: bypass, identity: identity, hash: hash}
    end

    test "when the transaction is successful, returns transaction result", %{
      hash: hash,
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "status" => "0x1",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => "hx2e243ad926ac48d15156756fce28314357d49d83",
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :success,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cumulativeStepUsed: 100_000,
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: "hx2e243ad926ac48d15156756fce28314357d49d83",
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} = Icon.get_transaction_result(identity, hash)
    end

    test "when the request times out, returns transaction result with failure",
         %{
           hash: hash,
           identity: identity,
           bypass: bypass
         } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "failure" => %{
              "code" => -31_006,
              "message" => "Timeout",
              "data" =>
                "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"
            },
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "status" => "0x0",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => "hx2e243ad926ac48d15156756fce28314357d49d83",
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :failure,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cumulativeStepUsed: 100_000,
                failure: %Error{
                  code: -31_006,
                  message: "Timeout",
                  data:
                    "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                  reason: :timeout,
                  domain: :request
                },
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: "hx2e243ad926ac48d15156756fce28314357d49d83",
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} = Icon.get_transaction_result(identity, hash, timeout: 5_000)
    end

    test "when the result is not valid, returns error", %{
      hash: hash,
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast transaction result"
              }} = Icon.get_transaction_result(identity, hash)
    end

    test "when server responds with an error, errors", %{
      hash: hash,
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} = Icon.get_transaction_result(identity, hash)
    end
  end

  describe "get_transaction_by_hash/2" do
    setup do
      bypass = Bypass.open()
      identity = Identity.new(node: "http://localhost:#{bypass.port}")

      hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      {:ok, bypass: bypass, identity: identity, hash: hash}
    end

    test "when the transaction is successful, returns transaction", %{
      hash: hash,
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0xd6e8ed8035b38a5c09de59df101c7e6258e6d7e0690d3c6c6093045a5550bb83",
            "blockHeight" => "0x2b120c6",
            "data" => %{
              "method" => "transfer",
              "params" => %{
                "_data" =>
                  "0x7b226d6574686f64223a20225f73776170222c2022706172616d73223a207b22746f546f6b656e223a2022637838386664376466376464666638326637636337333563383731646335313938333863623233356262222c20226d696e696d756d52656365697665223a202231303030303230303030303030303030303030303030222c202270617468223a205b22637832363039623932346533336566303062363438613430393234356337656133393463343637383234222c2022637866363163643561343564633966393163313561613635383331613330613930643539613039363139222c2022637838386664376466376464666638326637636337333563383731646335313938333863623233356262225d7d7d",
                "_to" => "cx21e94c08c03daee80c25d8ee3ea22a20786ec231",
                "_value" => "0x363610bbaabe220000"
              }
            },
            "dataType" => "call",
            "from" => "hx948b9727f426ae7789741da8c796807f78ba137f",
            "nid" => "0x1",
            "nonce" => "0xdf",
            "signature" =>
              "TTfXvXZ3NG53R2tx9D69fMvmHW8mIIWWEDZnNfOgGG1BOeGYSYzV37PWCi7ryXKKAc7e80ue937yrull8hoZxgE=",
            "stepLimit" => "0x2faf080",
            "timestamp" => "0x5d62620d16b86",
            "to" => "cx88fd7df7ddff82f7cc735c871dc519838cb235bb",
            "txHash" => hash,
            "txIndex" => "0x2",
            "value" => "0x0",
            "version" => "0x3"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction{
                blockHash:
                  "0xd6e8ed8035b38a5c09de59df101c7e6258e6d7e0690d3c6c6093045a5550bb83",
                blockHeight: 45_162_694,
                data: %{
                  method: "transfer",
                  params: %{
                    "_data" =>
                      "0x7b226d6574686f64223a20225f73776170222c2022706172616d73223a207b22746f546f6b656e223a2022637838386664376466376464666638326637636337333563383731646335313938333863623233356262222c20226d696e696d756d52656365697665223a202231303030303230303030303030303030303030303030222c202270617468223a205b22637832363039623932346533336566303062363438613430393234356337656133393463343637383234222c2022637866363163643561343564633966393163313561613635383331613330613930643539613039363139222c2022637838386664376466376464666638326637636337333563383731646335313938333863623233356262225d7d7d",
                    "_to" => "cx21e94c08c03daee80c25d8ee3ea22a20786ec231",
                    "_value" => "0x363610bbaabe220000"
                  }
                },
                dataType: :call,
                from: "hx948b9727f426ae7789741da8c796807f78ba137f",
                nid: 1,
                nonce: 223,
                signature:
                  "TTfXvXZ3NG53R2tx9D69fMvmHW8mIIWWEDZnNfOgGG1BOeGYSYzV37PWCi7ryXKKAc7e80ue937yrull8hoZxgE=",
                stepLimit: 50_000_000,
                timestamp: ~U[2022-01-22 06:48:51.250054Z],
                to: "cx88fd7df7ddff82f7cc735c871dc519838cb235bb",
                txHash: ^hash,
                txIndex: 2,
                value: 0,
                version: 3
              }} = Icon.get_transaction_by_hash(identity, hash)
    end

    test "when the result is not valid, returns error", %{
      hash: hash,
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast transaction"
              }} = Icon.get_transaction_by_hash(identity, hash)
    end

    test "when server responds with an error, errors", %{
      hash: hash,
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} = Icon.get_transaction_by_hash(identity, hash)
    end
  end

  describe "transfer/4" do
    setup do
      bypass = Bypass.open()

      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity =
        Identity.new(
          private_key: private_key,
          node: "http://localhost:#{bypass.port}"
        )

      {:ok, bypass: bypass, identity: identity}
    end

    test "when the transaction is sent, returns hash", %{
      identity: identity,
      bypass: bypass
    } do
      recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"
      amount = 1_000_000_000_000_000_000

      tx_hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(tx_hash)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, ^tx_hash} = Icon.transfer(identity, recipient, amount)
    end

    test "when the transaction is sent and doesn't timeout, returns result", %{
      identity: identity,
      bypass: bypass
    } do
      recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"
      amount = 1_000_000_000_000_000_000

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "status" => "0x1",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => recipient,
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :success,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cumulativeStepUsed: 100_000,
                failure: nil,
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: ^recipient,
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} = Icon.transfer(identity, recipient, amount, timeout: 5_000)
    end

    test "when the response is invalid, returns error", %{
      identity: identity,
      bypass: bypass
    } do
      recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"
      amount = 1_000_000_000_000_000_000

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast transaction result"
              }} = Icon.transfer(identity, recipient, amount)
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass
    } do
      recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"
      amount = 1_000_000_000_000_000_000

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} = Icon.transfer(identity, recipient, amount)
    end
  end

  describe "send_message/4" do
    setup do
      bypass = Bypass.open()

      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity =
        Identity.new(
          private_key: private_key,
          node: "http://localhost:#{bypass.port}"
        )

      {:ok, bypass: bypass, identity: identity}
    end

    test "when the transaction is sent, returns hash", %{
      identity: identity,
      bypass: bypass
    } do
      recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"

      tx_hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(tx_hash)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, ^tx_hash} = Icon.send_message(identity, recipient, "Hello!")
    end

    test "when the transaction is sent and doesn't timeout, returns result", %{
      identity: identity,
      bypass: bypass
    } do
      recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "status" => "0x1",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => recipient,
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :success,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cumulativeStepUsed: 100_000,
                failure: nil,
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: ^recipient,
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} =
               Icon.send_message(identity, recipient, "Hello!", timeout: 5_000)
    end

    test "when the response is invalid, returns error", %{
      identity: identity,
      bypass: bypass
    } do
      recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast transaction result"
              }} = Icon.send_message(identity, recipient, "Hello!")
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass
    } do
      recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} = Icon.send_message(identity, recipient, "Hello!")
    end
  end

  describe "transaction_call/5" do
    setup do
      bypass = Bypass.open()

      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity =
        Identity.new(
          private_key: private_key,
          node: "http://localhost:#{bypass.port}"
        )

      {:ok, bypass: bypass, identity: identity}
    end

    test "when the transaction is sent (without params), returns hash", %{
      identity: identity,
      bypass: bypass
    } do
      tx_hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(tx_hash)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, ^tx_hash} =
               Icon.transaction_call(
                 identity,
                 "cx2e243ad926ac48d15156756fce28314357d49d83",
                 "method"
               )
    end

    test "when the transaction is sent (with params), returns hash", %{
      identity: identity,
      bypass: bypass
    } do
      tx_hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(tx_hash)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, ^tx_hash} =
               Icon.transaction_call(
                 identity,
                 "cx2e243ad926ac48d15156756fce28314357d49d83",
                 "transfer",
                 %{
                   from: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
                   to: "hx2e243ad926ac48d15156756fce28314357d49d83",
                   amount: 1_000_000_000_000_000_000
                 },
                 call_schema: %{
                   from: {:eoa_address, required: true},
                   to: {:eoa_address, required: true},
                   amount: {:loop, required: true}
                 }
               )
    end

    test "when the transaction is sent and doesn't timeout, returns result", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "scoreAddress" => nil,
            "status" => "0x1",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => "cx2e243ad926ac48d15156756fce28314357d49d83",
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :success,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cumulativeStepUsed: 100_000,
                failure: nil,
                scoreAddress: nil,
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: "cx2e243ad926ac48d15156756fce28314357d49d83",
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} =
               Icon.transaction_call(
                 identity,
                 "cx2e243ad926ac48d15156756fce28314357d49d83",
                 "transfer",
                 %{
                   from: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
                   to: "hx2e243ad926ac48d15156756fce28314357d49d83",
                   amount: 1_000_000_000_000_000_000
                 },
                 call_schema: %{
                   from: {:eoa_address, required: true},
                   to: {:eoa_address, required: true},
                   amount: {:loop, required: true}
                 },
                 timeout: 5_000
               )
    end

    test "when the response is invalid, returns error", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast transaction result"
              }} =
               Icon.transaction_call(
                 identity,
                 "cx2e243ad926ac48d15156756fce28314357d49d83",
                 "method"
               )
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} =
               Icon.transaction_call(
                 identity,
                 "cx2e243ad926ac48d15156756fce28314357d49d83",
                 "method"
               )
    end
  end

  describe "install_score/3" do
    setup do
      bypass = Bypass.open()

      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity =
        Identity.new(
          private_key: private_key,
          node: "http://localhost:#{bypass.port}"
        )

      unique_id = '#{:erlang.phash2(make_ref())}'

      {:ok, {_, content}} =
        :zip.create(unique_id, [{'file.txt', "ICON 2.0"}], [:memory])

      {:ok, bypass: bypass, identity: identity, content: content}
    end

    test "when the transaction is sent, returns hash", %{
      identity: identity,
      bypass: bypass,
      content: content
    } do
      tx_hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(tx_hash)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, ^tx_hash} = Icon.install_score(identity, content)
    end

    test "when the transaction is sent and doesn't timeout, returns result", %{
      identity: identity,
      bypass: bypass,
      content: content
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
            "status" => "0x1",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => "cx0000000000000000000000000000000000000000",
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :success,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cumulativeStepUsed: 100_000,
                failure: nil,
                scoreAddress: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: "cx0000000000000000000000000000000000000000",
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} = Icon.install_score(identity, content, timeout: 5_000)
    end

    test "when the response is invalid, returns error", %{
      identity: identity,
      bypass: bypass,
      content: content
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast transaction result"
              }} = Icon.install_score(identity, content)
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass,
      content: content
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} = Icon.install_score(identity, content)
    end
  end

  describe "update_score/3" do
    setup do
      bypass = Bypass.open()

      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity =
        Identity.new(
          private_key: private_key,
          node: "http://localhost:#{bypass.port}"
        )

      unique_id = '#{:erlang.phash2(make_ref())}'

      {:ok, {_, content}} =
        :zip.create(unique_id, [{'file.txt', "ICON 2.0"}], [:memory])

      {:ok, bypass: bypass, identity: identity, content: content}
    end

    test "when the transaction is sent, returns hash", %{
      identity: identity,
      bypass: bypass,
      content: content
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      tx_hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(tx_hash)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, ^tx_hash} =
               Icon.update_score(identity, score_address, content)
    end

    test "when the transaction is sent and doesn't timeout, returns result", %{
      identity: identity,
      bypass: bypass,
      content: content
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "status" => "0x1",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :success,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cumulativeStepUsed: 100_000,
                failure: nil,
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} =
               Icon.update_score(identity, score_address, content,
                 timeout: 5_000
               )
    end

    test "when the response is invalid, returns error", %{
      identity: identity,
      bypass: bypass,
      content: content
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast transaction result"
              }} = Icon.update_score(identity, score_address, content)
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass,
      content: content
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} = Icon.update_score(identity, score_address, content)
    end
  end

  describe "deposit_shared_fee/4" do
    setup do
      bypass = Bypass.open()

      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity =
        Identity.new(
          private_key: private_key,
          node: "http://localhost:#{bypass.port}"
        )

      {:ok, bypass: bypass, identity: identity}
    end

    test "when the transaction is sent, returns hash", %{
      identity: identity,
      bypass: bypass
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      tx_hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(tx_hash)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, ^tx_hash} =
               Icon.deposit_shared_fee(identity, score_address, 42)
    end

    test "when the transaction is sent and doesn't timeout, returns result", %{
      identity: identity,
      bypass: bypass
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "status" => "0x1",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :success,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cumulativeStepUsed: 100_000,
                failure: nil,
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} =
               Icon.deposit_shared_fee(identity, score_address, 42,
                 timeout: 5_000
               )
    end

    test "when the response is invalid, returns error", %{
      identity: identity,
      bypass: bypass
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast transaction result"
              }} = Icon.deposit_shared_fee(identity, score_address, 42)
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} = Icon.deposit_shared_fee(identity, score_address, 42)
    end
  end

  describe "withdraw_shared_fee/4" do
    setup do
      bypass = Bypass.open()

      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity =
        Identity.new(
          private_key: private_key,
          node: "http://localhost:#{bypass.port}"
        )

      {:ok, bypass: bypass, identity: identity}
    end

    test "when the transaction is sent, returns hash", %{
      identity: identity,
      bypass: bypass
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      tx_hash =
        "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(tx_hash)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, ^tx_hash} = Icon.withdraw_shared_fee(identity, score_address)
    end

    test "when the transaction is sent and doesn't timeout, returns result", %{
      identity: identity,
      bypass: bypass
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "blockHash" =>
              "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
            "blockHeight" => "0x250b45",
            "cumulativeStepUsed" => "0x186a0",
            "eventLogs" => [],
            "logsBloom" =>
              "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "status" => "0x1",
            "stepPrice" => "0x2e90edd00",
            "stepUsed" => "0x186a0",
            "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
            "txHash" =>
              "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "txIndex" => "0x1"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok,
              %Transaction.Result{
                status: :success,
                blockHash:
                  "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
                blockHeight: 2_427_717,
                cumulativeStepUsed: 100_000,
                failure: nil,
                stepPrice: 12_500_000_000,
                stepUsed: 100_000,
                to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                txHash:
                  "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
                txIndex: 1
              }} =
               Icon.withdraw_shared_fee(identity, score_address, 42,
                 timeout: 5_000
               )
    end

    test "when the response is invalid, returns error", %{
      identity: identity,
      bypass: bypass
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result("invalid")
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:error,
              %Error{
                reason: :server_error,
                message: "cannot cast transaction result"
              }} = Icon.withdraw_shared_fee(identity, score_address, 42)
    end

    test "when server responds with an error, errors", %{
      identity: identity,
      bypass: bypass
    } do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        response = result("0x186a0")

        Plug.Conn.resp(conn, 200, response)
      end)

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:error,
              %Error{
                reason: :system_error,
                message: "System error"
              }} = Icon.withdraw_shared_fee(identity, score_address, 42)
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

  @spec error(map()) :: binary()
  defp error(error) when is_map(error) do
    %{
      "jsonrpc" => "2.0",
      "id" => :erlang.system_time(:microsecond),
      "error" => error
    }
    |> Jason.encode!()
  end
end
