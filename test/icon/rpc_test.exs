defmodule Icon.RPCTest do
  use ExUnit.Case, async: true

  alias Icon.RPC

  describe "build/1" do
    test "sets an id" do
      assert %RPC{id: id} = RPC.build("method")
      assert is_integer(id) and id > 0
    end

    test "sets a method" do
      assert %RPC{method: "method"} = RPC.build("method")
    end

    test "sets empty params" do
      assert %RPC{params: params} = RPC.build("method")
      assert params == %{}
    end

    test "sets empty options" do
      assert %RPC{options: []} = RPC.build("method")
    end
  end

  describe "build/3" do
    test "sets an id" do
      assert %RPC{id: id} = RPC.build("method", %{}, [])
      assert is_integer(id) and id > 0
    end

    test "sets a method" do
      assert %RPC{method: "method"} = RPC.build("method", %{}, [])
    end

    test "sets params" do
      assert %RPC{params: %{int: 42}} = RPC.build("method", %{int: 42}, [])
    end

    test "sets options" do
      params = %{int: 42}
      options = [schema: %{int: :integer}]

      assert %RPC{options: ^options} = RPC.build("method", params, options)
    end
  end

  describe "encoder" do
    test "ignores options" do
      payload =
        "icx_method"
        |> RPC.build(%{integer: 42}, schema: %{integer: :integer})
        |> Jason.encode!()
        |> Jason.decode!()

      assert :miss = Map.get(payload, "options", :miss)
    end

    test "adds jsonrpc version" do
      assert %{"jsonrpc" => "2.0"} =
               "icx_method"
               |> RPC.build()
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "keeps the id" do
      assert %{"id" => id} =
               "icx_method"
               |> RPC.build()
               |> Jason.encode!()
               |> Jason.decode!()

      assert is_integer(id) and id > 0
    end

    test "keeps the method" do
      assert %{"method" => "icx_method"} =
               "icx_method"
               |> RPC.build()
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "encodes params according to type" do
      params = %{
        address: "hxbe258ceb872e08851f1f59694dac2558708ece11",
        binary_data: "0x34b2",
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
                 "binary_data" => "0x34b2",
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
               |> RPC.build(params, options)
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "does not include empty parameters" do
      payload =
        "icx_method"
        |> RPC.build()
        |> Jason.encode!()
        |> Jason.decode!()

      assert :miss = Map.get(payload, "params", :miss)
    end

    test "ignores value when the type is not found in the options" do
      assert %{"params" => %{}} =
               "icx_method"
               |> RPC.build(%{integer: 42}, schema: %{})
               |> Jason.encode!()
               |> Jason.decode!()
    end

    test "raises when the schema cannot be dumped" do
      assert_raise ArgumentError, fn ->
        "icx_method"
        |> RPC.build(%{integer: "INVALID"}, schema: %{integer: :integer})
        |> Jason.encode!()
        |> Jason.decode!()
      end
    end
  end
end
