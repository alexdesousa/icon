defmodule Icon.RPC.GoloopTest do
  use ExUnit.Case, async: true

  alias Icon.RPC

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
                 options: [
                   types: %{
                     hash: Icon.Types.Hash,
                     height: Icon.Types.Integer
                   }
                 ],
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
                 options: [
                   types: %{
                     hash: Icon.Types.Hash,
                     height: Icon.Types.Integer
                   }
                 ],
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
                 options: [
                   types: %{
                     hash: Icon.Types.Hash,
                     height: Icon.Types.Integer
                   }
                 ],
                 params: %{
                   hash: ^hash
                 }
               }
             } = RPC.Goloop.get_block(hash: hash, height: height)
    end

    test "when invalid hash is provided, errors" do
      assert {
               :error,
               %Ecto.Changeset{errors: [hash: {"is invalid", _}]}
             } = RPC.Goloop.get_block(hash: "0x0")
    end

    test "when invalid height is provided, errors" do
      assert {
               :error,
               %Ecto.Changeset{errors: [height: {"is invalid", _}]}
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
                 options: [
                   types: %{
                     address: Icon.Types.Address
                   }
                 ],
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
                 options: [
                   types: %{
                     address: Icon.Types.Address
                   }
                 ],
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
               %Ecto.Changeset{errors: [address: {"is invalid", _}]}
             } = RPC.Goloop.get_balance("hx0")
    end

    test "when invalid SCORE address is provided, errors" do
      assert {
               :error,
               %Ecto.Changeset{errors: [address: {"is invalid", _}]}
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
                 options: [
                   types: %{
                     address: Icon.Types.SCORE
                   }
                 ],
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
               %Ecto.Changeset{errors: [address: {"is invalid", _}]}
             } = RPC.Goloop.get_score_api("cx0")
    end

    test "when valid EOA address is provided, errors" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert {
               :error,
               %Ecto.Changeset{errors: [address: {"is invalid", _}]}
             } = RPC.Goloop.get_score_api(address)
    end
  end
end
