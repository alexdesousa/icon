defmodule Icon.Schema.TypeTest do
  use ExUnit.Case, async: true

  alias Icon.Schema.Type

  describe "delegated module" do
    defmodule Int do
      use Type, delegate_to: Icon.Schema.Types.Integer
    end

    test "delegates to other module" do
      assert function_exported?(Int, :load, 1)
      assert function_exported?(Int, :dump, 1)
    end

    test "raises when delegates to unexistent module" do
      assert_raise ArgumentError, fn ->
        defmodule Invalid do
          use Type, delegate_to: Unexistent
        end
      end
    end
  end

  describe "non delegated module" do
    defmodule Bool do
      use Type

      @impl Type
      def load(0), do: {:ok, false}
      def load(1), do: {:ok, true}
      def load(_), do: :error

      @impl Type
      def dump(false), do: {:ok, 0}
      def dump(true), do: {:ok, 1}
      def dump(_), do: :error
    end

    test "has implemented functions" do
      assert function_exported?(Bool, :load, 1)
      assert function_exported?(Bool, :dump, 1)
    end
  end

  describe "load/2" do
    test "loads a value by module" do
      assert {:ok, 42} = Type.load(Icon.Schema.Types.Integer, "0x2a")
    end

    test "when value cannot be loaded, errors" do
      assert :error = Type.load(Icon.Schema.Types.Integer, nil)
    end
  end

  describe "load!/2" do
    test "loads a value by module" do
      assert 42 = Type.load!(Icon.Schema.Types.Integer, "0x2a")
    end

    test "when value cannot be loaded, raises" do
      assert_raise ArgumentError, fn ->
        Type.load!(Icon.Schema.Types.Integer, nil)
      end
    end
  end

  describe "dump/2" do
    test "dumps a value by module" do
      assert {:ok, "0x2a"} = Type.dump(Icon.Schema.Types.Integer, 42)
    end

    test "when value cannot be dumped, errors" do
      assert :error = Type.dump(Icon.Schema.Types.Integer, nil)
    end
  end

  describe "dump!/2" do
    test "dumps a value by module" do
      assert "0x2a" = Type.dump!(Icon.Schema.Types.Integer, 42)
    end

    test "when value cannot be dumped, raises" do
      assert_raise ArgumentError, fn ->
        Type.dump!(Icon.Schema.Types.Integer, nil)
      end
    end
  end

  describe "to_atom_map/1" do
    test "converts from a map with binary keys to a map with atom keys" do
      assert %{key: 42} = Type.to_atom_map(%{"key" => 42})
    end

    test "converts nested maps" do
      assert %{outer: %{inner: 42}} =
               Type.to_atom_map(%{"outer" => %{"inner" => 42}})
    end

    test "converts maps inside lists" do
      assert %{list: [%{key: 42}]} =
               Type.to_atom_map(%{"list" => [%{"key" => 42}]})
    end

    test "does nothing to keys if they are atoms" do
      assert %{key: 42} = Type.to_atom_map(%{key: 42})
    end
  end
end
