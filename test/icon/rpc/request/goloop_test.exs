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
                   schema: %{height: {:non_neg_integer, required: true}}
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

  describe "call/3, call/5" do
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

    test "when params schema is empty, loads the parameters without conversion",
         %{
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

    test "encodes it correctly without schema", %{identity: identity} do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "getBalance"
      params = %{address: from}

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
               |> Request.Goloop.call(to, method, params)
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

    test "encodes icx_sendTransaction without schema correctly", %{
      identity: identity
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "transfer"

      params = %{
        address: "hx2e243ad926ac48d15156756fce28314357d49d83",
        value: "0xde0b6b3a7640000"
      }

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
               |> Request.Goloop.transaction_call(to, method, params)
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

    test "encodes icx_sendTransactionAndWait without schema correctly", %{
      identity: identity
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      method = "transfer"

      params = %{
        address: "hx2e243ad926ac48d15156756fce28314357d49d83",
        value: "0xde0b6b3a7640000"
      }

      options = [timeout: 5_000]

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
                       data: {
                         %{
                           method: {:string, required: true}
                         },
                         required: true
                       }
                     } = schema
                 }
               }
             } = Request.Goloop.transaction_call(identity, to, method)

      refute Map.has_key?(elem(schema[:data], 0), :params)
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
                     data:
                       {%{
                          method: {:string, required: true},
                          params: {
                            %{
                              address: {:address, required: true},
                              value: {:loop, required: true}
                            },
                            required: true
                          }
                        }, required: true}
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

  describe "install_score/2 with or without options" do
    setup do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      unique_id = '#{:erlang.phash2(make_ref())}'

      {:ok, {_, content}} =
        :zip.create(unique_id, [{'file.txt', "ICON 2.0"}], [:memory])

      {:ok, identity: identity, content: content}
    end

    test "builds RPC call for icx_sendTransaction", %{
      identity: identity,
      content: content
    } do
      from = identity.address

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 params: %{
                   from: ^from,
                   to: "cx0000000000000000000000000000000000000000",
                   version: 3,
                   nid: 1,
                   timestamp: _,
                   nonce: _,
                   dataType: :deploy,
                   data: %{
                     contentType: "application/zip",
                     content: ^content
                   }
                 }
               }
             } = Request.Goloop.install_score(identity, content)
    end

    test "encodes icx_sendTransaction correctly", %{
      identity: identity,
      content: content
    } do
      from = identity.address

      options = [
        on_install_params: %{
          address: "hx2e243ad926ac48d15156756fce28314357d49d83"
        },
        on_install_schema: %{
          address: {:address, required: true}
        }
      ]

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransaction",
               "params" => %{
                 "version" => "0x3",
                 "from" => ^from,
                 "to" => "cx0000000000000000000000000000000000000000",
                 "timestamp" => "0x" <> _timestamp,
                 "nid" => "0x1",
                 "nonce" => "0x" <> _nonce,
                 "dataType" => "deploy",
                 "data" => %{
                   "contentType" => "application/zip",
                   "content" => "0x" <> _content,
                   "params" => %{
                     "address" => "hx2e243ad926ac48d15156756fce28314357d49d83"
                   }
                 }
               }
             } =
               identity
               |> Request.Goloop.install_score(content, options)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "encodes icx_sendTransaction without parameters correctly", %{
      identity: identity,
      content: content
    } do
      from = identity.address

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransaction",
               "params" => %{
                 "version" => "0x3",
                 "from" => ^from,
                 "to" => "cx0000000000000000000000000000000000000000",
                 "timestamp" => "0x" <> _timestamp,
                 "nid" => "0x1",
                 "nonce" => "0x" <> _nonce,
                 "dataType" => "deploy",
                 "data" =>
                   %{
                     "contentType" => "application/zip",
                     "content" => "0x" <> _content
                   } = data
               }
             } =
               identity
               |> Request.Goloop.install_score(content)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()

      refute Map.has_key?(data, "params")
    end

    test "builds RPC call for icx_sendTransactionAndWait", %{
      identity: identity,
      content: content
    } do
      from = identity.address
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
                   to: "cx0000000000000000000000000000000000000000",
                   version: 3,
                   nid: 1,
                   timestamp: _,
                   nonce: _,
                   dataType: :deploy,
                   data: %{
                     contentType: "application/zip",
                     content: ^content
                   }
                 }
               }
             } =
               Request.Goloop.install_score(identity, content, timeout: timeout)
    end

    test "encodes icx_sendTransactionAndWait correctly", %{
      identity: identity,
      content: content
    } do
      from = identity.address

      options = [
        timeout: 5_000,
        on_install_params: %{
          address: "hx2e243ad926ac48d15156756fce28314357d49d83"
        },
        on_install_schema: %{
          address: {:address, required: true}
        }
      ]

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransactionAndWait",
               "params" => %{
                 "version" => "0x3",
                 "from" => ^from,
                 "to" => "cx0000000000000000000000000000000000000000",
                 "timestamp" => "0x" <> _timestamp,
                 "nid" => "0x1",
                 "nonce" => "0x" <> _nonce,
                 "dataType" => "deploy",
                 "data" => %{
                   "contentType" => "application/zip",
                   "content" => "0x" <> _content,
                   "params" => %{
                     "address" => "hx2e243ad926ac48d15156756fce28314357d49d83"
                   }
                 }
               }
             } =
               identity
               |> Request.Goloop.install_score(content, options)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "encodes icx_sendTransactionAndWait without parameters correctly", %{
      identity: identity,
      content: content
    } do
      from = identity.address

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransactionAndWait",
               "params" => %{
                 "version" => "0x3",
                 "from" => ^from,
                 "to" => "cx0000000000000000000000000000000000000000",
                 "timestamp" => "0x" <> _timestamp,
                 "nid" => "0x1",
                 "nonce" => "0x" <> _nonce,
                 "dataType" => "deploy",
                 "data" =>
                   %{
                     "contentType" => "application/zip",
                     "content" => "0x" <> _content
                   } = data
               }
             } =
               identity
               |> Request.Goloop.install_score(content, timeout: 5_000)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()

      refute Map.has_key?(data, "params")
    end

    test "adds identity", %{identity: identity, content: content} do
      assert {:ok, %Request{options: %{identity: ^identity}}} =
               Request.Goloop.install_score(identity, content)
    end

    test "adds schema without parameters to the request", %{
      identity: identity,
      content: content
    } do
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
                       dataType: {{:enum, [:deploy]}, default: :deploy},
                       data:
                         {%{
                            contentType: {:string, required: true},
                            content: {:binary_data, required: true}
                          }, required: true}
                     } = schema
                 }
               }
             } = Request.Goloop.install_score(identity, content)

      refute Map.has_key?(elem(schema[:data], 0), :params)
    end

    test "adds schema with parameters to the request", %{
      identity: identity,
      content: content
    } do
      options = [
        on_install_params: %{
          address: "hx2e243ad926ac48d15156756fce28314357d49d83"
        },
        on_install_schema: %{
          address: {:address, required: true}
        }
      ]

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
                     dataType: {{:enum, [:deploy]}, default: :deploy},
                     data:
                       {%{
                          contentType: {:string, required: true},
                          content: {:binary_data, required: true},
                          params: {
                            %{
                              address: {:address, required: true}
                            },
                            required: true
                          }
                        }, required: true}
                   }
                 }
               }
             } = Request.Goloop.install_score(identity, content, options)
    end

    test "overrides any parameter in the request", %{
      identity: identity,
      content: content
    } do
      assert {:ok, %Request{params: %{version: 4}}} =
               Request.Goloop.install_score(identity, content,
                 params: %{version: 4}
               )
    end

    test "when params are invalid, errors", %{identity: identity} do
      assert {
               :error,
               %Error{message: "data.content is required"}
             } = Request.Goloop.install_score(identity, nil)
    end

    test "when identity doesn't have a wallet, errors", %{content: content} do
      identity = Identity.new()

      assert {
               :error,
               %Error{message: "identity must have a wallet"}
             } = Request.Goloop.install_score(identity, content)
    end
  end

  describe "update_score/3 with or without options" do
    setup do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      unique_id = '#{:erlang.phash2(make_ref())}'

      {:ok, {_, content}} =
        :zip.create(unique_id, [{'file.txt', "ICON 2.0"}], [:memory])

      {:ok, identity: identity, content: content}
    end

    test "builds RPC call for icx_sendTransaction", %{
      identity: identity,
      content: content
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

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
                   dataType: :deploy,
                   data: %{
                     contentType: "application/zip",
                     content: ^content
                   }
                 }
               }
             } = Request.Goloop.update_score(identity, to, content)
    end

    test "encodes icx_sendTransaction correctly", %{
      identity: identity,
      content: content
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      options = [
        on_update_params: %{
          address: "hx2e243ad926ac48d15156756fce28314357d49d83"
        },
        on_update_schema: %{
          address: {:address, required: true}
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
                 "dataType" => "deploy",
                 "data" => %{
                   "contentType" => "application/zip",
                   "content" => "0x" <> _content,
                   "params" => %{
                     "address" => "hx2e243ad926ac48d15156756fce28314357d49d83"
                   }
                 }
               }
             } =
               identity
               |> Request.Goloop.update_score(to, content, options)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "encodes icx_sendTransaction without parameters correctly", %{
      identity: identity,
      content: content
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

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
                 "dataType" => "deploy",
                 "data" =>
                   %{
                     "contentType" => "application/zip",
                     "content" => "0x" <> _content
                   } = data
               }
             } =
               identity
               |> Request.Goloop.update_score(to, content)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()

      refute Map.has_key?(data, "params")
    end

    test "builds RPC call for icx_sendTransactionAndWait", %{
      identity: identity,
      content: content
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
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
                   dataType: :deploy,
                   data: %{
                     contentType: "application/zip",
                     content: ^content
                   }
                 }
               }
             } =
               Request.Goloop.update_score(identity, to, content,
                 timeout: timeout
               )
    end

    test "encodes icx_sendTransactionAndWait correctly", %{
      identity: identity,
      content: content
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      options = [
        timeout: 5_000,
        on_update_params: %{
          address: "hx2e243ad926ac48d15156756fce28314357d49d83"
        },
        on_update_schema: %{
          address: {:address, required: true}
        }
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
                 "dataType" => "deploy",
                 "data" => %{
                   "contentType" => "application/zip",
                   "content" => "0x" <> _content,
                   "params" => %{
                     "address" => "hx2e243ad926ac48d15156756fce28314357d49d83"
                   }
                 }
               }
             } =
               identity
               |> Request.Goloop.update_score(to, content, options)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "encodes icx_sendTransactionAndWait without parameters correctly", %{
      identity: identity,
      content: content
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

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
                 "dataType" => "deploy",
                 "data" =>
                   %{
                     "contentType" => "application/zip",
                     "content" => "0x" <> _content
                   } = data
               }
             } =
               identity
               |> Request.Goloop.update_score(to, content, timeout: 5_000)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()

      refute Map.has_key?(data, "params")
    end

    test "adds identity", %{identity: identity, content: content} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {:ok, %Request{options: %{identity: ^identity}}} =
               Request.Goloop.update_score(identity, to, content)
    end

    test "adds schema without parameters to the request", %{
      identity: identity,
      content: content
    } do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

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
                       dataType: {{:enum, [:deploy]}, default: :deploy},
                       data: {
                         %{
                           contentType: {:string, required: true},
                           content: {:binary_data, required: true}
                         },
                         required: true
                       }
                     } = schema
                 }
               }
             } = Request.Goloop.update_score(identity, to, content)

      refute Map.has_key?(elem(schema[:data], 0), :params)
    end

    test "adds schema with parameters to the request", %{
      identity: identity,
      content: content
    } do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      options = [
        on_update_params: %{
          address: "hx2e243ad926ac48d15156756fce28314357d49d83"
        },
        on_update_schema: %{
          address: {:address, required: true}
        }
      ]

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
                     dataType: {{:enum, [:deploy]}, default: :deploy},
                     data:
                       {%{
                          contentType: {:string, required: true},
                          content: {:binary_data, required: true},
                          params: {
                            %{
                              address: {:address, required: true}
                            },
                            required: true
                          }
                        }, required: true}
                   }
                 }
               }
             } = Request.Goloop.update_score(identity, to, content, options)
    end

    test "overrides any parameter in the request", %{
      identity: identity,
      content: content
    } do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {:ok, %Request{params: %{version: 4}}} =
               Request.Goloop.update_score(identity, to, content,
                 params: %{version: 4}
               )
    end

    test "when params are invalid, errors", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {
               :error,
               %Error{message: "data.content is required"}
             } = Request.Goloop.update_score(identity, to, nil)
    end

    test "when identity doesn't have a wallet, errors", %{content: content} do
      identity = Identity.new()
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {
               :error,
               %Error{message: "identity must have a wallet"}
             } = Request.Goloop.update_score(identity, to, content)
    end
  end

  describe "deposit_shared_fee/3 with or without options" do
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
                   nonce: _,
                   dataType: :deposit,
                   data: %{
                     action: :add
                   }
                 }
               }
             } = Request.Goloop.deposit_shared_fee(identity, to, value)
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
                 "nonce" => "0x" <> _nonce,
                 "dataType" => "deposit",
                 "data" => %{
                   "action" => "add"
                 }
               }
             } =
               identity
               |> Request.Goloop.deposit_shared_fee(to, value)
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
                   nonce: _,
                   dataType: :deposit,
                   data: %{
                     action: :add
                   }
                 }
               }
             } =
               Request.Goloop.deposit_shared_fee(identity, to, value,
                 timeout: timeout
               )
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
                 "nonce" => "0x" <> _nonce,
                 "dataType" => "deposit",
                 "data" => %{
                   "action" => "add"
                 }
               }
             } =
               identity
               |> Request.Goloop.deposit_shared_fee(to, value, timeout: timeout)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "adds identity", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 42

      assert {:ok, %Request{options: %{identity: ^identity}}} =
               Request.Goloop.deposit_shared_fee(identity, to, value)
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
                     to: {:score_address, required: true},
                     value: {:loop, required: true},
                     stepLimit: :integer,
                     timestamp: {:timestamp, required: true, default: _},
                     nid: {:integer, required: true},
                     nonce: {:integer, default: _},
                     dataType: {{:enum, [:deposit]}, default: :deposit},
                     data: {
                       %{action: {{:enum, [:add]}, default: :add}},
                       default: %{action: "add"}
                     }
                   }
                 }
               }
             } = Request.Goloop.deposit_shared_fee(identity, to, value)
    end

    test "overrides any parameter in the request", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 42
      options = [params: %{version: 4}]

      assert {:ok, %Request{params: %{version: 4}}} =
               Request.Goloop.deposit_shared_fee(identity, to, value, options)
    end

    test "when params are invalid, errors", %{identity: identity} do
      assert {
               :error,
               %Error{message: "to is invalid"}
             } = Request.Goloop.deposit_shared_fee(identity, "cx0", 42)
    end

    test "when identity doesn't have a wallet, errors" do
      identity = Identity.new()
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 42

      assert {
               :error,
               %Error{message: "identity must have a wallet"}
             } = Request.Goloop.deposit_shared_fee(identity, to, value)
    end
  end

  describe "withdraw_shared_fee/3 with or without options" do
    setup do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      {:ok, identity: identity}
    end

    test "builds RPC call for withdrawing the whole deposit", %{
      identity: identity
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

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
                   dataType: :deposit,
                   data: %{
                     action: :withdraw
                   }
                 }
               }
             } = Request.Goloop.withdraw_shared_fee(identity, to)
    end

    test "encodes full withdraw correctly", %{identity: identity} do
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
                 "timestamp" => "0x" <> _timestamp,
                 "nid" => "0x1",
                 "nonce" => "0x" <> _nonce,
                 "dataType" => "deposit",
                 "data" => %{
                   "action" => "withdraw"
                 }
               }
             } =
               identity
               |> Request.Goloop.withdraw_shared_fee(to, value)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "builds RPC call for withdrawing an specific amount from the deposit",
         %{
           identity: identity
         } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      amount = 42

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
                   dataType: :deposit,
                   data: %{
                     action: :withdraw,
                     amount: ^amount
                   }
                 }
               }
             } = Request.Goloop.withdraw_shared_fee(identity, to, amount)
    end

    test "encodes partial deposit withdraw by amount correctly", %{
      identity: identity
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      amount = 42

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
                 "dataType" => "deposit",
                 "data" => %{
                   "action" => "withdraw",
                   "amount" => "0x2a"
                 }
               }
             } =
               identity
               |> Request.Goloop.withdraw_shared_fee(to, amount)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "builds an RPC call to withdraw a deposit by id", %{
      identity: identity
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      hash =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

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
                   dataType: :deposit,
                   data: %{
                     action: :withdraw,
                     id: ^hash
                   }
                 }
               }
             } = Request.Goloop.withdraw_shared_fee(identity, to, hash)
    end

    test "encodes partial deposit withdraw by id correctly", %{
      identity: identity
    } do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      hash =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

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
                 "dataType" => "deposit",
                 "data" => %{
                   "action" => "withdraw",
                   "id" => ^hash
                 }
               }
             } =
               identity
               |> Request.Goloop.withdraw_shared_fee(to, hash)
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
                   dataType: :deposit,
                   data: %{
                     action: :withdraw
                   }
                 }
               }
             } =
               Request.Goloop.withdraw_shared_fee(identity, to, nil,
                 timeout: timeout
               )
    end

    test "encodes icx_sendTransactionAndWait correctly", %{identity: identity} do
      from = identity.address
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
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
                 "dataType" => "deposit",
                 "data" => %{
                   "action" => "withdraw"
                 }
               }
             } =
               identity
               |> Request.Goloop.withdraw_shared_fee(to, nil, timeout: timeout)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "adds identity", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {:ok, %Request{options: %{identity: ^identity}}} =
               Request.Goloop.withdraw_shared_fee(identity, to)
    end

    test "adds schema for full withdraw to the request", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

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
                     dataType: {{:enum, [:deposit]}, default: :deposit},
                     data: {
                       %{
                         action: {{:enum, [:withdraw]}, default: :withdraw}
                       },
                       default: %{action: "withdraw"}
                     }
                   }
                 }
               }
             } = Request.Goloop.withdraw_shared_fee(identity, to)
    end

    test "adds schema for partial withdraw to the request", %{
      identity: identity
    } do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      value = 42

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
                     dataType: {{:enum, [:deposit]}, default: :deposit},
                     data: {
                       %{
                         action: {{:enum, [:withdraw]}, default: :withdraw},
                         amount: {:loop, required: true}
                       },
                       default: %{action: "withdraw"}
                     }
                   }
                 }
               }
             } = Request.Goloop.withdraw_shared_fee(identity, to, value)
    end

    test "adds schema for partial withdraw by id to the request", %{
      identity: identity
    } do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      hash =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

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
                     dataType: {{:enum, [:deposit]}, default: :deposit},
                     data: {
                       %{
                         action: {{:enum, [:withdraw]}, default: :withdraw},
                         id: {:hash, required: true}
                       },
                       default: %{action: "withdraw"}
                     }
                   }
                 }
               }
             } = Request.Goloop.withdraw_shared_fee(identity, to, hash)
    end

    test "overrides any parameter in the request", %{identity: identity} do
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      options = [params: %{version: 4}]

      assert {:ok, %Request{params: %{version: 4}}} =
               Request.Goloop.withdraw_shared_fee(identity, to, nil, options)
    end

    test "when params are invalid, errors", %{identity: identity} do
      assert {
               :error,
               %Error{message: "to is invalid"}
             } = Request.Goloop.withdraw_shared_fee(identity, "cx0")
    end

    test "when identity doesn't have a wallet, errors" do
      identity = Identity.new()
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {
               :error,
               %Error{message: "identity must have a wallet"}
             } = Request.Goloop.withdraw_shared_fee(identity, to)
    end
  end
end
