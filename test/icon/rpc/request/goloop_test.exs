defmodule Icon.RPC.Request.GoloopTest do
  use ExUnit.Case, async: true

  alias Icon.RPC.{Identity, Request}
  alias Icon.Schema.Error

  describe "get_last_block/1" do
    setup do
      identity = Identity.new()

      {:ok, identity: identity}
    end

    test "builds RPC call for icx_getLastBlock", %{identity: identity} do
      assert {
               :ok,
               %Request{
                 method: "icx_getLastBlock",
                 options: %{url: _},
                 params: %{}
               }
             } = Request.Goloop.get_last_block(identity)
    end

    test "encodes it correctly", %{identity: identity} do
      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getLastBlock"
             } =
               identity
               |> Request.Goloop.get_last_block()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end
  end

  describe "get_block_by_height/2" do
    setup do
      identity = Identity.new()

      {:ok, identity: identity}
    end

    test "builds RPC call for icx_getBlockByHeight", %{identity: identity} do
      height = 42

      assert {
               :ok,
               %Request{
                 method: "icx_getBlockByHeight",
                 options: %{
                   url: _,
                   schema: %{height: {:integer, required: true}}
                 },
                 params: %{
                   height: ^height
                 }
               }
             } = Request.Goloop.get_block_by_height(identity, height)
    end

    test "encodes height correctly", %{identity: identity} do
      height = 42

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getBlockByHeight",
               "params" => %{
                 "height" => "0x2a"
               }
             } =
               identity
               |> Request.Goloop.get_block_by_height(height)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when invalid height is provided, errors", %{identity: identity} do
      assert {
               :error,
               %Error{message: "height is invalid"}
             } = Request.Goloop.get_block_by_height(identity, -42)
    end
  end

  describe "get_block_by_hash/2" do
    setup do
      identity = Identity.new()

      {:ok, identity: identity}
    end

    test "builds RPC call for icx_getBlockByHash", %{identity: identity} do
      hash =
        "0x8e25acc5b5c74375079d51828760821fc6f54283656620b1d5a715edcc0770c6"

      assert {
               :ok,
               %Request{
                 method: "icx_getBlockByHash",
                 options: %{
                   url: _,
                   schema: %{hash: {:hash, required: true}}
                 },
                 params: %{
                   hash: ^hash
                 }
               }
             } = Request.Goloop.get_block_by_hash(identity, hash)
    end

    test "encodes hash correctly", %{identity: identity} do
      hash =
        "0x8e25acc5b5c74375079d51828760821fc6f54283656620b1d5a715edcc0770c6"

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getBlockByHash",
               "params" => %{
                 "hash" => ^hash
               }
             } =
               identity
               |> Request.Goloop.get_block_by_hash(hash)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when invalid hash is provided, errors", %{identity: identity} do
      assert {
               :error,
               %Error{message: "hash is invalid"}
             } = Request.Goloop.get_block_by_hash(identity, "0x0")
    end
  end

  describe "call/3" do
    setup do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      {:ok, identity: identity}
    end

    test "when a valid, builds RPC call for icx_call", %{identity: identity} do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      options = [
        method: "getBalance",
        params: %{
          address: from
        },
        schema: %{address: {:address, required: true}}
      ]

      assert {
               :ok,
               %Request{
                 method: "icx_call",
                 options: %{
                   url: _,
                   schema: %{
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     dataType: {:string, default: "call"},
                     data: %{
                       method: {:string, required: true},
                       params: {
                         %{address: {:address, required: true}},
                         required: true
                       }
                     }
                   }
                 },
                 params: %{
                   from: ^from,
                   to: ^to,
                   dataType: "call",
                   data: %{
                     method: "getBalance",
                     params: %{
                       address: ^from
                     }
                   }
                 }
               }
             } = Request.Goloop.call(identity, to, options)
    end

    test "when params schema is empty, ignores parameters", %{
      identity: identity
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      options = [
        method: "getBalance",
        params: %{
          address: from
        }
      ]

      assert {
               :ok,
               %Request{
                 method: "icx_call",
                 options: %{
                   url: _,
                   schema: %{
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     dataType: {:string, default: "call"},
                     data: %{
                       method: {:string, required: true}
                     }
                   }
                 },
                 params: %{
                   from: ^from,
                   to: ^to,
                   dataType: "call",
                   data: %{
                     method: "getBalance"
                   }
                 }
               }
             } = Request.Goloop.call(identity, to, options)
    end

    test "encodes it correctly", %{identity: identity} do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      options = [
        method: "getBalance",
        params: %{
          address: from
        },
        schema: %{address: {:address, required: true}}
      ]

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_call",
               "params" => %{
                 "from" => ^from,
                 "to" => ^to,
                 "dataType" => "call",
                 "data" => %{
                   "method" => "getBalance",
                   "params" => %{
                     "address" => ^from
                   }
                 }
               }
             } =
               identity
               |> Request.Goloop.call(to, options)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when to address is invalid, errors", %{identity: identity} do
      from = identity.address
      to = "cx0"

      options = [
        method: "getBalance",
        params: %{
          address: from
        },
        schema: %{address: {:address, required: true}}
      ]

      assert {
               :error,
               %Error{message: "to is invalid"}
             } = Request.Goloop.call(identity, to, options)
    end

    test "when to is a EOA address, errors", %{identity: identity} do
      from = identity.address
      to = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      options = [
        method: "getBalance",
        params: %{
          address: from
        },
        schema: %{address: {:address, required: true}}
      ]

      assert {
               :error,
               %Error{message: "to is invalid"}
             } = Request.Goloop.call(identity, to, options)
    end

    test "when params is invalid, errors", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      options = [
        method: "getBalance",
        params: %{
          address: "hx0"
        },
        schema: %{address: {:address, required: true}}
      ]

      assert {
               :error,
               %Error{message: "data.params.address is invalid"}
             } = Request.Goloop.call(identity, to, options)
    end
  end

  describe "get_balance/2" do
    setup do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      {:ok, identity: identity}
    end

    test "when valid EOA address is provided, builds RPC call for icx_getBalance",
         %{
           identity: identity
         } do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"
      assert identity.address != address

      assert {
               :ok,
               %Request{
                 method: "icx_getBalance",
                 options: %{
                   url: _,
                   schema: %{address: {:address, required: true}}
                 },
                 params: %{
                   address: ^address
                 }
               }
             } = Request.Goloop.get_balance(identity, address)
    end

    test "when valid identity is provided, builds RPC call for icx_getBalance",
         %{
           identity: identity
         } do
      address = identity.address

      assert {
               :ok,
               %Request{
                 method: "icx_getBalance",
                 options: %{
                   url: _,
                   schema: %{address: {:address, required: true}}
                 },
                 params: %{
                   address: ^address
                 }
               }
             } = Request.Goloop.get_balance(identity)
    end

    test "encodes EOA address correctly", %{identity: identity} do
      address = identity.address

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getBalance",
               "params" => %{
                 "address" => ^address
               }
             } =
               identity
               |> Request.Goloop.get_balance()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when valid SCORE address is provided, builds RPC call for icx_getBalance",
         %{
           identity: identity
         } do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {
               :ok,
               %Request{
                 method: "icx_getBalance",
                 options: %{
                   url: _,
                   schema: %{address: {:address, required: true}}
                 },
                 params: %{
                   address: ^address
                 }
               }
             } = Request.Goloop.get_balance(identity, address)
    end

    test "encodes SCORE address correctly", %{identity: identity} do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getBalance",
               "params" => %{
                 "address" => ^address
               }
             } =
               identity
               |> Request.Goloop.get_balance(address)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when invalid EOA address is provided, errors", %{
      identity: identity
    } do
      assert {
               :error,
               %Error{message: "address is invalid"}
             } = Request.Goloop.get_balance(identity, "hx0")
    end

    test "when invalid SCORE address is provided, errors", %{
      identity: identity
    } do
      assert {
               :error,
               %Error{message: "address is invalid"}
             } = Request.Goloop.get_balance(identity, "cx0")
    end
  end

  describe "get_score_api/2" do
    setup do
      identity = Identity.new()

      {:ok, identity: identity}
    end

    test "when valid SCORE address is provided, builds RPC call for icx_getScoreApi",
         %{
           identity: identity
         } do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {
               :ok,
               %Request{
                 method: "icx_getScoreApi",
                 options: %{
                   url: _,
                   schema: %{address: {:score_address, required: true}}
                 },
                 params: %{
                   address: ^address
                 }
               }
             } = Request.Goloop.get_score_api(identity, address)
    end

    test "encodes SCORE address correctly", %{identity: identity} do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getScoreApi",
               "params" => %{
                 "address" => ^address
               }
             } =
               identity
               |> Request.Goloop.get_score_api(address)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when invalid SCORE address is provided, errors", %{
      identity: identity
    } do
      assert {
               :error,
               %Error{message: "address is invalid"}
             } = Request.Goloop.get_score_api(identity, "cx0")
    end

    test "when valid EOA address is provided, errors", %{
      identity: identity
    } do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert {
               :error,
               %Error{message: "address is invalid"}
             } = Request.Goloop.get_score_api(identity, address)
    end
  end

  describe "get_total_supply/1" do
    setup do
      identity = Identity.new()

      {:ok, identity: identity}
    end

    test "builds RPC call for icx_getTotalSupply", %{identity: identity} do
      assert {
               :ok,
               %Request{
                 method: "icx_getTotalSupply",
                 options: %{url: _},
                 params: %{}
               }
             } = Request.Goloop.get_total_supply(identity)
    end

    test "encodes it correctly", %{identity: identity} do
      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getTotalSupply"
             } =
               identity
               |> Request.Goloop.get_total_supply()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end
  end

  describe "get_transaction_result/2" do
    setup do
      identity = Identity.new()

      {:ok, identity: identity}
    end

    test "builds RPC call for icx_getTransactionResult", %{identity: identity} do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      assert {
               :ok,
               %Request{
                 method: "icx_getTransactionResult",
                 options: %{
                   url: _,
                   schema: %{txHash: {:hash, required: true}}
                 },
                 params: %{
                   txHash: ^tx_hash
                 }
               }
             } = Request.Goloop.get_transaction_result(identity, tx_hash)
    end

    test "builds RPC call for icx_waitTransactionResult", %{identity: identity} do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      assert {
               :ok,
               %Request{
                 method: "icx_waitTransactionResult",
                 options: %{
                   url: _,
                   schema: %{txHash: {:hash, required: true}},
                   timeout: 5_000
                 },
                 params: %{
                   txHash: ^tx_hash
                 }
               }
             } =
               Request.Goloop.get_transaction_result(
                 identity,
                 tx_hash,
                 timeout: 5_000
               )
    end

    test "encodes it correctly", %{identity: identity} do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getTransactionResult",
               "params" => %{
                 "txHash" => ^tx_hash
               }
             } =
               identity
               |> Request.Goloop.get_transaction_result(tx_hash)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when invalid hash is provided, errors", %{identity: identity} do
      assert {
               :error,
               %Error{message: "txHash is invalid"}
             } = Request.Goloop.get_transaction_result(identity, "0x0")
    end
  end

  describe "get_transaction_by_hash/2" do
    setup do
      identity = Identity.new()

      {:ok, identity: identity}
    end

    test "builds RPC call for icx_getTransactionByHash", %{identity: identity} do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      assert {
               :ok,
               %Request{
                 method: "icx_getTransactionByHash",
                 options: %{
                   url: _,
                   schema: %{txHash: {:hash, required: true}}
                 },
                 params: %{
                   txHash: ^tx_hash
                 }
               }
             } = Request.Goloop.get_transaction_by_hash(identity, tx_hash)
    end

    test "encodes it correctly", %{identity: identity} do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getTransactionByHash",
               "params" => %{
                 "txHash" => ^tx_hash
               }
             } =
               identity
               |> Request.Goloop.get_transaction_by_hash(tx_hash)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when invalid hash is provided, errors", %{identity: identity} do
      assert {
               :error,
               %Error{message: "txHash is invalid"}
             } = Request.Goloop.get_transaction_by_hash(identity, "0x0")
    end
  end

  describe "send_transaction/1 for coin transfers" do
    setup do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      {:ok, identity: identity}
    end

    test "builds RPC call for icx_sendTransaction", %{identity: identity} do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: datetime,
        nonce: 1
      }

      expected = %{
        version: 3,
        from: identity.address,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: datetime,
        nid: identity.network_id,
        nonce: 1
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 options: %{
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: {:loop, required: true},
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: 1}
                   }
                 },
                 params: ^expected
               }
             } = Request.Goloop.send_transaction(identity, params: params)
    end

    test "builds RPC call for icx_sendTransactionAndWait", %{identity: identity} do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: datetime,
        nonce: 1
      }

      expected = %{
        version: 3,
        from: identity.address,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: datetime,
        nid: identity.network_id,
        nonce: 1
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransactionAndWait",
                 options: %{
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: {:loop, required: true},
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: 1}
                   },
                   timeout: 5_000
                 },
                 params: ^expected
               }
             } =
               Request.Goloop.send_transaction(
                 identity,
                 params: params,
                 timeout: 5_000
               )
    end

    test "encodes it correctly", %{identity: identity} do
      from = identity.address

      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nonce: 1
      }

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransaction",
               "params" => %{
                 "version" => "0x3",
                 "from" => ^from,
                 "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "value" => "0x2a",
                 "stepLimit" => "0xa",
                 "timestamp" => 1_640_005_534_711_847,
                 "nid" => "0x1",
                 "nonce" => "0x1"
               }
             } =
               identity
               |> Request.Goloop.send_transaction(params: params)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when dataType is invalid, errors", %{identity: identity} do
      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nonce: 1,
        dataType: :invalid
      }

      assert {
               :error,
               %Error{message: "dataType is invalid"}
             } = Request.Goloop.send_transaction(identity, params: params)
    end

    test "when identity does not have an address, errors" do
      identity = Identity.new()

      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nonce: 1
      }

      assert {
               :error,
               %Error{message: "Invalid identity"}
             } = Request.Goloop.send_transaction(identity, params: params)
    end

    test "builds call when params are a keyword list", %{identity: identity} do
      datetime = DateTime.utc_now()

      params = [
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: datetime,
        nonce: 1
      ]

      expected = %{
        version: 3,
        from: identity.address,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: datetime,
        nonce: 1,
        nid: identity.network_id
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 options: %{
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: {:loop, required: true},
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: 1}
                   }
                 },
                 params: ^expected
               }
             } = Request.Goloop.send_transaction(identity, params: params)
    end
  end

  describe "send_transaction/1 for method calls" do
    setup do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      {:ok, identity: identity}
    end

    test "builds RPC call for icx_sendTransaction with params", %{
      identity: identity
    } do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nonce: 1,
        dataType: :call,
        data: %{
          method: "getBalance",
          params: %{
            address: "hxbe258ceb872e08851f1f59694dac2558708ece11"
          }
        }
      }

      expected = %{
        version: 3,
        from: identity.address,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nid: identity.network_id,
        nonce: 1,
        dataType: :call,
        data: %{
          method: "getBalance",
          params: %{
            address: "hxbe258ceb872e08851f1f59694dac2558708ece11"
          }
        }
      }

      call_schema = %{
        address: {:address, required: true}
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 options: %{
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     value: :loop,
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: 1},
                     dataType:
                       {{:enum, [:call]}, default: :call, required: true},
                     data: {
                       %{
                         method: {:string, required: true},
                         params: {
                           %{address: {:address, required: true}},
                           required: true
                         }
                       },
                       required: true
                     }
                   }
                 },
                 params: ^expected
               }
             } =
               Request.Goloop.send_transaction(
                 identity,
                 params: params,
                 schema: call_schema
               )
    end

    test "encodes it correctly with params", %{identity: identity} do
      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nonce: 1,
        dataType: :call,
        data: %{
          method: "getBalance",
          params: %{
            address: "hxbe258ceb872e08851f1f59694dac2558708ece11"
          }
        }
      }

      call_schema = %{
        address: {:address, required: true}
      }

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransaction",
               "params" => %{
                 "version" => "0x3",
                 "from" => "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
                 "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "stepLimit" => "0xa",
                 "timestamp" => 1_640_005_534_711_847,
                 "nid" => "0x1",
                 "nonce" => "0x1",
                 "dataType" => "call",
                 "data" => %{
                   "method" => "getBalance",
                   "params" => %{
                     "address" => "hxbe258ceb872e08851f1f59694dac2558708ece11"
                   }
                 }
               }
             } =
               identity
               |> Request.Goloop.send_transaction(
                 params: params,
                 schema: call_schema
               )
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "builds RPC call for icx_sendTransaction without params", %{
      identity: identity
    } do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nonce: 1,
        dataType: :call,
        data: %{
          method: "getBalance"
        }
      }

      expected = %{
        version: 3,
        from: identity.address,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nid: identity.network_id,
        nonce: 1,
        dataType: :call,
        data: %{
          method: "getBalance"
        }
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 options: %{
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     value: :loop,
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: 1},
                     dataType:
                       {{:enum, [:call]}, default: :call, required: true},
                     data: {
                       %{
                         method: {:string, required: true}
                       },
                       required: true
                     }
                   }
                 },
                 params: ^expected
               }
             } = Request.Goloop.send_transaction(identity, params: params)
    end

    test "encodes it correctly without params", %{identity: identity} do
      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nonce: 1,
        dataType: :call,
        data: %{
          method: "getBalance"
        }
      }

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransaction",
               "params" => %{
                 "version" => "0x3",
                 "from" => "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
                 "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "stepLimit" => "0xa",
                 "timestamp" => 1_640_005_534_711_847,
                 "nid" => "0x1",
                 "nonce" => "0x1",
                 "dataType" => "call",
                 "data" => %{
                   "method" => "getBalance"
                 }
               }
             } =
               identity
               |> Request.Goloop.send_transaction(params: params)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end
  end

  describe "send_transaction/1 for deploys" do
    setup do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      {:ok, identity: identity}
    end

    test "builds RPC call for icx_sendTransaction with params", %{
      identity: identity
    } do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nonce: 1,
        dataType: :deploy,
        data: %{
          contentType: "application/zip",
          content: "0x1867291283973610982301923812873419826abcdef9182731926312",
          params: %{
            address: "hxbe258ceb872e08851f1f59694dac2558708ece11"
          }
        }
      }

      expected = %{
        version: 3,
        from: identity.address,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nid: identity.network_id,
        nonce: 1,
        dataType: :deploy,
        data: %{
          contentType: "application/zip",
          content: "0x1867291283973610982301923812873419826abcdef9182731926312",
          params: %{
            address: "hxbe258ceb872e08851f1f59694dac2558708ece11"
          }
        }
      }

      deploy_schema = %{
        address: {:address, required: true}
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 options: %{
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     value: :loop,
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: 1},
                     dataType:
                       {{:enum, [:deploy]}, default: :deploy, required: true},
                     data: {
                       %{
                         contentType: {:string, required: true},
                         content: {:binary_data, required: true},
                         params: {
                           %{address: {:address, required: true}},
                           required: true
                         }
                       },
                       required: true
                     }
                   }
                 },
                 params: ^expected
               }
             } =
               Request.Goloop.send_transaction(
                 identity,
                 params: params,
                 schema: deploy_schema
               )
    end

    test "encodes it correctly with params", %{identity: identity} do
      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nonce: 1,
        dataType: :deploy,
        data: %{
          contentType: "application/zip",
          content: "0x1867291283973610982301923812873419826abcdef9182731926312",
          params: %{
            address: "hxbe258ceb872e08851f1f59694dac2558708ece11"
          }
        }
      }

      deploy_schema = %{
        address: {:address, required: true}
      }

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransaction",
               "params" => %{
                 "version" => "0x3",
                 "from" => "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
                 "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "stepLimit" => "0xa",
                 "timestamp" => 1_640_005_534_711_847,
                 "nid" => "0x1",
                 "nonce" => "0x1",
                 "dataType" => "deploy",
                 "data" => %{
                   "contentType" => "application/zip",
                   "content" =>
                     "0x1867291283973610982301923812873419826abcdef9182731926312",
                   "params" => %{
                     "address" => "hxbe258ceb872e08851f1f59694dac2558708ece11"
                   }
                 }
               }
             } =
               identity
               |> Request.Goloop.send_transaction(
                 params: params,
                 schema: deploy_schema
               )
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "builds RPC call for icx_sendTransaction without params", %{
      identity: identity
    } do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nonce: 1,
        dataType: :deploy,
        data: %{
          contentType: "application/zip",
          content: "0x1867291283973610982301923812873419826abcdef9182731926312"
        }
      }

      expected = %{
        version: 3,
        from: identity.address,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nid: identity.network_id,
        nonce: 1,
        dataType: :deploy,
        data: %{
          contentType: "application/zip",
          content: "0x1867291283973610982301923812873419826abcdef9182731926312"
        }
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 options: %{
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     value: :loop,
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: 1},
                     dataType:
                       {{:enum, [:deploy]}, default: :deploy, required: true},
                     data: {
                       %{
                         contentType: {:string, required: true},
                         content: {:binary_data, required: true}
                       },
                       required: true
                     }
                   }
                 },
                 params: ^expected
               }
             } = Request.Goloop.send_transaction(identity, params: params)
    end

    test "encodes it correctly without params", %{identity: identity} do
      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nonce: 1,
        dataType: :deploy,
        data: %{
          contentType: "application/zip",
          content: "0x1867291283973610982301923812873419826abcdef9182731926312"
        }
      }

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransaction",
               "params" => %{
                 "version" => "0x3",
                 "from" => "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
                 "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "stepLimit" => "0xa",
                 "timestamp" => 1_640_005_534_711_847,
                 "nid" => "0x1",
                 "nonce" => "0x1",
                 "dataType" => "deploy",
                 "data" => %{
                   "contentType" => "application/zip",
                   "content" =>
                     "0x1867291283973610982301923812873419826abcdef9182731926312"
                 }
               }
             } =
               identity
               |> Request.Goloop.send_transaction(params: params)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end
  end

  describe "send_transaction/1 for deposits" do
    setup do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      {:ok, identity: identity}
    end

    test "builds RPC for icx_sendTransaction (action=add)", %{
      identity: identity
    } do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: datetime,
        nonce: 1,
        dataType: :deposit,
        data: %{action: :add}
      }

      expected = %{
        version: 3,
        from: identity.address,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: datetime,
        nid: identity.network_id,
        nonce: 1,
        dataType: :deposit,
        data: %{action: :add}
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 options: %{
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: {:loop, required: true},
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: 1},
                     dataType:
                       {{:enum, [:deposit]}, default: :deposit, required: true},
                     data: {
                       %{
                         action:
                           {{:enum, [:add]}, default: :add, required: true}
                       },
                       required: true
                     }
                   }
                 },
                 params: ^expected
               }
             } = Request.Goloop.send_transaction(identity, params: params)
    end

    test "encodes it correctly (action=add)", %{identity: identity} do
      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nonce: 1,
        dataType: :deposit,
        data: %{action: :add}
      }

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransaction",
               "params" => %{
                 "version" => "0x3",
                 "from" => "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
                 "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "value" => "0x2a",
                 "stepLimit" => "0xa",
                 "timestamp" => 1_640_005_534_711_847,
                 "nid" => "0x1",
                 "nonce" => "0x1",
                 "dataType" => "deposit",
                 "data" => %{
                   "action" => "add"
                 }
               }
             } =
               identity
               |> Request.Goloop.send_transaction(params: params)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "builds RPC for icx_sendTransaction (action withdraw)", %{
      identity: identity
    } do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nonce: 1,
        dataType: :deposit,
        data: %{action: :withdraw}
      }

      expected = %{
        version: 3,
        from: identity.address,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nid: identity.network_id,
        nonce: 1,
        dataType: :deposit,
        data: %{action: :withdraw}
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 options: %{
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: :loop,
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: 1},
                     dataType:
                       {{:enum, [:deposit]}, default: :deposit, required: true},
                     data: {
                       %{
                         action:
                           {{:enum, [:withdraw]},
                            default: :withdraw, required: true},
                         id: :hash,
                         amount: :loop
                       },
                       required: true
                     }
                   }
                 },
                 params: ^expected
               }
             } = Request.Goloop.send_transaction(identity, params: params)
    end

    test "encodes it correctly (action=withdraw)", %{identity: identity} do
      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nonce: 1,
        dataType: :deposit,
        data: %{action: :withdraw}
      }

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransaction",
               "params" => %{
                 "version" => "0x3",
                 "from" => "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
                 "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "value" => "0x2a",
                 "stepLimit" => "0xa",
                 "timestamp" => 1_640_005_534_711_847,
                 "nid" => "0x1",
                 "nonce" => "0x1",
                 "dataType" => "deposit",
                 "data" => %{
                   "action" => "withdraw"
                 }
               }
             } =
               identity
               |> Request.Goloop.send_transaction(params: params)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when action is invalid, errors", %{identity: identity} do
      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nonce: 1,
        dataType: :deposit,
        data: %{action: "deposit"}
      }

      assert {
               :error,
               %Error{
                 code: -32_602,
                 reason: :invalid_params,
                 message: "data.action is invalid",
                 domain: :unknown
               }
             } = Request.Goloop.send_transaction(identity, params: params)
    end
  end

  describe "send_transaction/1 for messages" do
    setup do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      {:ok, identity: identity}
    end

    test "builds RPC for icx_sendTransaction", %{identity: identity} do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nonce: 1,
        dataType: :message,
        data: "0x2a"
      }

      expected = %{
        version: 3,
        from: identity.address,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nid: identity.network_id,
        nonce: 1,
        dataType: :message,
        data: "0x2a"
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 options: %{
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: :loop,
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: 1},
                     dataType:
                       {{:enum, [:message]}, default: :message, required: true},
                     data: {:binary_data, required: true}
                   }
                 },
                 params: ^expected
               }
             } = Request.Goloop.send_transaction(identity, params: params)
    end

    test "encodes it correctly (action=add)", %{identity: identity} do
      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nonce: 1,
        dataType: :message,
        data: "0x2a"
      }

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransaction",
               "params" => %{
                 "version" => "0x3",
                 "from" => "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
                 "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "stepLimit" => "0xa",
                 "timestamp" => 1_640_005_534_711_847,
                 "nid" => "0x1",
                 "nonce" => "0x1",
                 "dataType" => "message",
                 "data" => "0x2a"
               }
             } =
               identity
               |> Request.Goloop.send_transaction(params: params)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end
  end
end
