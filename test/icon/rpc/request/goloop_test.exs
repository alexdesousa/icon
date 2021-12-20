defmodule Icon.RPC.Request.GoloopTest do
  use ExUnit.Case, async: true

  alias Icon.RPC.Request
  alias Icon.Schema.Error

  describe "get_last_block/0" do
    test "builds RPC call for icx_getLastBlock" do
      assert {
               :ok,
               %Request{
                 method: "icx_getLastBlock",
                 options: [url: _],
                 params: %{}
               }
             } = Request.Goloop.get_last_block()
    end
  end

  describe "get_block_by_height/1" do
    test "builds RPC call for icx_getBlockByHeight" do
      height = 42

      assert {
               :ok,
               %Request{
                 method: "icx_getBlockByHeight",
                 options: [
                   url: _,
                   schema: %{height: {:integer, required: true}}
                 ],
                 params: %{
                   height: ^height
                 }
               }
             } = Request.Goloop.get_block_by_height(height)
    end

    test "encodes height correctly" do
      height = 42

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getBlockByHeight",
               "params" => %{
                 "height" => "0x2a"
               }
             } =
               height
               |> Request.Goloop.get_block_by_height()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when invalid height is provided, errors" do
      assert {
               :error,
               %Error{message: "height is invalid"}
             } = Request.Goloop.get_block_by_height(-42)
    end
  end

  describe "get_block_by_hash/1" do
    test "builds RPC call for icx_getBlockByHash" do
      hash =
        "0x8e25acc5b5c74375079d51828760821fc6f54283656620b1d5a715edcc0770c6"

      assert {
               :ok,
               %Request{
                 method: "icx_getBlockByHash",
                 options: [
                   url: _,
                   schema: %{hash: {:hash, required: true}}
                 ],
                 params: %{
                   hash: ^hash
                 }
               }
             } = Request.Goloop.get_block_by_hash(hash)
    end

    test "encodes hash correctly" do
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
               hash
               |> Request.Goloop.get_block_by_hash()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when invalid hash is provided, errors" do
      assert {
               :error,
               %Error{message: "hash is invalid"}
             } = Request.Goloop.get_block_by_hash("0x0")
    end
  end

  describe "call/1" do
    test "when a valid, builds RPC call for icx_call" do
      from = "hxbe258ceb872e08851f1f59694dac2558708ece11"
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
                 options: [
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
                 ],
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
             } = Request.Goloop.call(from, to, options)
    end

    test "when params schema is empty, ignores parameters" do
      from = "hxbe258ceb872e08851f1f59694dac2558708ece11"
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
                 options: [
                   url: _,
                   schema: %{
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     dataType: {:string, default: "call"},
                     data: %{
                       method: {:string, required: true}
                     }
                   }
                 ],
                 params: %{
                   from: ^from,
                   to: ^to,
                   dataType: "call",
                   data: %{
                     method: "getBalance"
                   }
                 }
               }
             } = Request.Goloop.call(from, to, options)
    end

    test "encodes it correctly" do
      from = "hxbe258ceb872e08851f1f59694dac2558708ece11"
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
               from
               |> Request.Goloop.call(to, options)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when from address is invalid, errors" do
      from = "hx0"
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      options = [
        method: "getBalance",
        params: %{
          address: to
        },
        schema: %{address: {:address, required: true}}
      ]

      assert {
               :error,
               %Error{message: "from is invalid"}
             } = Request.Goloop.call(from, to, options)
    end

    test "when from is a SCORE address, errors" do
      from = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      to = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      options = [
        method: "getBalance",
        params: %{
          address: from
        },
        schema: %{address: {:address, required: true}}
      ]

      assert {
               :error,
               %Error{message: "from is invalid"}
             } = Request.Goloop.call(from, to, options)
    end

    test "when to address is invalid, errors" do
      from = "hxbe258ceb872e08851f1f59694dac2558708ece11"
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
             } = Request.Goloop.call(from, to, options)
    end

    test "when to is a EOA address, errors" do
      from = "hxbe258ceb872e08851f1f59694dac2558708ece11"
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
             } = Request.Goloop.call(from, to, options)
    end

    test "when params is invalid, errors" do
      from = "hxbe258ceb872e08851f1f59694dac2558708ece11"
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
             } = Request.Goloop.call(from, to, options)
    end
  end

  describe "get_balance/1" do
    test "when valid EOA address is provided, builds RPC call for icx_getBalance" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert {
               :ok,
               %Request{
                 method: "icx_getBalance",
                 options: [
                   url: _,
                   schema: %{address: {:address, required: true}}
                 ],
                 params: %{
                   address: ^address
                 }
               }
             } = Request.Goloop.get_balance(address)
    end

    test "encodes EOA address correctly" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getBalance",
               "params" => %{
                 "address" => ^address
               }
             } =
               address
               |> Request.Goloop.get_balance()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when valid SCORE address is provided, builds RPC call for icx_getBalance" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {
               :ok,
               %Request{
                 method: "icx_getBalance",
                 options: [
                   url: _,
                   schema: %{address: {:address, required: true}}
                 ],
                 params: %{
                   address: ^address
                 }
               }
             } = Request.Goloop.get_balance(address)
    end

    test "encodes SCORE address correctly" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getBalance",
               "params" => %{
                 "address" => ^address
               }
             } =
               address
               |> Request.Goloop.get_balance()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when invalid EOA address is provided, errors" do
      assert {
               :error,
               %Error{message: "address is invalid"}
             } = Request.Goloop.get_balance("hx0")
    end

    test "when invalid SCORE address is provided, errors" do
      assert {
               :error,
               %Error{message: "address is invalid"}
             } = Request.Goloop.get_balance("cx0")
    end
  end

  describe "get_score_api/1" do
    test "when valid SCORE address is provided, builds RPC call for icx_getScoreApi" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {
               :ok,
               %Request{
                 method: "icx_getScoreApi",
                 options: [
                   url: _,
                   schema: %{address: {:score_address, required: true}}
                 ],
                 params: %{
                   address: ^address
                 }
               }
             } = Request.Goloop.get_score_api(address)
    end

    test "encodes SCORE address correctly" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getScoreApi",
               "params" => %{
                 "address" => ^address
               }
             } =
               address
               |> Request.Goloop.get_score_api()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when invalid SCORE address is provided, errors" do
      assert {
               :error,
               %Error{message: "address is invalid"}
             } = Request.Goloop.get_score_api("cx0")
    end

    test "when valid EOA address is provided, errors" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert {
               :error,
               %Error{message: "address is invalid"}
             } = Request.Goloop.get_score_api(address)
    end
  end

  describe "get_total_supply/0" do
    test "builds RPC call for icx_getTotalSupply" do
      assert {
               :ok,
               %Request{
                 method: "icx_getTotalSupply",
                 options: [url: _],
                 params: %{}
               }
             } = Request.Goloop.get_total_supply()
    end

    test "encodes it correctly" do
      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getTotalSupply"
             } =
               Request.Goloop.get_total_supply()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end
  end

  describe "get_transaction_result/1" do
    test "builds RPC call for icx_getTransactionResult" do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      assert {
               :ok,
               %Request{
                 method: "icx_getTransactionResult",
                 options: [
                   url: _,
                   schema: %{txHash: {:hash, required: true}}
                 ],
                 params: %{
                   txHash: ^tx_hash
                 }
               }
             } = Request.Goloop.get_transaction_result(tx_hash)
    end

    test "encodes it correctly" do
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
               tx_hash
               |> Request.Goloop.get_transaction_result()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when invalid hash is provided, errors" do
      assert {
               :error,
               %Error{message: "txHash is invalid"}
             } = Request.Goloop.get_transaction_result("0x0")
    end
  end

  describe "get_transaction_by_hash/1" do
    test "builds RPC call for icx_getTransactionByHash" do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      assert {
               :ok,
               %Request{
                 method: "icx_getTransactionByHash",
                 options: [
                   url: _,
                   schema: %{txHash: {:hash, required: true}}
                 ],
                 params: %{
                   txHash: ^tx_hash
                 }
               }
             } = Request.Goloop.get_transaction_by_hash(tx_hash)
    end

    test "encodes it correctly" do
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
               tx_hash
               |> Request.Goloop.get_transaction_by_hash()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when invalid hash is provided, errors" do
      assert {
               :error,
               %Error{message: "txHash is invalid"}
             } = Request.Goloop.get_transaction_by_hash("0x0")
    end
  end

  describe "wait_transaction_result/1" do
    test "builds RPC call for icx_waitTransactionResult" do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      timeout = 5_000

      assert {
               :ok,
               %Request{
                 method: "icx_waitTransactionResult",
                 options: [
                   url: _,
                   schema: %{txHash: {:hash, required: true}},
                   timeout: ^timeout
                 ],
                 params: %{
                   txHash: ^tx_hash
                 }
               }
             } = Request.Goloop.wait_transaction_result(tx_hash, timeout)
    end

    test "encodes it correctly" do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_waitTransactionResult",
               "params" => %{
                 "txHash" => ^tx_hash
               }
             } =
               tx_hash
               |> Request.Goloop.wait_transaction_result(5_000)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when invalid hash is provided, errors" do
      assert {
               :error,
               %Error{message: "txHash is invalid"}
             } = Request.Goloop.wait_transaction_result("0x0", 5_000)
    end

    test "when invalid timeout is provided, raises" do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      assert_raise FunctionClauseError, fn ->
        Request.Goloop.wait_transaction_result(tx_hash, -5_000)
      end
    end
  end
end
