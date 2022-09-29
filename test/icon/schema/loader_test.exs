defmodule Icon.Schema.LoaderTest do
  use ExUnit.Case, async: true
  import Icon.Schema, only: [list: 1, any: 2, enum: 1]

  alias Icon.Schema
  alias Icon.Schema.Error
  alias Icon.Schema.Types.EventLog

  describe "Icon.Schema.load/1" do
    test "parameters can be a keyword list" do
      assert %Schema{
               data: %{integer: 42},
               is_valid?: true
             } =
               %{integer: :integer}
               |> Schema.generate()
               |> Schema.new(integer: "0x2a")
               |> Schema.load()
    end

    test "adds error when required field is missing" do
      assert %Schema{
               errors: %{integer: "is required"},
               is_valid?: false
             } =
               %{integer: {:integer, required: true}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.load()
    end

    test "uses default when field is missing" do
      assert %Schema{
               data: %{integer: 42},
               is_valid?: true
             } =
               %{integer: {:integer, default: "0x2a"}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.load()
    end

    test "expands default function when field is missing" do
      assert %Schema{
               data: %{integer: 42},
               is_valid?: true
             } =
               %{integer: {:integer, default: fn %Schema{} -> 42 end}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.load()
    end

    test "keeps field when is nil and it's nullable" do
      assert %Schema{
               data: %{integer: nil},
               is_valid?: true
             } =
               %{integer: {:integer, nullable: true}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.load()
    end

    test "keeps field when is an empty binary and it's nullable" do
      assert %Schema{
               data: %{string: ""},
               is_valid?: true
             } =
               %{string: {:string, nullable: true, default: ""}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.load()
    end

    test "uses the provided value for a nullable field" do
      assert %Schema{
               data: %{integer: 42},
               is_valid?: true
             } =
               %{integer: {:integer, nullable: true}}
               |> Schema.generate()
               |> Schema.new(%{integer: 42})
               |> Schema.load()
    end

    test "doesn't add an error when the missing field is required, but a default is provided" do
      assert %Schema{
               data: %{integer: 42},
               is_valid?: true
             } =
               %{integer: {:integer, default: "0x2a", required: true}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.load()
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
               |> Schema.load()
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
               |> Schema.load()
    end

    test "when default is an empty string ignores it" do
      assert %Schema{
               data: %{},
               is_valid?: true
             } =
               %{integer: {:integer, default: ""}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.load()
    end

    test "adds error when required field has a default that's an empty string" do
      assert %Schema{
               errors: %{integer: "is required"},
               is_valid?: false
             } =
               %{integer: {:integer, default: "", required: true}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.load()
    end

    test "when schema is missing, ignores them" do
      assert %Schema{
               data: %{},
               is_valid?: true
             } =
               %{schema: %{integer: :integer}}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.load()
    end

    test "when enum is missing, ignores it" do
      assert %Schema{
               data: %{},
               is_valid?: true
             } =
               %{enum: enum([:call, :deploy, :message, :deposit])}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.load()
    end

    test "when list is missing, ignores it" do
      assert %Schema{
               data: %{},
               is_valid?: true
             } =
               %{list: list(:integer)}
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.load()
    end

    test "loads primitive type with options" do
      assert %Schema{
               data: %{"$__SCHEMA__": 42},
               is_valid?: true
             } =
               {:integer, default: 42}
               |> Schema.generate()
               |> Schema.new(nil)
               |> Schema.load()
    end

    test "loads $variable type" do
      data = %{
        "0" => "0x2a",
        "1" => "0x54"
      }

      assert %Schema{
               data: %{"0" => 42, "1" => 84},
               is_valid?: true
             } =
               %{"$variable": :loop}
               |> Schema.generate()
               |> Schema.new(data)
               |> Schema.load()
    end

    test "loads address type" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert %Schema{
               data: %{"$__SCHEMA__": ^address},
               is_valid?: true
             } =
               :address
               |> Schema.generate()
               |> Schema.new(address)
               |> Schema.load()

      assert %Schema{
               data: %{"$__SCHEMA__": ^address},
               is_valid?: true
             } =
               Icon.Schema.Types.Address
               |> Schema.generate()
               |> Schema.new(address)
               |> Schema.load()
    end

    test "loads address type in schema" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"
      params = %{"address" => address}

      assert %Schema{
               data: %{address: ^address},
               is_valid?: true
             } =
               %{address: :address}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
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
               |> Schema.load()
    end

    test "loads primitive any type" do
      data = "0x2a"

      assert %Schema{
               data: %{"$__SCHEMA__": ^data},
               is_valid?: true
             } =
               :any
               |> Schema.generate()
               |> Schema.new(data)
               |> Schema.load()

      assert %Schema{
               data: %{"$__SCHEMA__": ^data},
               is_valid?: true
             } =
               Icon.Schema.Types.Any
               |> Schema.generate()
               |> Schema.new(data)
               |> Schema.load()
    end

    test "loads primitive any type in schema" do
      data = "0x2a"
      params = %{"any" => data}

      assert %Schema{
               data: %{any: ^data},
               is_valid?: true
             } =
               %{any: :any}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "loads binary_data type" do
      binary_data = "ICON 2.0"

      assert %Schema{
               data: %{"$__SCHEMA__": ^binary_data},
               is_valid?: true
             } =
               :binary_data
               |> Schema.generate()
               |> Schema.new(binary_data)
               |> Schema.load()

      assert %Schema{
               data: %{"$__SCHEMA__": ^binary_data},
               is_valid?: true
             } =
               Icon.Schema.Types.BinaryData
               |> Schema.generate()
               |> Schema.new(binary_data)
               |> Schema.load()
    end

    test "loads binary_data type in schema" do
      binary_data = "ICON 2.0"
      params = %{"binary_data" => binary_data}

      assert %Schema{
               data: %{binary_data: ^binary_data},
               is_valid?: true
             } =
               %{binary_data: :binary_data}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
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
               |> Schema.load()
    end

    test "loads boolean type" do
      boolean = "0x1"

      assert %Schema{
               data: %{"$__SCHEMA__": true},
               is_valid?: true
             } =
               :boolean
               |> Schema.generate()
               |> Schema.new(boolean)
               |> Schema.load()

      assert %Schema{
               data: %{"$__SCHEMA__": true},
               is_valid?: true
             } =
               Icon.Schema.Types.Boolean
               |> Schema.generate()
               |> Schema.new(boolean)
               |> Schema.load()
    end

    test "loads boolean type in schema" do
      boolean = "0x1"
      params = %{"boolean" => boolean}

      assert %Schema{
               data: %{boolean: true},
               is_valid?: true
             } =
               %{boolean: :boolean}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
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
               |> Schema.load()
    end

    test "loads eoa_address type" do
      eoa_address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert %Schema{
               data: %{"$__SCHEMA__": ^eoa_address},
               is_valid?: true
             } =
               :eoa_address
               |> Schema.generate()
               |> Schema.new(eoa_address)
               |> Schema.load()

      assert %Schema{
               data: %{"$__SCHEMA__": ^eoa_address},
               is_valid?: true
             } =
               Icon.Schema.Types.EOA
               |> Schema.generate()
               |> Schema.new(eoa_address)
               |> Schema.load()
    end

    test "loads eoa_address type in schema" do
      eoa_address = "hxbe258ceb872e08851f1f59694dac2558708ece11"
      params = %{"eoa_address" => eoa_address}

      assert %Schema{
               data: %{eoa_address: ^eoa_address},
               is_valid?: true
             } =
               %{eoa_address: :eoa_address}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
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
               |> Schema.load()
    end

    test "loads error type" do
      error = %{
        "code" => -32_000,
        "message" => "Server error",
        "data" =>
          "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"
      }

      assert %Schema{
               data: %{
                 "$__SCHEMA__": %Error{
                   code: -32_000,
                   message: "Server error",
                   data:
                     "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
                   reason: :server_error,
                   domain: :request
                 }
               },
               is_valid?: true
             } =
               :error
               |> Schema.generate()
               |> Schema.new(error)
               |> Schema.load()

      assert %Schema{
               data: %{
                 "$__SCHEMA__": %Error{
                   code: -32_000,
                   message: "Server error",
                   data:
                     "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
                   reason: :server_error,
                   domain: :request
                 }
               },
               is_valid?: true
             } =
               Icon.Schema.Error
               |> Schema.generate()
               |> Schema.new(error)
               |> Schema.load()
    end

    test "loads error type in schema" do
      params = %{
        "error" => %{
          "code" => -32_000,
          "message" => "Server error",
          "data" =>
            "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"
        }
      }

      assert %Schema{
               data: %{
                 error: %Error{
                   code: -32_000,
                   message: "Server error",
                   data:
                     "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
                   reason: :server_error,
                   domain: :request
                 }
               },
               is_valid?: true
             } =
               %{error: :error}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "adds error when error type is invalid" do
      params = %{
        "error" => %{
          "code" => 1,
          "message" => "Server error"
        }
      }

      assert %Schema{
               errors: %{error: "is invalid"},
               is_valid?: false
             } =
               %{error: :error}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "loads event_log type" do
      event_log = %{
        "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        "indexed" => [
          "Transfer(Address,Address,int)",
          "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
          "hx2e243ad926ac48d15156756fce28314357d49d83"
        ],
        "data" => [
          "0x2a"
        ]
      }

      assert %Schema{
               data: %{
                 "$__SCHEMA__": %EventLog{
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
               },
               is_valid?: true
             } =
               :event_log
               |> Schema.generate()
               |> Schema.new(event_log)
               |> Schema.load()

      assert %Schema{
               data: %{
                 "$__SCHEMA__": %EventLog{
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
               },
               is_valid?: true
             } =
               Icon.Schema.Types.EventLog
               |> Schema.generate()
               |> Schema.new(event_log)
               |> Schema.load()
    end

    test "loads event_log type in schema" do
      params = %{
        "event_log" => %{
          "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
          "indexed" => [
            "Transfer(Address,Address,int)",
            "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
            "hx2e243ad926ac48d15156756fce28314357d49d83"
          ],
          "data" => [
            "0x2a"
          ]
        }
      }

      assert %Schema{
               data: %{
                 event_log: %EventLog{
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
               },
               is_valid?: true
             } =
               %{event_log: :event_log}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "adds error when event_log is invalid" do
      assert %Schema{
               errors: %{event_log: "is invalid"},
               is_valid?: false
             } =
               %{event_log: :event_log}
               |> Schema.generate()
               |> Schema.new(%{"event_log" => 42})
               |> Schema.load()
    end

    test "loads hash type" do
      hash =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      assert %Schema{
               data: %{"$__SCHEMA__": ^hash},
               is_valid?: true
             } =
               :hash
               |> Schema.generate()
               |> Schema.new(hash)
               |> Schema.load()

      assert %Schema{
               data: %{"$__SCHEMA__": ^hash},
               is_valid?: true
             } =
               Icon.Schema.Types.Hash
               |> Schema.generate()
               |> Schema.new(hash)
               |> Schema.load()
    end

    test "loads hash type in schema" do
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
               |> Schema.load()
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
               |> Schema.load()
    end

    test "loads integer type" do
      integer = "0x2a"

      assert %Schema{
               data: %{"$__SCHEMA__": 42},
               is_valid?: true
             } =
               :integer
               |> Schema.generate()
               |> Schema.new(integer)
               |> Schema.load()

      assert %Schema{
               data: %{"$__SCHEMA__": 42},
               is_valid?: true
             } =
               Icon.Schema.Types.Integer
               |> Schema.generate()
               |> Schema.new(integer)
               |> Schema.load()
    end

    test "loads integer type in schema" do
      params = %{"integer" => "0x2a"}

      assert %Schema{
               data: %{integer: 42},
               is_valid?: true
             } =
               %{integer: :integer}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
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
               |> Schema.load()
    end

    test "loads loop type" do
      loop = "0x2a"

      assert %Schema{
               data: %{"$__SCHEMA__": 42},
               is_valid?: true
             } =
               :loop
               |> Schema.generate()
               |> Schema.new(loop)
               |> Schema.load()

      assert %Schema{
               data: %{"$__SCHEMA__": 42},
               is_valid?: true
             } =
               Icon.Schema.Types.Loop
               |> Schema.generate()
               |> Schema.new(loop)
               |> Schema.load()
    end

    test "loads loop type in schema" do
      params = %{"loop" => "0x2a"}

      assert %Schema{
               data: %{loop: 42},
               is_valid?: true
             } =
               %{loop: :loop}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "adds error when loop is invalid" do
      params = %{"loop" => "INVALID"}

      assert %Schema{
               errors: %{loop: "is invalid"},
               is_valid?: false
             } =
               %{loop: :loop}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "loads neg_integer type" do
      neg_integer = "-0x2a"

      assert %Schema{
               data: %{"$__SCHEMA__": -42},
               is_valid?: true
             } =
               :neg_integer
               |> Schema.generate()
               |> Schema.new(neg_integer)
               |> Schema.load()

      assert %Schema{
               data: %{"$__SCHEMA__": -42},
               is_valid?: true
             } =
               Icon.Schema.Types.NegInteger
               |> Schema.generate()
               |> Schema.new(neg_integer)
               |> Schema.load()
    end

    test "loads neg_integer type in schema" do
      params = %{"neg_integer" => "-0x2a"}

      assert %Schema{
               data: %{neg_integer: -42},
               is_valid?: true
             } =
               %{neg_integer: :neg_integer}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "adds error when neg_integer is invalid" do
      params = %{"neg_integer" => "0x2a"}

      assert %Schema{
               errors: %{neg_integer: "is invalid"},
               is_valid?: false
             } =
               %{neg_integer: :neg_integer}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "loads pos_integer type" do
      pos_integer = "0x2a"

      assert %Schema{
               data: %{"$__SCHEMA__": 42},
               is_valid?: true
             } =
               :pos_integer
               |> Schema.generate()
               |> Schema.new(pos_integer)
               |> Schema.load()

      assert %Schema{
               data: %{"$__SCHEMA__": 42},
               is_valid?: true
             } =
               Icon.Schema.Types.PosInteger
               |> Schema.generate()
               |> Schema.new(pos_integer)
               |> Schema.load()
    end

    test "loads pos_integer type in schema" do
      params = %{"pos_integer" => "0x2a"}

      assert %Schema{
               data: %{pos_integer: 42},
               is_valid?: true
             } =
               %{pos_integer: :pos_integer}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "adds error when pos_integer is invalid" do
      params = %{"pos_integer" => "-0x2a"}

      assert %Schema{
               errors: %{pos_integer: "is invalid"},
               is_valid?: false
             } =
               %{pos_integer: :pos_integer}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "loads score_address type" do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert %Schema{
               data: %{"$__SCHEMA__": ^score_address},
               is_valid?: true
             } =
               :score_address
               |> Schema.generate()
               |> Schema.new(score_address)
               |> Schema.load()

      assert %Schema{
               data: %{"$__SCHEMA__": ^score_address},
               is_valid?: true
             } =
               Icon.Schema.Types.SCORE
               |> Schema.generate()
               |> Schema.new(score_address)
               |> Schema.load()
    end

    test "loads score_address type in schema" do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      params = %{"score_address" => score_address}

      assert %Schema{
               data: %{score_address: ^score_address},
               is_valid?: true
             } =
               %{score_address: :score_address}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
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
               |> Schema.load()
    end

    test "loads signature type" do
      signature =
        "VAia7YZ2Ji6igKWzjR2YsGa2m53nKPrfK7uXYW78QLE+ATehAVZPC40szvAiA6NEU5gCYB4c4qaQzqDh2ugcHgA="

      assert %Schema{
               data: %{"$__SCHEMA__": ^signature},
               is_valid?: true
             } =
               :signature
               |> Schema.generate()
               |> Schema.new(signature)
               |> Schema.load()

      assert %Schema{
               data: %{"$__SCHEMA__": ^signature},
               is_valid?: true
             } =
               Icon.Schema.Types.Signature
               |> Schema.generate()
               |> Schema.new(signature)
               |> Schema.load()
    end

    test "loads signature type in schema" do
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
               |> Schema.load()
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
               |> Schema.load()
    end

    test "loads string type" do
      string = "ICON 2.0"

      assert %Schema{
               data: %{"$__SCHEMA__": ^string},
               is_valid?: true
             } =
               :string
               |> Schema.generate()
               |> Schema.new(string)
               |> Schema.load()

      assert %Schema{
               data: %{"$__SCHEMA__": ^string},
               is_valid?: true
             } =
               Icon.Schema.Types.String
               |> Schema.generate()
               |> Schema.new(string)
               |> Schema.load()
    end

    test "loads string type in schema" do
      string = "ICON 2.0"
      params = %{"string" => string}

      assert %Schema{
               data: %{string: ^string},
               is_valid?: true
             } =
               %{string: :string}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
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
               |> Schema.load()
    end

    test "loads timestamp type" do
      timestamp = 1_639_653_259_594_958
      expected = DateTime.from_unix!(timestamp, :microsecond)

      assert %Schema{
               data: %{"$__SCHEMA__": ^expected},
               is_valid?: true
             } =
               :timestamp
               |> Schema.generate()
               |> Schema.new(timestamp)
               |> Schema.load()

      assert %Schema{
               data: %{"$__SCHEMA__": ^expected},
               is_valid?: true
             } =
               Icon.Schema.Types.Timestamp
               |> Schema.generate()
               |> Schema.new(timestamp)
               |> Schema.load()
    end

    test "loads timestamp type in schema" do
      timestamp = 1_639_653_259_594_958
      params = %{"timestamp" => timestamp}
      expected = DateTime.from_unix!(timestamp, :microsecond)

      assert %Schema{
               data: %{timestamp: ^expected},
               is_valid?: true
             } =
               %{timestamp: :timestamp}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "adds error when timestamp is invalid" do
      params = %{"timestamp" => -3_777_051_168_000_000_000}

      assert %Schema{
               errors: %{timestamp: "is invalid"},
               is_valid?: false
             } =
               %{timestamp: :timestamp}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "loads enum type" do
      assert %Schema{
               data: %{"$__SCHEMA__": :call},
               is_valid?: true
             } =
               [:call, :deploy, :message, :deposit]
               |> enum()
               |> Schema.generate()
               |> Schema.new("call")
               |> Schema.load()

      assert %Schema{
               data: %{"$__SCHEMA__": :call},
               is_valid?: true
             } =
               [:call, :deploy, :message, :deposit]
               |> enum()
               |> Schema.generate()
               |> Schema.new(:call)
               |> Schema.load()
    end

    test "loads enum type in schema as string" do
      params = %{"enum" => "call"}

      assert %Schema{
               data: %{enum: :call},
               is_valid?: true
             } =
               %{enum: enum([:call, :deploy, :message, :deposit])}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "loads enum type in schema as atom" do
      params = %{"enum" => :call}

      assert %Schema{
               data: %{enum: :call},
               is_valid?: true
             } =
               %{enum: enum([:call, :deploy, :message, :deposit])}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
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
               |> Schema.load()
    end

    test "enum values should be atoms" do
      values = ["call", "deploy", "message", "deposit"]
      schema = %{data_type: {:enum, values}}

      assert_raise ArgumentError, fn ->
        Schema.generate(schema)
      end
    end

    test "loads anonymous schema" do
      params = %{"schema" => %{"integer" => "0x2a"}}

      assert %Schema{
               data: %{schema: %{integer: 42}},
               is_valid?: true
             } =
               %{schema: %{integer: :integer}}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
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
               |> Schema.load()
    end

    test "loads a list" do
      list = ["0x2a", "0x2b"]

      assert %Schema{
               data: %{"$__SCHEMA__": [42, 43]},
               is_valid?: true
             } =
               :integer
               |> list()
               |> Schema.generate()
               |> Schema.new(list)
               |> Schema.load()
    end

    test "loads a list with primitive type in schemas" do
      params = %{"list" => ["0x2a", "0x2b"]}

      assert %Schema{
               data: %{list: [42, 43]},
               is_valid?: true
             } =
               %{list: list(:integer)}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "loads a list with enum type in schema" do
      params = %{"list" => ["call", "deploy"]}

      assert %Schema{
               data: %{list: [:call, :deploy]},
               is_valid?: true
             } =
               %{list: list(enum([:call, :deploy, :message, :deposit]))}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "raises when a list has any type" do
      params = %{
        "type" => "bool",
        "list" => ["0x0", "0x1"]
      }

      schema = %{
        type: enum([:int, :bool]),
        list: list(any([int: :integer, boo: :boolean], :type))
      }

      assert_raise ArgumentError, fn ->
        schema
        |> Schema.generate()
        |> Schema.new(params)
        |> Schema.load()
      end
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
               |> Schema.load()
    end

    test "raises when any type is used outside a schema" do
      assert_raise ArgumentError, fn ->
        [score: :score_address, eoa: :eoa_address]
        |> any(:type)
        |> Schema.generate()
      end
    end

    test "does nothing when field is not present and any is not required" do
      assert %Schema{
               data: %{},
               errors: errors,
               is_valid?: true
             } =
               %{
                 type: enum([:score, :eoa]),
                 address: any([score: :score_address, eoa: :eoa_address], :type)
               }
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.load()

      assert errors == %{}
    end

    test "errors when field is not present and any is required" do
      assert %Schema{
               errors: %{address: "is invalid"},
               is_valid?: false
             } =
               %{
                 type: enum([:score, :eoa]),
                 address: {
                   any([score: :score_address, eoa: :eoa_address], :type),
                   required: true
                 }
               }
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.load()
    end

    test "errors when field is nil" do
      assert %Schema{
               errors: %{address: "is invalid"},
               is_valid?: false
             } =
               %{
                 address: any([score: :score_address, eoa: :eoa_address], nil)
               }
               |> Schema.generate()
               |> Schema.new(%{})
               |> Schema.load()
    end

    test "loads any type in schema" do
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
                 address: any([score: :score_address, eoa: :eoa_address], :type)
               }
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
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
                 address: any([score: :score_address, eoa: :eoa_address], :type)
               }
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
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
                 address: any([score: :score_address, hash: :hash], :type)
               }
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "loads delegated module type in schema" do
      defmodule Int do
        use Icon.Schema.Type, delegate_to: Icon.Schema.Types.Integer
      end

      params = %{"integer" => "0x2a"}

      assert %Schema{
               data: %{integer: 42},
               is_valid?: true
             } =
               %{integer: Int}
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
    end

    test "loads module type in schema" do
      defmodule Bool do
        use Icon.Schema.Type

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
               |> Schema.load()
    end

    test "loads remote schema" do
      defmodule Remote do
        use Schema

        defschema(%{integer: :integer})
      end

      assert %Schema{
               data: %{schema: %{integer: 42}},
               is_valid?: true
             } =
               %{schema: Remote}
               |> Schema.generate()
               |> Schema.new(%{schema: %{integer: "0x2a"}})
               |> Schema.load()

      assert %Schema{
               data: %{integer: 42},
               is_valid?: true
             } =
               Remote
               |> Schema.generate()
               |> Schema.new(integer: "0x2a")
               |> Schema.load()
    end

    test "module type must be compiled" do
      assert_raise ArgumentError, fn ->
        Schema.generate(%{module: UnexistentModule})
      end

      assert_raise ArgumentError, fn ->
        Schema.generate(UnexistentModule)
      end
    end
  end

  describe "apply/1" do
    test "returns data when state is valid" do
      assert {:ok, 42} =
               :integer
               |> Schema.generate()
               |> Schema.new("0x2a")
               |> Schema.load()
               |> Schema.apply()
    end

    test "returns data when state is valid for a schema" do
      assert {:ok, %{integer: 42}} =
               %{integer: :integer}
               |> Schema.generate()
               |> Schema.new(integer: "0x2a")
               |> Schema.load()
               |> Schema.apply()
    end

    test "returns data in struct when state is valid in a schema" do
      defmodule Inner do
        use Schema

        defschema(%{
          loop: :loop
        })
      end

      defmodule Outer do
        use Schema

        defschema(%{
          required_integer: {:integer, required: true},
          required_enum: {enum([:foo, :bar]), required: true},
          required_list: {list(:boolean), required: true},
          required_schema: {Icon.Schema.LoaderTest.Inner, required: true},
          integer: :integer,
          enum: enum([:foo, :bar]),
          list: list(:boolean),
          schema: Icon.Schema.LoaderTest.Inner,
          anonymous: %{
            boolean: :boolean
          }
        })
      end

      params = %{
        "required_integer" => "0x2a",
        "required_enum" => "foo",
        "required_list" => ["0x1", "0x0"],
        "required_schema" => %{
          "loop" => "0x2a"
        },
        "integer" => "0x2b",
        "enum" => "bar",
        "list" => ["0x0", "0x1"],
        "schema" => %{
          "loop" => "0x2b"
        },
        "anonymous" => %{
          "boolean" => "0x1"
        }
      }

      assert {:ok,
              %{
                __struct__: Outer,
                required_integer: 42,
                required_enum: :foo,
                required_list: [true, false],
                required_schema: %{
                  __struct__: Inner,
                  loop: 42
                },
                integer: 43,
                enum: :bar,
                list: [false, true],
                schema: %{
                  __struct__: Inner,
                  loop: 43
                },
                anonymous: %{
                  boolean: true
                }
              }} =
               Outer
               |> Schema.generate()
               |> Schema.new(params)
               |> Schema.load()
               |> Schema.apply(into: Outer)
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
               |> Schema.load()
               |> Schema.apply()
    end
  end
end
