defmodule Icon.Types.Schema.TypeTest do
  use ExUnit.Case, async: true

  alias Icon.Types.Schema.Type

  describe "delegated module" do
    defmodule Int do
      use Type, delegate_to: Icon.Types.Integer
    end

    test "delegates to other module" do
      assert function_exported?(Int, :load, 1)
      assert function_exported?(Int, :dump, 1)
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
end
