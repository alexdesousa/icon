defmodule Icon.Types.SchemaTest do
  use ExUnit.Case, async: true
  import Icon.Types.Schema, only: [list: 1, any: 1, enum: 1]

  alias Icon.Types.Schema

  describe "schema helpers" do
    test "list/1 expands a list type" do
      assert {:list, :address} = Schema.list(:address)
    end

    test "any/1 expands a any type" do
      assert {:any, [:eoa_address, :score_address]} =
               Schema.any([:eoa_address, :score_address])
    end

    test "enum/1 expands a any type" do
      assert {:enum, [:call, :deploy, :message, :deposit]} =
               Schema.enum([:call, :deploy, :message, :deposit])
    end
  end

  describe "validate/1" do
    test "parameters can be a keyword list" do
      assert %Schema{
               data: %{integer: 42},
               is_valid?: true
             } =
               %{integer: :integer}
               |> Schema.generate()
               |> Schema.new(integer: "0x2a")
               |> Schema.validate()
    end

    test "adds error when required field is missing" do
      assert %Schema{
               errors: %{integer: "is required"},
               is_valid?: false
             } =
               %{integer: {:integer, required: true}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.validate()
    end

    test "uses default when field is missing" do
      assert %Schema{
               data: %{integer: 42},
               is_valid?: true
             } =
               %{integer: {:integer, default: "0x2a"}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.validate()
    end

    test "doesn't add an error when the missing field is required, but a default is provided" do
      assert %Schema{
               data: %{integer: 42},
               is_valid?: true
             } =
               %{integer: {:integer, default: "0x2a", required: true}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.validate()
    end

    test "add error when required field is empty string" do
      params = %{"integer" => ""}

      assert %Schema{
               errors: %{integer: "is required"},
               is_valid?: false
             } =
               %{integer: {:integer, required: true}}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "does not add error when non required field is empty string" do
      params = %{"integer" => ""}

      assert %Schema{
               data: %{},
               is_valid?: true
             } =
               %{integer: :integer}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "when default is an empty string ignores it" do
      assert %Schema{
               data: %{},
               is_valid?: true
             } =
               %{integer: {:integer, default: ""}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.validate()
    end

    test "adds error when required field has a default that's an empty string" do
      assert %Schema{
               errors: %{integer: "is required"},
               is_valid?: false
             } =
               %{integer: {:integer, default: "", required: true}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.validate()
    end

    test "when schema is missing, ignores it" do
      assert %Schema{
               data: %{},
               is_valid?: true
             } =
               %{schema: %{integer: :integer}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.validate()
    end

    test "when enum is missing, ignores it" do
      assert %Schema{
               data: %{},
               is_valid?: true
             } =
               %{enum: enum([:call, :deploy, :message, :deposit])}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.validate()
    end

    test "when list is missing, ignores it" do
      assert %Schema{
               data: %{},
               is_valid?: true
             } =
               %{list: list(:integer)}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.validate()
    end

    test "validates address type" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"
      params = %{"address" => address}

      assert %Schema{
               data: %{address: ^address},
               is_valid?: true
             } =
               %{address: :address}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "adds error when address is invalid" do
      params = %{"address" => "hx0"}

      assert %Schema{
               errors: %{address: "is invalid"},
               is_valid?: false
             } =
               %{address: :address}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "validates binary_data type" do
      binary_data = "0x34b2"
      params = %{"binary_data" => binary_data}

      assert %Schema{
               data: %{binary_data: ^binary_data},
               is_valid?: true
             } =
               %{binary_data: :binary_data}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "adds error when binary data is invalid" do
      params = %{"binary_data" => "0x0"}

      assert %Schema{
               errors: %{binary_data: "is invalid"},
               is_valid?: false
             } =
               %{binary_data: :binary_data}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "validates boolean type" do
      boolean = "0x1"
      params = %{"boolean" => boolean}

      assert %Schema{
               data: %{boolean: true},
               is_valid?: true
             } =
               %{boolean: :boolean}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "adds error when boolean is invalid" do
      params = %{"boolean" => "0x3"}

      assert %Schema{
               errors: %{boolean: "is invalid"},
               is_valid?: false
             } =
               %{boolean: :boolean}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "validates eoa_address type" do
      eoa_address = "hxbe258ceb872e08851f1f59694dac2558708ece11"
      params = %{"eoa_address" => eoa_address}

      assert %Schema{
               data: %{eoa_address: ^eoa_address},
               is_valid?: true
             } =
               %{eoa_address: :eoa_address}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "adds error when eoa_address is invalid" do
      params = %{"eoa_address" => "hx0"}

      assert %Schema{
               errors: %{eoa_address: "is invalid"},
               is_valid?: false
             } =
               %{eoa_address: :eoa_address}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "validates hash type" do
      hash =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      params = %{"hash" => hash}

      assert %Schema{
               data: %{hash: ^hash},
               is_valid?: true
             } =
               %{hash: :hash}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "adds error when hash is invalid" do
      params = %{"hash" => "0x0"}

      assert %Schema{
               errors: %{hash: "is invalid"},
               is_valid?: false
             } =
               %{hash: :hash}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "validates integer type" do
      params = %{"integer" => "0x2a"}

      assert %Schema{
               data: %{integer: 42},
               is_valid?: true
             } =
               %{integer: :integer}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "adds error when integer is invalid" do
      params = %{"integer" => "INVALID"}

      assert %Schema{
               errors: %{integer: "is invalid"},
               is_valid?: false
             } =
               %{integer: :integer}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "validates score_address type" do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      params = %{"score_address" => score_address}

      assert %Schema{
               data: %{score_address: ^score_address},
               is_valid?: true
             } =
               %{score_address: :score_address}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "adds error score_address is invalid" do
      params = %{"score_address" => "cx0"}

      assert %Schema{
               errors: %{score_address: "is invalid"},
               is_valid?: false
             } =
               %{score_address: :score_address}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "validates signature type" do
      signature =
        "VAia7YZ2Ji6igKWzjR2YsGa2m53nKPrfK7uXYW78QLE+ATehAVZPC40szvAiA6NEU5gCYB4c4qaQzqDh2ugcHgA="

      params = %{"signature" => signature}

      assert %Schema{
               data: %{signature: ^signature},
               is_valid?: true
             } =
               %{signature: :signature}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "adds error when signature is invalid" do
      params = %{"signature" => "INVALID"}

      assert %Schema{
               errors: %{signature: "is invalid"},
               is_valid?: false
             } =
               %{signature: :signature}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "validates string type" do
      string = "ICON 2.0"
      params = %{"string" => string}

      assert %Schema{
               data: %{string: ^string},
               is_valid?: true
             } =
               %{string: :string}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "adds error when string is invalid" do
      params = %{"string" => 42}

      assert %Schema{
               errors: %{string: "is invalid"},
               is_valid?: false
             } =
               %{string: :string}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "expands enum type" do
      params = %{"enum" => "call"}

      assert %Schema{
               data: %{enum: :call},
               is_valid?: true
             } =
               %{enum: enum([:call, :deploy, :message, :deposit])}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "errors when enum type is incorrect" do
      params = %{"enum" => "invalid"}

      assert %Schema{
               errors: %{enum: "is invalid"},
               is_valid?: false
             } =
               %{enum: enum([:call, :deploy, :message, :deposit])}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "enum values should be atoms" do
      values = ["call", "deploy", "message", "deposit"]
      schema = %{data_type: {:enum, values}}

      assert_raise ArgumentError, fn ->
        Schema.generate(schema)
      end
    end

    test "validates anonymous schema" do
      params = %{"schema" => %{"integer" => "0x2a"}}

      assert %Schema{
               data: %{schema: %{integer: 42}},
               is_valid?: true
             } =
               %{schema: %{integer: :integer}}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "adds anonymous schema errors" do
      params = %{"schema" => %{"integer" => "INVALID"}}

      assert %Schema{
               errors: %{schema: %{integer: "is invalid"}},
               is_valid?: false
             } =
               %{schema: %{integer: :integer}}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "validates a list" do
      params = %{"list" => ["0x2a", "0x2b"]}

      assert %Schema{
               data: %{list: [42, 43]},
               is_valid?: true
             } =
               %{list: list(:integer)}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "adds error when list is invalid" do
      params = %{"list" => ["0x2a", "INVALID"]}

      assert %Schema{
               errors: %{list: "is invalid"},
               is_valid?: false
             } =
               %{list: list(:integer)}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "validates any type" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      params = %{
        "type" => "score",
        "address" => address
      }

      assert %Schema{
               data: %{
                 type: :score,
                 address: ^address
               },
               is_valid?: true
             } =
               %{
                 type: enum([:score, :eoa]),
                 address: {
                   any(score: :score_address, eoa: :eoa_address),
                   field: :type
                 }
               }
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "adds error when any field is invalid" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      params = %{
        "type" => "invalid",
        "address" => address
      }

      assert %Schema{
               errors: %{
                 type: "is invalid",
                 address: "is invalid"
               },
               is_valid?: false
             } =
               %{
                 type: enum([:score, :eoa]),
                 address: {
                   any(score: :score_address, eoa: :eoa_address),
                   field: :type
                 }
               }
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "adds error when any field value is not found" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      params = %{
        "type" => "eoa",
        "address" => address
      }

      assert %Schema{
               errors: %{address: "is invalid"},
               is_valid?: false
             } =
               %{
                 type: enum([:score, :eoa]),
                 address: {
                   any(score: :score_address, hash: :hash),
                   field: :type
                 }
               }
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "validates delegated module type" do
      defmodule Int do
        use Icon.Types.Schema.Type, delegate_to: Icon.Types.Integer
      end

      params = %{"integer" => "0x2a"}

      assert %Schema{
               data: %{integer: 42},
               is_valid?: true
             } =
               %{integer: Int}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "validates module type" do
      defmodule Bool do
        use Icon.Types.Schema.Type

        def load(0), do: {:ok, false}
        def load(1), do: {:ok, true}
        def load(_), do: :error

        def dump(false), do: {:ok, 0}
        def dump(true), do: {:ok, 1}
        def dump(_), do: :error
      end

      params = %{"boolean" => 1}

      assert %Schema{
               data: %{boolean: true},
               is_valid?: true
             } =
               %{boolean: Bool}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "validates remote schema" do
      defmodule Remote do
        use Schema

        def init do
          %{integer: :integer}
        end
      end

      params = %{"schema" => %{"integer" => "0x2a"}}

      assert %Schema{
               data: %{schema: %{integer: 42}},
               is_valid?: true
             } =
               %{schema: Remote}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.validate()
    end

    test "module type must be compiled" do
      schema = %{module: UnexistentModule}

      assert_raise ArgumentError, fn ->
        Schema.generate(schema)
      end
    end
  end
end
