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

    test "builds RPC call for icx_waitTransactionResult" do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      assert {
               :ok,
               %Request{
                 method: "icx_waitTransactionResult",
                 options: [
                   url: _,
                   schema: %{txHash: {:hash, required: true}},
                   timeout: 5_000
                 ],
                 params: %{
                   txHash: ^tx_hash
                 }
               }
             } = Request.Goloop.get_transaction_result(tx_hash, timeout: 5_000)
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

  describe "send_transaction/1 for coin transfers" do
    test "builds RPC call for icx_sendTransaction" do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: datetime,
        nid: 1,
        signature: "c2lnbmF0dXJl",
        nonce: 1
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 options: [
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: {:loop, required: true},
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     signature: {:signature, required: true},
                     nonce: {:integer, default: 1}
                   }
                 ],
                 params: ^params
               }
             } = Request.Goloop.send_transaction(params: params)
    end

    test "builds RPC call for icx_sendTransactionAndWait" do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: datetime,
        nid: 1,
        signature: "c2lnbmF0dXJl",
        nonce: 1
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransactionAndWait",
                 options: [
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: {:loop, required: true},
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     signature: {:signature, required: true},
                     nonce: {:integer, default: 1}
                   },
                   timeout: 5_000
                 ],
                 params: ^params
               }
             } =
               Request.Goloop.send_transaction(
                 params: params,
                 timeout: 5_000
               )
    end

    test "encodes it correctly" do
      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nid: 1,
        signature: "c2lnbmF0dXJl",
        nonce: 1
      }

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_sendTransaction",
               "params" => %{
                 "version" => "0x3",
                 "from" => "hxbe258ceb872e08851f1f59694dac2558708ece11",
                 "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "value" => "0x2a",
                 "stepLimit" => "0xa",
                 "timestamp" => 1_640_005_534_711_847,
                 "nid" => "0x1",
                 "signature" => "c2lnbmF0dXJl",
                 "nonce" => "0x1"
               }
             } =
               [params: params]
               |> Request.Goloop.send_transaction()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when dataType is invalid, errors" do
      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nid: 1,
        signature: "c2lnbmF0dXJl",
        nonce: 1,
        dataType: :invalid
      }

      assert {
               :error,
               %Error{message: "dataType is invalid"}
             } = Request.Goloop.send_transaction(params: params)
    end
  end

  describe "send_transaction/1 for method calls" do
    test "builds RPC call for icx_sendTransaction with params" do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nid: 1,
        signature: "c2lnbmF0dXJl",
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
                 options: [
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     value: :loop,
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     signature: {:signature, required: true},
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
                 ],
                 params: ^params
               }
             } =
               Request.Goloop.send_transaction(
                 params: params,
                 schema: call_schema
               )
    end

    test "encodes it correctly with params" do
      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nid: 1,
        signature: "c2lnbmF0dXJl",
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
                 "from" => "hxbe258ceb872e08851f1f59694dac2558708ece11",
                 "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "stepLimit" => "0xa",
                 "timestamp" => 1_640_005_534_711_847,
                 "nid" => "0x1",
                 "signature" => "c2lnbmF0dXJl",
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
               [params: params, schema: call_schema]
               |> Request.Goloop.send_transaction()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "builds RPC call for icx_sendTransaction without params" do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nid: 1,
        signature: "c2lnbmF0dXJl",
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
                 options: [
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     value: :loop,
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     signature: {:signature, required: true},
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
                 ],
                 params: ^params
               }
             } = Request.Goloop.send_transaction(params: params)
    end

    test "encodes it correctly without params" do
      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nid: 1,
        signature: "c2lnbmF0dXJl",
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
                 "from" => "hxbe258ceb872e08851f1f59694dac2558708ece11",
                 "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "stepLimit" => "0xa",
                 "timestamp" => 1_640_005_534_711_847,
                 "nid" => "0x1",
                 "signature" => "c2lnbmF0dXJl",
                 "nonce" => "0x1",
                 "dataType" => "call",
                 "data" => %{
                   "method" => "getBalance"
                 }
               }
             } =
               [params: params]
               |> Request.Goloop.send_transaction()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end
  end

  describe "send_transaction/1 for deploys" do
    test "builds RPC call for icx_sendTransaction with params" do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nid: 1,
        signature: "c2lnbmF0dXJl",
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
                 options: [
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     value: :loop,
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     signature: {:signature, required: true},
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
                 ],
                 params: ^params
               }
             } =
               Request.Goloop.send_transaction(
                 params: params,
                 schema: deploy_schema
               )
    end

    test "encodes it correctly with params" do
      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nid: 1,
        signature: "c2lnbmF0dXJl",
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
                 "from" => "hxbe258ceb872e08851f1f59694dac2558708ece11",
                 "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "stepLimit" => "0xa",
                 "timestamp" => 1_640_005_534_711_847,
                 "nid" => "0x1",
                 "signature" => "c2lnbmF0dXJl",
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
               [params: params, schema: deploy_schema]
               |> Request.Goloop.send_transaction()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "builds RPC call for icx_sendTransaction without params" do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nid: 1,
        signature: "c2lnbmF0dXJl",
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
                 options: [
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:score_address, required: true},
                     value: :loop,
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     signature: {:signature, required: true},
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
                 ],
                 params: ^params
               }
             } = Request.Goloop.send_transaction(params: params)
    end

    test "encodes it correctly without params" do
      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nid: 1,
        signature: "c2lnbmF0dXJl",
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
                 "from" => "hxbe258ceb872e08851f1f59694dac2558708ece11",
                 "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "stepLimit" => "0xa",
                 "timestamp" => 1_640_005_534_711_847,
                 "nid" => "0x1",
                 "signature" => "c2lnbmF0dXJl",
                 "nonce" => "0x1",
                 "dataType" => "deploy",
                 "data" => %{
                   "contentType" => "application/zip",
                   "content" =>
                     "0x1867291283973610982301923812873419826abcdef9182731926312"
                 }
               }
             } =
               [params: params]
               |> Request.Goloop.send_transaction()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end
  end

  describe "send_transaction/1 for deposits" do
    test "builds RPC for icx_sendTransaction (action=add)" do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: datetime,
        nid: 1,
        signature: "c2lnbmF0dXJl",
        nonce: 1,
        dataType: :deposit,
        data: %{action: :add}
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 options: [
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: {:loop, required: true},
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     signature: {:signature, required: true},
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
                 ],
                 params: ^params
               }
             } = Request.Goloop.send_transaction(params: params)
    end

    test "encodes it correctly (action=add)" do
      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nid: 1,
        signature: "c2lnbmF0dXJl",
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
                 "from" => "hxbe258ceb872e08851f1f59694dac2558708ece11",
                 "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "value" => "0x2a",
                 "stepLimit" => "0xa",
                 "timestamp" => 1_640_005_534_711_847,
                 "nid" => "0x1",
                 "signature" => "c2lnbmF0dXJl",
                 "nonce" => "0x1",
                 "dataType" => "deposit",
                 "data" => %{
                   "action" => "add"
                 }
               }
             } =
               [params: params]
               |> Request.Goloop.send_transaction()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "builds RPC for icx_sendTransaction (action withdraw)" do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nid: 1,
        signature: "c2lnbmF0dXJl",
        nonce: 1,
        dataType: :deposit,
        data: %{action: :withdraw}
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 options: [
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: :loop,
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     signature: {:signature, required: true},
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
                 ],
                 params: ^params
               }
             } = Request.Goloop.send_transaction(params: params)
    end

    test "encodes it correctly (action=withdraw)" do
      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nid: 1,
        signature: "c2lnbmF0dXJl",
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
                 "from" => "hxbe258ceb872e08851f1f59694dac2558708ece11",
                 "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "value" => "0x2a",
                 "stepLimit" => "0xa",
                 "timestamp" => 1_640_005_534_711_847,
                 "nid" => "0x1",
                 "signature" => "c2lnbmF0dXJl",
                 "nonce" => "0x1",
                 "dataType" => "deposit",
                 "data" => %{
                   "action" => "withdraw"
                 }
               }
             } =
               [params: params]
               |> Request.Goloop.send_transaction()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when action is invalid, errors" do
      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 42,
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nid: 1,
        signature: "c2lnbmF0dXJl",
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
             } = Request.Goloop.send_transaction(params: params)
    end
  end

  describe "send_transaction/1 for messages" do
    test "builds RPC for icx_sendTransaction" do
      datetime = DateTime.utc_now()

      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: datetime,
        nid: 1,
        signature: "c2lnbmF0dXJl",
        nonce: 1,
        dataType: :message,
        data: "0x2a"
      }

      assert {
               :ok,
               %Request{
                 method: "icx_sendTransaction",
                 options: [
                   url: _,
                   schema: %{
                     version: {:integer, required: true},
                     from: {:eoa_address, required: true},
                     to: {:address, required: true},
                     value: :loop,
                     stepLimit: {:integer, required: true},
                     timestamp: {:timestamp, required: true},
                     nid: {:integer, required: true},
                     signature: {:signature, required: true},
                     nonce: {:integer, default: 1},
                     dataType:
                       {{:enum, [:message]}, default: :message, required: true},
                     data: {:binary_data, required: true}
                   }
                 ],
                 params: ^params
               }
             } = Request.Goloop.send_transaction(params: params)
    end

    test "encodes it correctly (action=add)" do
      params = %{
        version: 3,
        from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        stepLimit: 10,
        timestamp: 1_640_005_534_711_847,
        nid: 1,
        signature: "c2lnbmF0dXJl",
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
                 "from" => "hxbe258ceb872e08851f1f59694dac2558708ece11",
                 "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "stepLimit" => "0xa",
                 "timestamp" => 1_640_005_534_711_847,
                 "nid" => "0x1",
                 "signature" => "c2lnbmF0dXJl",
                 "nonce" => "0x1",
                 "dataType" => "message",
                 "data" => "0x2a"
               }
             } =
               [params: params]
               |> Request.Goloop.send_transaction()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end
  end
end
