defmodule Icon.RPC.RequestTest do
  use ExUnit.Case, async: true

  alias Icon.RPC.{Identity, Request}
  alias Icon.Schema.Error

  describe "build/3" do
    test "sets an id" do
      assert %Request{id: id} = Request.build("method", %{}, [])
      assert is_integer(id) and id > 0
    end

    test "sets a method" do
      assert %Request{method: "method"} = Request.build("method", %{}, [])
    end

    test "sets params" do
      assert %Request{params: %{int: 42}} =
               Request.build("method", %{int: 42}, [])
    end

    test "does not override provided identity" do
      params = %{int: 42}
      %Identity{node: node} = identity = Identity.new(debug: true)

      options = [
        schema: %{int: :integer},
        identity: identity
      ]

      expected_url = "#{node}/api/v3d"

      assert %Request{
               options: %{
                 schema: %{int: :integer},
                 identity: ^identity,
                 url: ^expected_url
               }
             } = Request.build("method", params, options)
    end
  end

  describe "add_step_limit/1, add_step_limit/2 and add_step_limit/3" do
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

    test "adds step limit to an icx_sendTransaction", %{
      bypass: bypass,
      identity: identity
    } do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 1_000_000_000_000_000_000

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        result = result("0x186a0")
        Plug.Conn.resp(conn, 200, result)
      end)

      assert {:ok, %Request{} = request} =
               Request.Goloop.transfer(identity, to, value)

      assert {:ok,
              %Request{
                method: "icx_sendTransaction",
                options: %{
                  identity: ^identity
                },
                params: %{
                  to: ^to,
                  value: ^value,
                  stepLimit: 100_000
                }
              }} = Request.add_step_limit(request, nil, cache: false)
    end

    test "adds step limit to an icx_sendTransactionAndWait", %{
      bypass: bypass,
      identity: identity
    } do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 1_000_000_000_000_000_000
      timeout = 5_000

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        result = result("0x186a0")
        Plug.Conn.resp(conn, 200, result)
      end)

      assert {:ok, %Request{} = request} =
               Request.Goloop.transfer(identity, to, value, timeout: timeout)

      assert {:ok,
              %Request{
                method: "icx_sendTransactionAndWait",
                options: %{
                  identity: ^identity,
                  timeout: ^timeout
                },
                params: %{
                  to: ^to,
                  value: ^value,
                  stepLimit: 100_000
                }
              }} = Request.add_step_limit(request, nil, cache: false)
    end

    test "when step limit is already calculated for a transfer, returns it",
         %{
           bypass: bypass,
           identity: identity
         } do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 1_000_000_000_000_000_000

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        result = result("0x186a0")
        Plug.Conn.resp(conn, 200, result)
      end)

      assert {:ok, %Request{} = request} =
               Request.Goloop.transfer(identity, to, value)

      assert {:ok, %Request{}} = Request.add_step_limit(request)
      assert {:ok, %Request{}} = Request.add_step_limit(request)
    end

    test "when sending a message, requests step limit every time",
         %{
           bypass: bypass,
           identity: identity
         } do
      pid = self()
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      message = "ICON 2.0"

      Bypass.expect(bypass, "POST", "/api/v3d", fn conn ->
        result = result("0x186a0")
        send(pid, :requested)
        Plug.Conn.resp(conn, 200, result)
      end)

      assert {:ok, %Request{} = request} =
               Request.Goloop.send_message(identity, to, message)

      assert {:ok, %Request{}} = Request.add_step_limit(request)
      assert_receive :requested
      assert {:ok, %Request{}} = Request.add_step_limit(request)
      assert_receive :requested
    end

    test "when there's an error requesting the estimation, errors", %{
      bypass: bypass,
      identity: identity
    } do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 1_000_000_000_000_000_000

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        error =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, error)
      end)

      assert {:ok, %Request{} = request} =
               Request.Goloop.transfer(identity, to, value)

      assert {
               :error,
               %Error{
                 reason: :system_error,
                 message: "System error"
               }
             } = Request.add_step_limit(request, nil, cache: false)
    end

    test "when requested step limit is invalid, errors", %{
      bypass: bypass,
      identity: identity
    } do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 1_000_000_000_000_000_000

      Bypass.expect_once(bypass, "POST", "/api/v3d", fn conn ->
        result = result("invalid")
        Plug.Conn.resp(conn, 200, result)
      end)

      assert {:ok, %Request{} = request} =
               Request.Goloop.transfer(identity, to, value)

      assert {
               :error,
               %Error{
                 reason: :system_error,
                 message: "cannot estimate stepLimit"
               }
             } = Request.add_step_limit(request, nil, cache: false)
    end

    test "when request is not a transaction, errors", %{
      identity: identity
    } do
      assert {:ok, %Request{} = request} =
               Request.Goloop.get_last_block(identity)

      assert {
               :error,
               %Error{
                 reason: :invalid_request,
                 message: "only transactions have step limit"
               }
             } = Request.add_step_limit(request, nil, cache: false)
    end
  end

  describe "serialize/1" do
    setup do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key, network_id: :sejong)

      {:ok, identity: identity}
    end

    test "serializes a transaction without data", %{identity: identity} do
      params = %{
        to: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        value: 1_000_000_000_000_000_000,
        stepLimit: 100_000,
        nonce: 1,
        timestamp: 1_641_305_061_359_062
      }

      {:ok, request} = Request.Goloop.send_transaction(identity, params: params)

      expected =
        "icx_sendTransaction.from.hxfd7e4560ba363f5aabd32caac7317feeee70ea57.nid.0x53.nonce.0x1.stepLimit.0x186a0.timestamp.0x5d4c21d267dd6.to.hxbe258ceb872e08851f1f59694dac2558708ece11.value.0xde0b6b3a7640000.version.0x3"

      assert {:ok, ^expected} = Request.serialize(request)
    end

    test "serializes a transaction with complex data", %{identity: identity} do
      params = %{
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 1_000_000_000_000_000_000,
        stepLimit: 100_000,
        nonce: 1,
        timestamp: 1_641_305_061_359_062,
        dataType: :call,
        data: %{
          method: "getBalance",
          params: %{
            address: "hxbe258ceb872e08851f1f59694dac2558708ece11"
          }
        }
      }

      {:ok, request} =
        Request.Goloop.send_transaction(
          identity,
          params: params,
          schema: %{address: {:eoa_address, required: true}}
        )

      expected =
        "icx_sendTransaction.data.{method.getBalance.params.{address.hxbe258ceb872e08851f1f59694dac2558708ece11}}.dataType.call.from.hxfd7e4560ba363f5aabd32caac7317feeee70ea57.nid.0x53.nonce.0x1.stepLimit.0x186a0.timestamp.0x5d4c21d267dd6.to.cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32.value.0xde0b6b3a7640000.version.0x3"

      assert {:ok, ^expected} = Request.serialize(request)
    end

    test "ignores signature", %{identity: identity} do
      params = %{
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 1_000_000_000_000_000_000,
        stepLimit: 100_000,
        nonce: 1,
        timestamp: 1_641_305_061_359_062,
        dataType: :call,
        data: %{
          method: "getBalance",
          params: %{
            address: "hxbe258ceb872e08851f1f59694dac2558708ece11"
          }
        }
      }

      assert {:ok, request} =
               Request.Goloop.send_transaction(
                 identity,
                 params: params,
                 schema: %{address: {:eoa_address, required: true}}
               )

      assert {:ok, request} = Request.sign(request)

      assert {:ok, serialized} = Request.serialize(request)
      refute serialized =~ "signature."
    end

    test "serializes a list", %{identity: identity} do
      params = %{
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 1_000_000_000_000_000_000,
        stepLimit: 100_000,
        nonce: 1,
        timestamp: 1_641_305_061_359_062,
        dataType: :call,
        data: %{
          method: "getBalance",
          params: %{
            addresses: [
              "hxbe258ceb872e08851f1f59694dac2558708ece11",
              "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
            ]
          }
        }
      }

      {:ok, request} =
        Request.Goloop.send_transaction(
          identity,
          params: params,
          schema: %{addresses: {{:list, :address}, required: true}}
        )

      expected =
        "icx_sendTransaction.data.{method.getBalance.params.{addresses.[hxbe258ceb872e08851f1f59694dac2558708ece11.cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32]}}.dataType.call.from.hxfd7e4560ba363f5aabd32caac7317feeee70ea57.nid.0x53.nonce.0x1.stepLimit.0x186a0.timestamp.0x5d4c21d267dd6.to.cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32.value.0xde0b6b3a7640000.version.0x3"

      assert {:ok, ^expected} = Request.serialize(request)
    end

    test "serializes nil values", %{identity: identity} do
      params = %{
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 1_000_000_000_000_000_000,
        stepLimit: 100_000,
        nonce: 1,
        timestamp: 1_641_305_061_359_062,
        dataType: :call,
        data: %{
          method: "nullable",
          params: %{
            nullable: nil
          }
        }
      }

      {:ok, request} =
        Request.Goloop.send_transaction(
          identity,
          params: params,
          schema: %{nullable: {:address, nullable: true}}
        )

      expected =
        "icx_sendTransaction.data.{method.nullable.params.{nullable.\\0}}.dataType.call.from.hxfd7e4560ba363f5aabd32caac7317feeee70ea57.nid.0x53.nonce.0x1.stepLimit.0x186a0.timestamp.0x5d4c21d267dd6.to.cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32.value.0xde0b6b3a7640000.version.0x3"

      assert {:ok, ^expected} = Request.serialize(request)
    end

    test "serializes a backward slash", %{identity: identity} do
      params = %{
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 1_000_000_000_000_000_000,
        stepLimit: 100_000,
        nonce: 1,
        timestamp: 1_641_305_061_359_062,
        dataType: :call,
        data: %{
          method: "message",
          params: %{
            message: "\\"
          }
        }
      }

      {:ok, request} =
        Request.Goloop.send_transaction(
          identity,
          params: params,
          schema: %{message: {:string, required: true}}
        )

      expected =
        "icx_sendTransaction.data.{method.message.params.{message.\\\\}}.dataType.call.from.hxfd7e4560ba363f5aabd32caac7317feeee70ea57.nid.0x53.nonce.0x1.stepLimit.0x186a0.timestamp.0x5d4c21d267dd6.to.cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32.value.0xde0b6b3a7640000.version.0x3"

      assert {:ok, ^expected} = Request.serialize(request)
    end

    test "serializes a opening brace", %{identity: identity} do
      params = %{
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 1_000_000_000_000_000_000,
        stepLimit: 100_000,
        nonce: 1,
        timestamp: 1_641_305_061_359_062,
        dataType: :call,
        data: %{
          method: "message",
          params: %{
            message: "{"
          }
        }
      }

      {:ok, request} =
        Request.Goloop.send_transaction(
          identity,
          params: params,
          schema: %{message: {:string, required: true}}
        )

      expected =
        "icx_sendTransaction.data.{method.message.params.{message.\\{}}.dataType.call.from.hxfd7e4560ba363f5aabd32caac7317feeee70ea57.nid.0x53.nonce.0x1.stepLimit.0x186a0.timestamp.0x5d4c21d267dd6.to.cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32.value.0xde0b6b3a7640000.version.0x3"

      assert {:ok, ^expected} = Request.serialize(request)
    end

    test "serializes a closing brace", %{identity: identity} do
      params = %{
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 1_000_000_000_000_000_000,
        stepLimit: 100_000,
        nonce: 1,
        timestamp: 1_641_305_061_359_062,
        dataType: :call,
        data: %{
          method: "message",
          params: %{
            message: "}"
          }
        }
      }

      {:ok, request} =
        Request.Goloop.send_transaction(
          identity,
          params: params,
          schema: %{message: {:string, required: true}}
        )

      expected =
        "icx_sendTransaction.data.{method.message.params.{message.\\}}}.dataType.call.from.hxfd7e4560ba363f5aabd32caac7317feeee70ea57.nid.0x53.nonce.0x1.stepLimit.0x186a0.timestamp.0x5d4c21d267dd6.to.cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32.value.0xde0b6b3a7640000.version.0x3"

      assert {:ok, ^expected} = Request.serialize(request)
    end

    test "serializes a opening bracket", %{identity: identity} do
      params = %{
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 1_000_000_000_000_000_000,
        stepLimit: 100_000,
        nonce: 1,
        timestamp: 1_641_305_061_359_062,
        dataType: :call,
        data: %{
          method: "message",
          params: %{
            message: "["
          }
        }
      }

      {:ok, request} =
        Request.Goloop.send_transaction(
          identity,
          params: params,
          schema: %{message: {:string, required: true}}
        )

      expected =
        "icx_sendTransaction.data.{method.message.params.{message.\\[}}.dataType.call.from.hxfd7e4560ba363f5aabd32caac7317feeee70ea57.nid.0x53.nonce.0x1.stepLimit.0x186a0.timestamp.0x5d4c21d267dd6.to.cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32.value.0xde0b6b3a7640000.version.0x3"

      assert {:ok, ^expected} = Request.serialize(request)
    end

    test "serializes a closing bracket", %{identity: identity} do
      params = %{
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 1_000_000_000_000_000_000,
        stepLimit: 100_000,
        nonce: 1,
        timestamp: 1_641_305_061_359_062,
        dataType: :call,
        data: %{
          method: "message",
          params: %{
            message: "]"
          }
        }
      }

      {:ok, request} =
        Request.Goloop.send_transaction(
          identity,
          params: params,
          schema: %{message: {:string, required: true}}
        )

      expected =
        "icx_sendTransaction.data.{method.message.params.{message.\\]}}.dataType.call.from.hxfd7e4560ba363f5aabd32caac7317feeee70ea57.nid.0x53.nonce.0x1.stepLimit.0x186a0.timestamp.0x5d4c21d267dd6.to.cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32.value.0xde0b6b3a7640000.version.0x3"

      assert {:ok, ^expected} = Request.serialize(request)
    end

    test "serializes a dot", %{identity: identity} do
      params = %{
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 1_000_000_000_000_000_000,
        stepLimit: 100_000,
        nonce: 1,
        timestamp: 1_641_305_061_359_062,
        dataType: :call,
        data: %{
          method: "message",
          params: %{
            message: "."
          }
        }
      }

      {:ok, request} =
        Request.Goloop.send_transaction(
          identity,
          params: params,
          schema: %{message: {:string, required: true}}
        )

      expected =
        "icx_sendTransaction.data.{method.message.params.{message.\\.}}.dataType.call.from.hxfd7e4560ba363f5aabd32caac7317feeee70ea57.nid.0x53.nonce.0x1.stepLimit.0x186a0.timestamp.0x5d4c21d267dd6.to.cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32.value.0xde0b6b3a7640000.version.0x3"

      assert {:ok, ^expected} = Request.serialize(request)
    end

    test "when parameters are invalid, errors", %{identity: identity} do
      params = %{
        to: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        value: 1_000_000_000_000_000_000,
        stepLimit: 100_000
      }

      {:ok, request} = Request.Goloop.send_transaction(identity, params: params)

      request = %{request | params: Map.delete(request.params, :to)}

      assert {:error,
              %Error{
                code: -32_602,
                domain: :unknown,
                message: "to is required",
                reason: :invalid_params
              }} = Request.serialize(request)
    end

    test "when it is not a transaction, errors", %{identity: identity} do
      assert {:ok, request} = Request.Goloop.get_last_block(identity)

      assert {:error,
              %Error{
                code: -32_602,
                domain: :request,
                message: "cannot serialize method icx_getLastBlock",
                reason: :invalid_params
              }} = Request.serialize(request)
    end
  end

  describe "sign/1 and verify/1" do
    setup do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      {:ok, identity: identity}
    end

    test "when params are valid, generates signature", %{identity: identity} do
      params = %{
        to: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        value: 1_000_000_000_000_000_000,
        stepLimit: 100_000
      }

      assert {:ok, %Request{} = request} =
               Request.Goloop.send_transaction(identity, params: params)

      assert {:ok, %Request{} = request} = Request.sign(request)
      assert Request.verify(request)
    end

    test "when params are invalid, errors", %{identity: identity} do
      params = %{
        to: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        value: 1_000_000_000_000_000_000,
        stepLimit: 100_000
      }

      assert {:ok, %Request{} = request} =
               Request.Goloop.send_transaction(identity, params: params)

      request = %{request | params: Map.delete(request.params, :to)}

      assert {:error, %Error{message: "to is required"}} = Request.sign(request)
    end

    test "when identity cannot sign, errors", %{identity: identity} do
      params = %{
        to: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        value: 1_000_000_000_000_000_000,
        stepLimit: 100_000
      }

      assert {:ok, %Request{} = request} =
               Request.Goloop.send_transaction(identity, params: params)

      request = %{
        request
        | options: Map.put(request.options, :identity, Identity.new())
      }

      assert {:error,
              %Error{
                code: -32_600,
                domain: :request,
                message: "cannot sign request",
                reason: :invalid_request
              }} = Request.sign(request)
    end

    test "when there's no signature, verification fails", %{identity: identity} do
      params = %{
        to: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        value: 1_000_000_000_000_000_000,
        stepLimit: 100_000
      }

      assert {:ok, %Request{} = request} =
               Request.Goloop.send_transaction(identity, params: params)

      refute Request.verify(request)
    end
  end

  describe "request/2 with mocked API" do
    setup do
      bypass = Bypass.open()

      identity =
        Identity.new(
          private_key:
            "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf",
          node: "http://localhost:#{bypass.port}"
        )

      {:ok, bypass: bypass, identity: identity}
    end

    test "decodes result on successful call", %{
      bypass: bypass,
      identity: identity
    } do
      expected = %{
        "height" => "0x2a",
        "hash" =>
          "c71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"
      }

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(expected)
        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, %Request{} = rpc} = Request.Goloop.get_last_block(identity)

      assert {:ok, ^expected} = Request.send(rpc)
    end

    test "when there's no timeout, then there's no special Icon header", %{
      bypass: bypass,
      identity: identity
    } do
      tx_hash =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(%{"txHash" => tx_hash})

        assert Enum.all?(conn.req_headers, fn {name, _} ->
                 name != "icon-options"
               end)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, %Request{} = rpc} =
               Request.Goloop.get_transaction_result(identity, tx_hash)

      assert {:ok, _} = Request.send(rpc)
    end

    test "when there's timeout, then there's special Icon header", %{
      bypass: bypass,
      identity: identity
    } do
      tx_hash =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response = result(%{"txHash" => tx_hash})

        assert Enum.any?(conn.req_headers, fn {name, value} ->
                 name == "icon-options" and value == "5000"
               end)

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, %Request{} = rpc} =
               Request.Goloop.get_transaction_result(identity, tx_hash,
                 timeout: 5_000
               )

      assert {:ok, _} = Request.send(rpc)
    end

    test "when there's no connection, errors" do
      identity = Identity.new(node: "http://unexistent")

      assert {:ok, %Request{} = rpc} = Request.Goloop.get_last_block(identity)

      assert {:error,
              %Error{
                code: -31_000,
                data: nil,
                domain: :request,
                message: "System error",
                reason: :system_error
              }} = Request.send(rpc)
    end

    test "when the API returns an error, errors", %{
      bypass: bypass,
      identity: identity
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        error =
          error(%{
            "code" => -31_004,
            "message" => "Not found"
          })

        Plug.Conn.resp(conn, 404, error)
      end)

      assert {:ok, %Request{} = rpc} = Request.Goloop.get_last_block(identity)

      assert {:error,
              %Error{
                code: -31_004,
                data: nil,
                domain: :request,
                message: "Not found",
                reason: :not_found
              }} = Request.send(rpc)
    end

    test "when payload does not conform with API, errors", %{
      bypass: bypass,
      identity: identity
    } do
      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      assert {:ok, %Request{} = rpc} = Request.Goloop.get_last_block(identity)

      assert {:error,
              %Error{
                code: -31_000,
                data: nil,
                domain: :request,
                message: "System error",
                reason: :system_error
              }} = Request.send(rpc)
    end
  end

  describe "request/1 without mocked API" do
    test "connects with default node" do
      assert {:ok, %Request{} = rpc} =
               Identity.new()
               |> Request.Goloop.get_last_block()

      assert {:ok, block} = Request.send(rpc)
      assert is_map(block)
    end
  end

  describe "encoder" do
    test "ignores options" do
      payload =
        "icx_method"
        |> Request.build(%{integer: 42}, schema: %{integer: :integer})
        |> Jason.encode!()
        |> Jason.decode!()

      assert :miss = Map.get(payload, "options", :miss)
    end

    test "adds jsonrpc version" do
      assert %{"jsonrpc" => "2.0"} =
               "icx_method"
               |> Request.build(%{}, [])
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "keeps the id" do
      assert %{"id" => id} =
               "icx_method"
               |> Request.build(%{}, [])
               |> Jason.encode!()
               |> Jason.decode!()

      assert is_integer(id) and id > 0
    end

    test "keeps the method" do
      assert %{"method" => "icx_method"} =
               "icx_method"
               |> Request.build(%{}, [])
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "encodes params according to type" do
      params = %{
        address: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        binary_data: "ICON 2.0",
        boolean: true,
        eoa: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        hash:
          "c71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
        integer: 42,
        score: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        signature:
          "VAia7YZ2Ji6igKWzjR2YsGa2m53nKPrfK7uXYW78QLE+ATehAVZPC40szvAiA6NEU5gCYB4c4qaQzqDh2ugcHgA=",
        string: "don't panic"
      }

      options = [
        schema: %{
          address: :address,
          binary_data: :binary_data,
          boolean: :boolean,
          eoa: :eoa_address,
          hash: :hash,
          integer: :integer,
          score: :score_address,
          signature: :signature,
          string: :string
        }
      ]

      assert %{
               "params" => %{
                 "address" => "hxbe258ceb872e08851f1f59694dac2558708ece11",
                 "binary_data" => "0x49434f4e20322e30",
                 "boolean" => "0x1",
                 "eoa" => "hxbe258ceb872e08851f1f59694dac2558708ece11",
                 "hash" =>
                   "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
                 "integer" => "0x2a",
                 "score" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "signature" =>
                   "VAia7YZ2Ji6igKWzjR2YsGa2m53nKPrfK7uXYW78QLE+ATehAVZPC40szvAiA6NEU5gCYB4c4qaQzqDh2ugcHgA=",
                 "string" => "don't panic"
               }
             } =
               "icx_method"
               |> Request.build(params, options)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "does not include empty parameters" do
      payload =
        "icx_method"
        |> Request.build(%{}, [])
        |> Jason.encode!()
        |> Jason.decode!()

      assert :miss = Map.get(payload, "params", :miss)
    end

    test "ignores value when the type is not found in the options" do
      schema = %{boolean: {:boolean, default: true}}

      assert %{"params" => %{"boolean" => "0x1"}} =
               "icx_method"
               |> Request.build(%{integer: 42}, schema: schema)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "ignores params when it's empty" do
      payload =
        "icx_method"
        |> Request.build(%{integer: 42}, schema: %{})
        |> Jason.encode!()
        |> Jason.decode!()

      assert :miss = Map.get(payload, "params", :miss)
    end

    test "raises when the schema cannot be dumped" do
      assert_raise ArgumentError, fn ->
        "icx_method"
        |> Request.build(%{integer: "INVALID"}, schema: %{integer: :integer})
        |> Jason.encode!()
        |> Jason.decode!()
      end
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
