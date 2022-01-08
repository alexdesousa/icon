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

  describe "readonly_call/3, readonly_call/5" do
    setup do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      {:ok, identity: identity}
    end

    test "when a valid, builds RPC call without parameters for icx_call", %{
      identity: identity
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "getBalance"

      assert {
               :ok,
               %Request{
                 method: "icx_call",
                 params: %{
                   from: ^from,
                   to: ^to,
                   dataType: :call,
                   data: %{
                     method: "getBalance"
                   }
                 }
               }
             } = Request.Goloop.call(identity, to, method)
    end

    test "when the call doesn't have parameters, they're not present in the schema",
         %{
           identity: identity
         } do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "getBalance"

      assert {
               :ok,
               %Request{
                 method: "icx_call",
                 options: %{
                   schema:
                     %{
                       from: {:eoa_address, required: true},
                       to: {:score_address, required: true},
                       dataType: {{:enum, [:call]}, default: :call},
                       data: %{
                         method: {:string, required: true}
                       }
                     } = schema
                 }
               }
             } = Request.Goloop.call(identity, to, method)

      refute Map.has_key?(schema[:data], :params)
    end

    test "when a valid, builds RPC call with parameters for icx_call", %{
      identity: identity
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "getBalance"
      params = %{address: from}

      assert {
               :ok,
               %Request{
                 method: "icx_call",
                 params: %{
                   from: ^from,
                   to: ^to,
                   dataType: :call,
                   data: %{
                     method: "getBalance",
                     params: %{
                       address: ^from
                     }
                   }
                 }
               }
             } =
               Request.Goloop.call(identity, to, method, params,
                 schema: %{address: {:address, required: true}}
               )
    end

    test "when the call has parameters, they're present in the schema", %{
      identity: identity
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "getBalance"
      params = %{address: from}

      assert {
               :ok,
               %Request{
                 method: "icx_call",
                 options: %{
                   schema: %{
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     dataType: {{:enum, [:call]}, default: :call},
                     data: %{
                       method: {:string, required: true},
                       params: {
                         %{address: {:address, required: true}},
                         required: true
                       }
                     }
                   }
                 }
               }
             } =
               Request.Goloop.call(identity, to, method, params,
                 schema: %{address: {:address, required: true}}
               )
    end

    test "when params schema is empty, ignores parameters", %{
      identity: identity
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "getBalance"
      params = %{address: from}

      assert {
               :ok,
               %Request{
                 method: "icx_call",
                 params: %{
                   from: ^from,
                   to: ^to,
                   dataType: :call,
                   data: %{
                     method: "getBalance"
                   }
                 }
               }
             } = Request.Goloop.call(identity, to, method, params)
    end

    test "encodes it correctly", %{identity: identity} do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "getBalance"
      params = %{address: from}
      options = [schema: %{address: {:address, required: true}}]

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
               |> Request.Goloop.call(to, method, params, options)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when SCORE address is invalid, errors", %{identity: identity} do
      from = identity.address
      to = "cx0"
      method = "getBalance"
      params = %{address: from}

      assert {
               :error,
               %Error{message: "to is invalid"}
             } =
               Request.Goloop.call(identity, to, method, params,
                 schema: %{address: {:address, required: true}}
               )
    end

    test "when params are invalid, errors", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "getBalance"
      params = %{address: "hx0"}

      assert {
               :error,
               %Error{message: "data.params.address is invalid"}
             } =
               Request.Goloop.call(identity, to, method, params,
                 schema: %{address: {:address, required: true}}
               )
    end

    test "when identity doesn't have a wallet, errors" do
      identity = Identity.new()
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "getBalance"

      assert {
               :error,
               %Error{message: "identity must have a wallet"}
             } = Request.Goloop.call(identity, to, method)
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

  describe "transfer/3 with or without options" do
    setup do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      {:ok, identity: identity}
    end

    test "builds RPC call for icx_sendTransaction", %{identity: identity} do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 42

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 params: %{
                   from: ^from,
                   to: ^to,
                   value: ^value,
                   version: 3,
                   nid: 1,
                   timestamp: _,
                   nonce: _
                 }
               }
             } = Request.Goloop.transfer(identity, to, value)
    end

    test "encodes icx_sendTransaction correctly", %{identity: identity} do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 42

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransaction",
               "params" => %{
                 "version" => "0x3",
                 "from" => ^from,
                 "to" => ^to,
                 "value" => "0x2a",
                 "timestamp" => "0x" <> _timestamp,
                 "nid" => "0x1",
                 "nonce" => "0x" <> _nonce
               }
             } =
               identity
               |> Request.Goloop.transfer(to, value)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "builds RPC call for icx_sendTransactionAndWait when there's timeout",
         %{
           identity: identity
         } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 42
      timeout = 5_000

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransactionAndWait",
                 options: %{
                   timeout: ^timeout
                 },
                 params: %{
                   from: ^from,
                   to: ^to,
                   value: ^value,
                   version: 3,
                   nid: 1,
                   timestamp: _,
                   nonce: _
                 }
               }
             } = Request.Goloop.transfer(identity, to, value, timeout: timeout)
    end

    test "encodes icx_sendTransactionAndWait correctly", %{identity: identity} do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 42
      timeout = 5_000

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransactionAndWait",
               "params" => %{
                 "version" => "0x3",
                 "from" => ^from,
                 "to" => ^to,
                 "value" => "0x2a",
                 "timestamp" => "0x" <> _timestamp,
                 "nid" => "0x1",
                 "nonce" => "0x" <> _nonce
               }
             } =
               identity
               |> Request.Goloop.transfer(to, value, timeout: timeout)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "adds identity", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 42

      assert {:ok, %Request{options: %{identity: ^identity}}} =
               Request.Goloop.transfer(identity, to, value)
    end

    test "adds schema to the request", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 42

      assert {
               :ok,
               %Request{
                 options: %{
                   schema: %{
                     version: {:integer, required: true, default: 3},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: {:loop, required: true},
                     stepLimit: :integer,
                     timestamp: {:timestamp, required: true, default: _},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: _}
                   }
                 }
               }
             } = Request.Goloop.transfer(identity, to, value)
    end

    test "overrides any parameter in the request", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 42
      options = [params: %{version: 4}]

      assert {:ok, %Request{params: %{version: 4}}} =
               Request.Goloop.transfer(identity, to, value, options)
    end

    test "when params are invalid, errors", %{identity: identity} do
      assert {
               :error,
               %Error{message: "to is invalid"}
             } = Request.Goloop.transfer(identity, "cx0", 42)
    end

    test "when identity doesn't have a wallet, errors" do
      identity = Identity.new()
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 42

      assert {
               :error,
               %Error{message: "identity must have a wallet"}
             } = Request.Goloop.transfer(identity, to, value)
    end
  end

  describe "send_message/3 with or without options" do
    setup do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      {:ok, identity: identity}
    end

    test "builds RPC call for icx_sendTransaction", %{identity: identity} do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      message = "ICON 2.0"

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 params: %{
                   from: ^from,
                   to: ^to,
                   version: 3,
                   nid: 1,
                   timestamp: _,
                   nonce: _,
                   dataType: :message,
                   data: ^message
                 }
               }
             } = Request.Goloop.send_message(identity, to, message)
    end

    test "encodes icx_sendTransaction correctly", %{identity: identity} do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      message = "ICON 2.0"

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransaction",
               "params" => %{
                 "version" => "0x3",
                 "from" => ^from,
                 "to" => ^to,
                 "timestamp" => "0x" <> _timestamp,
                 "nid" => "0x1",
                 "nonce" => "0x" <> _nonce,
                 "dataType" => "message",
                 "data" => "0x49434f4e20322e30"
               }
             } =
               identity
               |> Request.Goloop.send_message(to, message)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "builds RPC call for icx_sendTransactionAndWait when there's timeout",
         %{
           identity: identity
         } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      message = "ICON 2.0"
      timeout = 5_000

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransactionAndWait",
                 options: %{
                   timeout: ^timeout
                 },
                 params: %{
                   from: ^from,
                   to: ^to,
                   version: 3,
                   nid: 1,
                   timestamp: _,
                   nonce: _,
                   dataType: :message,
                   data: ^message
                 }
               }
             } =
               Request.Goloop.send_message(identity, to, message,
                 timeout: timeout
               )
    end

    test "encodes icx_sendTransactionAndWait correctly", %{identity: identity} do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      message = "ICON 2.0"
      timeout = 5_000

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransactionAndWait",
               "params" => %{
                 "version" => "0x3",
                 "from" => ^from,
                 "to" => ^to,
                 "timestamp" => "0x" <> _timestamp,
                 "nid" => "0x1",
                 "nonce" => "0x" <> _nonce,
                 "dataType" => "message",
                 "data" => "0x49434f4e20322e30"
               }
             } =
               identity
               |> Request.Goloop.send_message(to, message, timeout: timeout)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "adds identity", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      message = "ICON 2.0"

      assert {:ok, %Request{options: %{identity: ^identity}}} =
               Request.Goloop.send_message(identity, to, message)
    end

    test "adds schema to the request", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      message = "ICON 2.0"

      assert {
               :ok,
               %Request{
                 options: %{
                   schema: %{
                     version: {:integer, required: true, default: 3},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     stepLimit: :integer,
                     timestamp: {:timestamp, required: true, default: _},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: _},
                     dataType: {{:enum, [:message]}, default: :message},
                     data: {:binary_data, required: true}
                   }
                 }
               }
             } = Request.Goloop.send_message(identity, to, message)
    end

    test "overrides any parameter in the request", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      message = "ICON 2.0"
      options = [params: %{version: 4}]

      assert {:ok, %Request{params: %{version: 4}}} =
               Request.Goloop.send_message(identity, to, message, options)
    end

    test "when params are invalid, errors", %{identity: identity} do
      assert {
               :error,
               %Error{message: "to is invalid"}
             } = Request.Goloop.send_message(identity, "cx0", "ICON 2.0")
    end

    test "when identity doesn't have a wallet, errors" do
      identity = Identity.new()
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      message = "ICON 2.0"

      assert {
               :error,
               %Error{message: "identity must have a wallet"}
             } = Request.Goloop.send_message(identity, to, message)
    end
  end

  describe "transaction_call/3 with or without options" do
    setup do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      {:ok, identity: identity}
    end

    test "builds RPC call for icx_sendTransaction", %{identity: identity} do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "transfer"

      params = %{
        address: "hx2e243ad926ac48d15156756fce28314357d49d83",
        value: 1_000_000_000_000_000_000
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 params: %{
                   from: ^from,
                   to: ^to,
                   version: 3,
                   nid: 1,
                   timestamp: _,
                   nonce: _,
                   dataType: :call,
                   data: %{
                     method: ^method,
                     params: ^params
                   }
                 }
               }
             } =
               Request.Goloop.transaction_call(identity, to, method, params,
                 schema: %{
                   address: {:address, required: true},
                   value: {:loop, required: true}
                 }
               )
    end

    test "encodes icx_sendTransaction correctly", %{identity: identity} do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "transfer"

      params = %{
        address: "hx2e243ad926ac48d15156756fce28314357d49d83",
        value: 1_000_000_000_000_000_000
      }

      options = [
        schema: %{
          address: {:address, required: true},
          value: {:loop, required: true}
        }
      ]

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransaction",
               "params" => %{
                 "version" => "0x3",
                 "from" => ^from,
                 "to" => ^to,
                 "timestamp" => "0x" <> _timestamp,
                 "nid" => "0x1",
                 "nonce" => "0x" <> _nonce,
                 "dataType" => "call",
                 "data" => %{
                   "method" => ^method,
                   "params" => %{
                     "address" => "hx2e243ad926ac48d15156756fce28314357d49d83",
                     "value" => "0xde0b6b3a7640000"
                   }
                 }
               }
             } =
               identity
               |> Request.Goloop.transaction_call(to, method, params, options)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "encodes icx_sendTransaction without parameters correctly", %{
      identity: identity
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "delete"

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransaction",
               "params" => %{
                 "version" => "0x3",
                 "from" => ^from,
                 "to" => ^to,
                 "timestamp" => "0x" <> _timestamp,
                 "nid" => "0x1",
                 "nonce" => "0x" <> _nonce,
                 "dataType" => "call",
                 "data" => %{
                   "method" => ^method
                 }
               }
             } =
               identity
               |> Request.Goloop.transaction_call(to, method)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "builds RPC call for icx_sendTransactionAndWait when there's timeout",
         %{
           identity: identity
         } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "transfer"

      params = %{
        address: "hx2e243ad926ac48d15156756fce28314357d49d83",
        value: 1_000_000_000_000_000_000
      }

      timeout = 5_000

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransactionAndWait",
                 options: %{
                   timeout: ^timeout
                 },
                 params: %{
                   from: ^from,
                   to: ^to,
                   version: 3,
                   nid: 1,
                   timestamp: _,
                   nonce: _,
                   dataType: :call,
                   data: %{
                     method: ^method,
                     params: ^params
                   }
                 }
               }
             } =
               Request.Goloop.transaction_call(identity, to, method, params,
                 schema: %{
                   address: {:address, required: true},
                   value: {:loop, required: true}
                 },
                 timeout: timeout
               )
    end

    test "encodes icx_sendTransactionAndWait correctly", %{identity: identity} do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "transfer"

      params = %{
        address: "hx2e243ad926ac48d15156756fce28314357d49d83",
        value: 1_000_000_000_000_000_000
      }

      options = [
        schema: %{
          address: {:address, required: true},
          value: {:loop, required: true}
        },
        timeout: 5_000
      ]

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransactionAndWait",
               "params" => %{
                 "version" => "0x3",
                 "from" => ^from,
                 "to" => ^to,
                 "timestamp" => "0x" <> _timestamp,
                 "nid" => "0x1",
                 "nonce" => "0x" <> _nonce,
                 "dataType" => "call",
                 "data" => %{
                   "method" => ^method,
                   "params" => %{
                     "address" => "hx2e243ad926ac48d15156756fce28314357d49d83",
                     "value" => "0xde0b6b3a7640000"
                   }
                 }
               }
             } =
               identity
               |> Request.Goloop.transaction_call(to, method, params, options)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "adds identity", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "transfer"

      params = %{
        address: "hx2e243ad926ac48d15156756fce28314357d49d83",
        value: 1_000_000_000_000_000_000
      }

      assert {:ok, %Request{options: %{identity: ^identity}}} =
               Request.Goloop.transaction_call(identity, to, method, params,
                 schema: %{
                   address: {:address, required: true},
                   value: {:loop, required: true}
                 }
               )
    end

    test "adds schema without parameters to the request", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "delete"

      assert {
               :ok,
               %Request{
                 options: %{
                   schema:
                     %{
                       version: {:integer, required: true, default: 3},
                       from: {:eoa_address, required: true},
                       to: {:score_address, required: true},
                       stepLimit: :integer,
                       timestamp: {:timestamp, required: true, default: _},
                       nid: {:integer, required: true},
                       nonce: {:integer, default: _},
                       dataType: {{:enum, [:call]}, default: :call},
                       data: %{
                         method: {:string, required: true}
                       }
                     } = schema
                 }
               }
             } = Request.Goloop.transaction_call(identity, to, method)

      refute Map.has_key?(schema[:data], :params)
    end

    test "adds schema with parameters to the request", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "transfer"

      params = %{
        address: "hx2e243ad926ac48d15156756fce28314357d49d83",
        value: 1_000_000_000_000_000_000
      }

      assert {
               :ok,
               %Request{
                 options: %{
                   schema: %{
                     version: {:integer, required: true, default: 3},
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     stepLimit: :integer,
                     timestamp: {:timestamp, required: true, default: _},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: _},
                     dataType: {{:enum, [:call]}, default: :call},
                     data: %{
                       method: {:string, required: true},
                       params: {
                         %{
                           address: {:address, required: true},
                           value: {:loop, required: true}
                         },
                         required: true
                       }
                     }
                   }
                 }
               }
             } =
               Request.Goloop.transaction_call(identity, to, method, params,
                 schema: %{
                   address: {:address, required: true},
                   value: {:loop, required: true}
                 }
               )
    end

    test "overrides any parameter in the request", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "delete"

      assert {:ok, %Request{params: %{version: 4}}} =
               Request.Goloop.transaction_call(identity, to, method, nil,
                 params: %{version: 4}
               )
    end

    test "when params are invalid, errors", %{identity: identity} do
      assert {
               :error,
               %Error{message: "to is invalid"}
             } = Request.Goloop.transaction_call(identity, "cx0", "delete")
    end

    test "when identity doesn't have a wallet, errors" do
      identity = Identity.new()
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "delete"

      assert {
               :error,
               %Error{message: "identity must have a wallet"}
             } = Request.Goloop.transaction_call(identity, to, method)
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
      datetime = DateTime.from_unix!(1_640_948_137_125_360, :microsecond)

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
                     version: {:integer, required: true, default: 3},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: {:loop, required: true},
                     stepLimit: :integer,
                     timestamp: {:timestamp, required: true, default: _},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: _}
                   }
                 },
                 params: ^expected
               }
             } = Request.Goloop.send_transaction(identity, params: params)
    end

    test "builds RPC call for icx_sendTransactionAndWait", %{identity: identity} do
      datetime = DateTime.from_unix!(1_640_948_137_125_360, :microsecond)

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
                     version: {:integer, required: true, default: 3},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: {:loop, required: true},
                     stepLimit: :integer,
                     timestamp: {:timestamp, required: true, default: _},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: _}
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
                 "timestamp" => "0x5d3938b538027",
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

    test "signs it correctly", %{identity: identity} do
      datetime = DateTime.from_unix!(1_640_948_137_125_360, :microsecond)

      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: datetime,
        nonce: 1
      }

      assert {:ok, %Request{} = request} =
               Request.Goloop.send_transaction(identity, params: params)

      assert {:ok, %Request{} = request} = Request.sign(request)
      assert Request.verify(request)
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
      datetime = DateTime.from_unix!(1_640_948_137_125_360, :microsecond)

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
                     version: {:integer, required: true, default: 3},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: {:loop, required: true},
                     stepLimit: :integer,
                     timestamp: {:timestamp, required: true, default: _},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: _}
                   }
                 },
                 params: ^expected
               }
             } = Request.Goloop.send_transaction(identity, params: params)
    end
  end

  describe "send_transaction/2 with no step limit" do
    setup do
      bypass = Bypass.open()

      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity =
        Identity.new(
          private_key: private_key,
          node: "http://localhost:#{bypass.port}"
        )

      {:ok, bypass: bypass, identity: identity}
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
      datetime = DateTime.from_unix!(1_640_948_137_125_360, :microsecond)

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
                     version: {:integer, required: true, default: 3},
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     value: :loop,
                     stepLimit: :integer,
                     timestamp: {:timestamp, required: true, default: _},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: _},
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
                 "timestamp" => "0x5d3938b538027",
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
      datetime = DateTime.from_unix!(1_640_948_137_125_360, :microsecond)

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
                     version: {:integer, required: true, default: 3},
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     value: :loop,
                     stepLimit: :integer,
                     timestamp: {:timestamp, required: true, default: _},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: _},
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
                 "timestamp" => "0x5d3938b538027",
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
      datetime = DateTime.from_unix!(1_640_948_137_125_360, :microsecond)

      {:ok, {_, zip_contents}} =
        :zip.create('test', [{'file.txt', "ICON 2.0"}], [:memory])

      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nonce: 1,
        dataType: :deploy,
        data: %{
          contentType: "application/zip",
          content: zip_contents,
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
          content: zip_contents,
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
                     version: {:integer, required: true, default: 3},
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     value: :loop,
                     stepLimit: :integer,
                     timestamp: {:timestamp, required: true, default: _},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: _},
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
                 "timestamp" => "0x5d3938b538027",
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
      datetime = DateTime.from_unix!(1_640_948_137_125_360, :microsecond)

      {:ok, {_, zip_contents}} =
        :zip.create('test', [{'file.txt', "ICON 2.0"}], [:memory])

      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nonce: 1,
        dataType: :deploy,
        data: %{
          contentType: "application/zip",
          content: zip_contents
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
          content: zip_contents
        }
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 options: %{
                   url: _,
                   schema: %{
                     version: {:integer, required: true, default: 3},
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     value: :loop,
                     stepLimit: :integer,
                     timestamp: {:timestamp, required: true, default: _},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: _},
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
                 "timestamp" => "0x5d3938b538027",
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
      datetime = DateTime.from_unix!(1_640_948_137_125_360, :microsecond)

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
                     version: {:integer, required: true, default: 3},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: {:loop, required: true},
                     stepLimit: :integer,
                     timestamp: {:timestamp, required: true, default: _},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: _},
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
                 "timestamp" => "0x5d3938b538027",
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
      datetime = DateTime.from_unix!(1_640_948_137_125_360, :microsecond)

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
                     version: {:integer, required: true, default: 3},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: :loop,
                     stepLimit: :integer,
                     timestamp: {:timestamp, required: true, default: _},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: _},
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
                 "timestamp" => "0x5d3938b538027",
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
      datetime = DateTime.from_unix!(1_640_948_137_125_360, :microsecond)

      params = %{
        version: 3,
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nonce: 1,
        dataType: :message,
        data: "ICON 2.0"
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
        data: "ICON 2.0"
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 options: %{
                   url: _,
                   schema: %{
                     version: {:integer, required: true, default: 3},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: :loop,
                     stepLimit: :integer,
                     timestamp: {:timestamp, required: true, default: _},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: _},
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
                 "timestamp" => "0x5d3938b538027",
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
