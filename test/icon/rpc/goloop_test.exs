defmodule Icon.RPC.GoloopTest do
  use ExUnit.Case, async: true

  alias Icon.RPC
  alias Icon.Types.Error

  describe "get_block/0" do
    test "builds RPC call for icx_getLastBlock" do
      assert {
               :ok,
               %RPC{
                 method: "icx_getLastBlock",
                 options: [],
                 params: %{}
               }
             } = RPC.Goloop.get_block()
    end

    test "it is encoded correctly" do
      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getLastBlock"
             } =
               RPC.Goloop.get_block()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end
  end

  describe "get_block/1" do
    test "when hash provided, builds RPC call for icx_getBlockByHash" do
      hash =
        "0x8e25acc5b5c74375079d51828760821fc6f54283656620b1d5a715edcc0770c6"

      assert {
               :ok,
               %RPC{
                 method: "icx_getBlockByHash",
                 options: [schema: %{hash: {:hash, required: true}}],
                 params: %{
                   hash: ^hash
                 }
               }
             } = RPC.Goloop.get_block(hash: hash)
    end

    test "encodes hash correctly" do
      hash = "8e25acc5b5c74375079d51828760821fc6f54283656620b1d5a715edcc0770c6"

      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getBlockByHash",
               "params" => %{
                 "hash" =>
                   "0x8e25acc5b5c74375079d51828760821fc6f54283656620b1d5a715edcc0770c6"
               }
             } =
               [hash: hash]
               |> RPC.Goloop.get_block()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when height provided, builds RPC call for icx_getBlockByHeight" do
      height = 42

      assert {
               :ok,
               %RPC{
                 method: "icx_getBlockByHeight",
                 options: [schema: %{height: {:integer, required: true}}],
                 params: %{
                   height: ^height
                 }
               }
             } = RPC.Goloop.get_block(height: height)
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
               [height: height]
               |> RPC.Goloop.get_block()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when hash and height are provided, builds RPC call for icx_getBlockByHash" do
      hash =
        "0x8e25acc5b5c74375079d51828760821fc6f54283656620b1d5a715edcc0770c6"

      height = 42

      assert {
               :ok,
               %RPC{
                 method: "icx_getBlockByHash",
                 options: [schema: %{hash: {:hash, required: true}}],
                 params: %{
                   hash: ^hash
                 }
               }
             } = RPC.Goloop.get_block(hash: hash, height: height)
    end

    test "when invalid hash is provided, errors" do
      assert {
               :error,
               %Error{message: "hash is invalid"}
             } = RPC.Goloop.get_block(hash: "0x0")
    end

    test "when invalid height is provided, errors" do
      assert {
               :error,
               %Error{message: "height is invalid"}
             } = RPC.Goloop.get_block(height: -42)
    end
  end

  describe "get_balance/1" do
    test "when valid EOA address is provided, builds RPC call for icx_getBalance" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert {
               :ok,
               %RPC{
                 method: "icx_getBalance",
                 options: [schema: %{address: {:address, required: true}}],
                 params: %{
                   address: ^address
                 }
               }
             } = RPC.Goloop.get_balance(address)
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
               |> RPC.Goloop.get_balance()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when valid SCORE address is provided, builds RPC call for icx_getBalance" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {
               :ok,
               %RPC{
                 method: "icx_getBalance",
                 options: [schema: %{address: {:address, required: true}}],
                 params: %{
                   address: ^address
                 }
               }
             } = RPC.Goloop.get_balance(address)
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
               |> RPC.Goloop.get_balance()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when invalid EOA address is provided, errors" do
      assert {
               :error,
               %Error{message: "address is invalid"}
             } = RPC.Goloop.get_balance("hx0")
    end

    test "when invalid SCORE address is provided, errors" do
      assert {
               :error,
               %Error{message: "address is invalid"}
             } = RPC.Goloop.get_balance("cx0")
    end
  end

  describe "get_score_api/1" do
    test "when valid SCORE address is provided, builds RPC call for icx_getScoreApi" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {
               :ok,
               %RPC{
                 method: "icx_getScoreApi",
                 options: [schema: %{address: {:score_address, required: true}}],
                 params: %{
                   address: ^address
                 }
               }
             } = RPC.Goloop.get_score_api(address)
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
               |> RPC.Goloop.get_score_api()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when invalid SCORE address is provided, errors" do
      assert {
               :error,
               %Error{message: "address is invalid"}
             } = RPC.Goloop.get_score_api("cx0")
    end

    test "when valid EOA address is provided, errors" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert {
               :error,
               %Error{message: "address is invalid"}
             } = RPC.Goloop.get_score_api(address)
    end
  end

  describe "get_total_supply/0" do
    test "builds RPC call for icx_getTotalSupply" do
      assert {
               :ok,
               %RPC{
                 method: "icx_getTotalSupply",
                 options: [],
                 params: %{}
               }
             } = RPC.Goloop.get_total_supply()
    end

    test "it is encoded correctly" do
      assert %{
               "id" => _id,
               "jsonrpc" => "2.0",
               "method" => "icx_getTotalSupply"
             } =
               RPC.Goloop.get_total_supply()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end
  end

  describe "get_transaction/1" do
    test "when no options are provided, builds RPC call for icx_getTransactionResult" do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      assert {
               :ok,
               %RPC{
                 method: "icx_getTransactionResult",
                 options: [schema: %{txHash: {:hash, required: true}}],
                 params: %{
                   txHash: ^tx_hash
                 }
               }
             } = RPC.Goloop.get_transaction(tx_hash)
    end

    test "it is encoded correctly for icx_getTransactionResult" do
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
               |> RPC.Goloop.get_transaction()
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "it is encoded correctly for icx_getTransactionByHash" do
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
               |> RPC.Goloop.get_transaction(format: :transaction)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "it is encoded correctly for icx_waitTransactionResult" do
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
               |> RPC.Goloop.get_transaction(wait_for: 5000)
               |> elem(1)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "when wait_for=0 and format=:result, builds RPC call for icx_getTransactionResult" do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      options = [
        wait_for: 0,
        format: :result
      ]

      assert {
               :ok,
               %RPC{
                 method: "icx_getTransactionResult",
                 options: [schema: %{txHash: {:hash, required: true}}],
                 params: %{
                   txHash: ^tx_hash
                 }
               }
             } = RPC.Goloop.get_transaction(tx_hash, options)
    end

    test "when wait_for=0 and format=:transaction, builds RPC call for icx_getTransactionByHash" do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      options = [
        wait_for: 0,
        format: :transaction
      ]

      assert {
               :ok,
               %RPC{
                 method: "icx_getTransactionByHash",
                 options: [schema: %{txHash: {:hash, required: true}}],
                 params: %{
                   txHash: ^tx_hash
                 }
               }
             } = RPC.Goloop.get_transaction(tx_hash, options)
    end

    test "when wait_for>0 and format=:result, builds RPC call for icx_waitTransactionResult" do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      options = [
        wait_for: 5000,
        format: :result
      ]

      assert {
               :ok,
               %RPC{
                 method: "icx_waitTransactionResult",
                 options: [
                   schema: %{txHash: {:hash, required: true}},
                   timeout: 5000,
                   format: :result
                 ],
                 params: %{
                   txHash: ^tx_hash
                 }
               }
             } = RPC.Goloop.get_transaction(tx_hash, options)
    end

    test "when wait_for>0 and format=:transaction, builds RPC call for icx_waitTransactionResult" do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      options = [
        wait_for: 5000,
        format: :transaction
      ]

      assert {
               :ok,
               %RPC{
                 method: "icx_waitTransactionResult",
                 options: [
                   schema: %{txHash: {:hash, required: true}},
                   timeout: 5000,
                   format: :transaction
                 ],
                 params: %{
                   txHash: ^tx_hash
                 }
               }
             } = RPC.Goloop.get_transaction(tx_hash, options)
    end

    test "when invalid hash is provided, errors" do
      assert {
               :error,
               %Error{message: "txHash is invalid"}
             } = RPC.Goloop.get_transaction("0x0")
    end

    test "when invalid wait_for value is provided, raises" do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      assert {
               :error,
               %Error{message: "wait_for is invalid"}
             } = RPC.Goloop.get_transaction(tx_hash, wait_for: -1)
    end

    test "when invalid format is provided, errors" do
      tx_hash =
        "0xd8da71e926052b960def61c64f325412772f8e986f888685bc87c0bc046c2d9f"

      assert {
               :error,
               %Error{message: "format is invalid"}
             } = RPC.Goloop.get_transaction(tx_hash, format: :full)
    end
  end
end
