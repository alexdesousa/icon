defmodule Icon.RPC.RequestTest do
  use ExUnit.Case, async: true

  alias Icon.RPC.{Identity, Request}

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
end
