defmodule Icon.Schema.DumperTest do
  use ExUnit.Case, async: true
  import Icon.Schema, only: [list: 1, any: 2, enum: 1]

  alias Icon.Schema
  alias Icon.Schema.Error
  alias Icon.Schema.Types.EventLog

  describe "Icon.Schema.dump/1" do
    test "parameters can be a keyword list" do
      assert %Schema{
               data: %{integer: "0x2a"},
               is_valid?: true
             } =
               %{integer: :integer}
               |> Schema.generate()
               |> Schema.new(integer: 42)
               |> Schema.dump()
    end

    test "adds error when required field is missing" do
      assert %Schema{
               errors: %{integer: "is required"},
               is_valid?: false
             } =
               %{integer: {:integer, required: true}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.dump()
    end

    test "uses default when field is missing" do
      assert %Schema{
               data: %{integer: "0x2a"},
               is_valid?: true
             } =
               %{integer: {:integer, default: 42}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.dump()
    end

    test "doesn't add an error when the missing field is required, but a default is provided" do
      assert %Schema{
               data: %{integer: "0x2a"},
               is_valid?: true
             } =
               %{integer: {:integer, default: 42, required: true}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.dump()
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
               |> Schema.dump()
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
               |> Schema.dump()
    end

    test "when default is an empty string ignores it" do
      assert %Schema{
               data: %{},
               is_valid?: true
             } =
               %{integer: {:integer, default: ""}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.dump()
    end

    test "adds error when required field has a default that's an empty string" do
      assert %Schema{
               errors: %{integer: "is required"},
               is_valid?: false
             } =
               %{integer: {:integer, default: "", required: true}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.dump()
    end

    test "when schema is missing, ignores it" do
      assert %Schema{
               data: %{},
               is_valid?: true
             } =
               %{schema: %{integer: :integer}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.dump()
    end

    test "when enum is missing, ignores it" do
      assert %Schema{
               data: %{},
               is_valid?: true
             } =
               %{enum: enum([:call, :deploy, :message, :deposit])}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.dump()
    end

    test "when list is missing, ignores it" do
      assert %Schema{
               data: %{},
               is_valid?: true
             } =
               %{list: list(:integer)}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.dump()
    end

    test "dumps address type" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"
      params = %{"address" => address}

      assert %Schema{
               data: %{address: ^address},
               is_valid?: true
             } =
               %{address: :address}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
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
               |> Schema.dump()
    end

    test "dumps primitive any type" do
      data = 42
      params = %{"any" => 42}

      assert %Schema{
               data: %{any: ^data},
               is_valid?: true
             } =
               %{any: :any}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "dumps binary_data type" do
      params = %{"binary_data" => "ICON 2.0"}

      assert %Schema{
               data: %{binary_data: "0x49434f4e20322e30"},
               is_valid?: true
             } =
               %{binary_data: :binary_data}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "adds error when binary data is invalid" do
      params = %{"binary_data" => 42}

      assert %Schema{
               errors: %{binary_data: "is invalid"},
               is_valid?: false
             } =
               %{binary_data: :binary_data}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "dumps boolean type" do
      params = %{"boolean" => true}

      assert %Schema{
               data: %{boolean: "0x1"},
               is_valid?: true
             } =
               %{boolean: :boolean}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "adds error when boolean is invalid" do
      params = %{"boolean" => :invalid}

      assert %Schema{
               errors: %{boolean: "is invalid"},
               is_valid?: false
             } =
               %{boolean: :boolean}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "dumps eoa_address type" do
      eoa_address = "hxbe258ceb872e08851f1f59694dac2558708ece11"
      params = %{"eoa_address" => eoa_address}

      assert %Schema{
               data: %{eoa_address: ^eoa_address},
               is_valid?: true
             } =
               %{eoa_address: :eoa_address}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
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
               |> Schema.dump()
    end

    test "dumps error type" do
      params = %{
        "error" => %Error{
          domain: :internal,
          reason: :server_error,
          code: -32_000,
          message: "Server error",
          data:
            "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"
        }
      }

      assert %Schema{
               data: %{
                 error: %{
                   "code" => -32_000,
                   "message" => "Server error",
                   "data" =>
                     "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"
                 }
               },
               is_valid?: true
             } =
               %{error: :error}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "adds error when error type is invalid" do
      params = %{"error" => :invalid}

      assert %Schema{
               errors: %{error: "is invalid"},
               is_valid?: false
             } =
               %{error: :error}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "dumps event_log type" do
      params = %{
        "event_log" => %EventLog{
          header: "Transfer(Address,Address,int)",
          name: "Transfer",
          score_address: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
          indexed: [
            "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
            "hx2e243ad926ac48d15156756fce28314357d49d83"
          ],
          data: [
            42
          ]
        }
      }

      assert %Schema{
               data: %{
                 event_log: %{
                   "scoreAddress" =>
                     "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                   "indexed" => [
                     "Transfer(Address,Address,int)",
                     "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
                     "hx2e243ad926ac48d15156756fce28314357d49d83"
                   ],
                   "data" => [
                     "0x2a"
                   ]
                 }
               },
               is_valid?: true
             } =
               %{event_log: :event_log}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "adds error when event_log type is invalid" do
      params = %{"event_log" => :invalid}

      assert %Schema{
               errors: %{event_log: "is invalid"},
               is_valid?: false
             } =
               %{event_log: :event_log}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "dumps hash type" do
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
               |> Schema.dump()
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
               |> Schema.dump()
    end

    test "dumps integer type" do
      params = %{"integer" => 42}

      assert %Schema{
               data: %{integer: "0x2a"},
               is_valid?: true
             } =
               %{integer: :integer}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "adds error when integer is invalid" do
      params = %{"integer" => -42}

      assert %Schema{
               errors: %{integer: "is invalid"},
               is_valid?: false
             } =
               %{integer: :integer}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "dumps loop type" do
      params = %{"loop" => 42}

      assert %Schema{
               data: %{loop: "0x2a"},
               is_valid?: true
             } =
               %{loop: :loop}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "adds error when loop is invalid" do
      params = %{"loop" => -42}

      assert %Schema{
               errors: %{loop: "is invalid"},
               is_valid?: false
             } =
               %{loop: :loop}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "dumps score_address type" do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      params = %{"score_address" => score_address}

      assert %Schema{
               data: %{score_address: ^score_address},
               is_valid?: true
             } =
               %{score_address: :score_address}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
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
               |> Schema.dump()
    end

    test "dumps signature type" do
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
               |> Schema.dump()
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
               |> Schema.dump()
    end

    test "dumps string type" do
      string = "ICON 2.0"
      params = %{"string" => string}

      assert %Schema{
               data: %{string: ^string},
               is_valid?: true
             } =
               %{string: :string}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
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
               |> Schema.dump()
    end

    test "dumps timestamp type" do
      timestamp = 1_640_005_534_711_847
      datetime = DateTime.from_unix!(timestamp, :microsecond)
      params = %{"timestamp" => datetime}
      expected = "0x5d3938b538027"

      assert %Schema{
               data: %{timestamp: ^expected},
               is_valid?: true
             } =
               %{timestamp: :timestamp}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "adds error when timestamp is invalid" do
      params = %{"timestamp" => -377_705_116_800_000_001}

      assert %Schema{
               errors: %{timestamp: "is invalid"},
               is_valid?: false
             } =
               %{timestamp: :timestamp}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "dumps enum type as string" do
      params = %{"enum" => "call"}

      assert %Schema{
               data: %{enum: "call"},
               is_valid?: true
             } =
               %{enum: enum([:call, :deploy, :message, :deposit])}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "dumps enum type as atom" do
      params = %{"enum" => :call}

      assert %Schema{
               data: %{enum: "call"},
               is_valid?: true
             } =
               %{enum: enum([:call, :deploy, :message, :deposit])}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "errors when enum type is incorrect" do
      params = %{"enum" => :invalid}

      assert %Schema{
               errors: %{enum: "is invalid"},
               is_valid?: false
             } =
               %{enum: enum([:call, :deploy, :message, :deposit])}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "dumps anonymous schema" do
      params = %{"schema" => %{"integer" => 42}}

      assert %Schema{
               data: %{schema: %{integer: "0x2a"}},
               is_valid?: true
             } =
               %{schema: %{integer: :integer}}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
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
               |> Schema.dump()
    end

    test "dumps a list with primitive types" do
      params = %{"list" => [42, 43]}

      assert %Schema{
               data: %{list: ["0x2a", "0x2b"]},
               is_valid?: true
             } =
               %{list: list(:integer)}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "dumps a list with enum type" do
      params = %{"list" => [:call, :deploy]}

      assert %Schema{
               data: %{list: ["call", "deploy"]},
               is_valid?: true
             } =
               %{list: list(enum([:call, :deploy, :message, :deposit]))}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "raises when a list has any type" do
      params = %{
        "type" => :bool,
        "list" => [false, true]
      }

      schema = %{
        type: enum([:int, :bool]),
        list: list(any([int: :integer, boo: :boolean], :type))
      }

      assert_raise ArgumentError, fn ->
        schema
        |> Schema.generate()
        |> Schema.new(params)
        |> Schema.dump()
      end
    end

    test "adds error when list is invalid" do
      params = %{"list" => [42, "INVALID"]}

      assert %Schema{
               errors: %{list: "is invalid"},
               is_valid?: false
             } =
               %{list: list(:integer)}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "dumps any type" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      params = %{
        "type" => :score,
        "address" => address
      }

      assert %Schema{
               data: %{
                 type: "score",
                 address: ^address
               },
               is_valid?: true
             } =
               %{
                 type: enum([:score, :eoa]),
                 address: any([score: :score_address, eoa: :eoa_address], :type)
               }
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "adds error when any field is invalid" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      params = %{
        "type" => :invalid,
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
                 address: any([score: :score_address, eoa: :eoa_address], :type)
               }
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "adds error when any field value is not found" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      params = %{
        "type" => :eoa,
        "address" => address
      }

      assert %Schema{
               errors: %{address: "is invalid"},
               is_valid?: false
             } =
               %{
                 type: enum([:score, :eoa]),
                 address: any([score: :score_address, hash: :hash], :type)
               }
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "dumps delegated module type" do
      defmodule Int do
        use Icon.Schema.Type, delegate_to: Icon.Schema.Types.Integer
      end

      params = %{"integer" => 42}

      assert %Schema{
               data: %{integer: "0x2a"},
               is_valid?: true
             } =
               %{integer: Int}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "dumps module type" do
      defmodule Bool do
        use Icon.Schema.Type

        def load(0), do: {:ok, false}
        def load(1), do: {:ok, true}
        def load(_), do: :error

        def dump(false), do: {:ok, 0}
        def dump(true), do: {:ok, 1}
        def dump(_), do: :error
      end

      params = %{"boolean" => true}

      assert %Schema{
               data: %{boolean: 1},
               is_valid?: true
             } =
               %{boolean: Bool}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "dumps remote schema" do
      defmodule Remote do
        use Schema

        def init do
          %{integer: :integer}
        end
      end

      params = %{"schema" => %{"integer" => 42}}

      assert %Schema{
               data: %{schema: %{integer: "0x2a"}},
               is_valid?: true
             } =
               %{schema: Remote}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.dump()
    end

    test "module type must be compiled" do
      schema = %{module: UnexistentModule}

      assert_raise ArgumentError, fn ->
        Schema.generate(schema)
      end
    end
  end

  describe "apply/1" do
    test "returns data when state is valid" do
      assert {:ok, %{integer: "0x2a"}} =
               %{integer: :integer}
               |> Schema.generate()
               |> Schema.new(integer: 42)
               |> Schema.dump()
               |> Schema.apply()
    end

    test "returns error when state is invalid" do
      assert {
               :error,
               %Error{
                 code: -32_602,
                 reason: :invalid_params,
                 domain: :internal,
                 message: "integer is invalid"
               }
             } =
               %{integer: :integer}
               |> Schema.generate()
               |> Schema.new(integer: "INVALID")
               |> Schema.dump()
               |> Schema.apply()
    end
  end
end
