defmodule Icon.Types.SchemaTest do
  use ExUnit.Case, async: true

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

  describe "generate/1" do
    test "expands address type" do
      schema = %{address: :address}

      assert %{address: {Icon.Types.Address, []}} = Schema.generate(schema)
    end

    test "expands binary_data type" do
      schema = %{binary_data: :binary_data}

      assert %{binary_data: {Icon.Types.BinaryData, []}} =
               Schema.generate(schema)
    end

    test "expands boolean type" do
      schema = %{boolean: :boolean}

      assert %{boolean: {Icon.Types.Boolean, []}} = Schema.generate(schema)
    end

    test "expands eoa_address type" do
      schema = %{address: :eoa_address}

      assert %{address: {Icon.Types.EOA, []}} = Schema.generate(schema)
    end

    test "expands hash type" do
      schema = %{hash: :hash}

      assert %{hash: {Icon.Types.Hash, []}} = Schema.generate(schema)
    end

    test "expands integer type" do
      schema = %{integer: :integer}

      assert %{integer: {Icon.Types.Integer, []}} = Schema.generate(schema)
    end

    test "expands score_address type" do
      schema = %{address: :score_address}

      assert %{address: {Icon.Types.SCORE, []}} = Schema.generate(schema)
    end

    test "expands signature type" do
      schema = %{signature: :signature}

      assert %{signature: {Icon.Types.Signature, []}} = Schema.generate(schema)
    end

    test "expands string type" do
      schema = %{string: :string}

      assert %{string: {Icon.Types.String, []}} = Schema.generate(schema)
    end

    test "expands enum type" do
      values = [:call, :deploy, :message, :deposit]
      schema = %{data_type: {:enum, values}}

      assert %{data_type: {{:enum, ^values}, []}} = Schema.generate(schema)
    end

    test "enum values should be atoms" do
      values = ["call", "deploy", "message", "deposit"]
      schema = %{data_type: {:enum, values}}

      assert_raise ArgumentError, fn ->
        Schema.generate(schema)
      end
    end

    test "expands an inner schema" do
      schema = %{
        schema: %{
          address: :address
        }
      }

      assert %{
               schema: {
                 %{
                   address: {Icon.Types.Address, []}
                 },
                 []
               }
             } = Schema.generate(schema)
    end

    test "expands a list" do
      schema = %{list: {:list, :address}}

      assert %{list: {{:list, Icon.Types.Address}, []}} =
               Schema.generate(schema)
    end

    test "expands any type" do
      schema = %{any: {:any, [:eoa_address, :score_address]}}

      assert %{any: {{:any, [Icon.Types.EOA, Icon.Types.SCORE]}, []}} =
               Schema.generate(schema)
    end

    test "expands delegated module type" do
      defmodule Int do
        use Icon.Types.Schema.Type, delegate_to: Icon.Types.Integer
      end

      schema = %{int: Int}

      assert %{int: {Int, []}} = Schema.generate(schema)
    end

    test "expands module type" do
      defmodule Bool do
        use Icon.Types.Schema.Type

        def load(0), do: {:ok, false}
        def load(1), do: {:ok, true}
        def load(_), do: :error

        def dump(false), do: {:ok, 0}
        def dump(true), do: {:ok, 1}
        def dump(_), do: :error
      end

      schema = %{bool: Bool}

      assert %{bool: {Bool, []}} = Schema.generate(schema)
    end

    test "module type must be compiled" do
      schema = %{module: UnexistentModule}

      assert_raise ArgumentError, fn ->
        Schema.generate(schema)
      end
    end

    test "module type must be a schema or type" do
      schema = %{module: Enum}

      assert_raise ArgumentError, fn ->
        Schema.generate(schema)
      end
    end
  end
end
