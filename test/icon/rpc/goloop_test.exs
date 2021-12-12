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
end
