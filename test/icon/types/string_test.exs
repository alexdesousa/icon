defmodule Icon.Types.StringTest do
  use ExUnit.Case, async: true

  describe "type/0" do
    test "it's a string" do
      assert :string = Icon.Types.String.type()
    end
  end

  describe "cast/1" do
    test "when it's a string, returns said string" do
      assert {:ok, "ICON 2.0"} = Icon.Types.String.cast("ICON 2.0")
    end

    test "when it's not a string, errors" do
      assert :error = Icon.Types.String.cast(42)
      assert :error = Icon.Types.String.cast(nil)
      assert :error = Icon.Types.String.cast(:atom)
      assert :error = Icon.Types.String.cast(%{})
      assert :error = Icon.Types.String.cast([])
    end
  end

  describe "load/1" do
    test "delegates to cast/1" do
      str = "ICON 2.0"

      assert Icon.Types.String.load(str) == Icon.Types.String.cast(str)
    end
  end

  describe "dump/1" do
    test "delegates to cast/1" do
      str = "ICON 2.0"

      assert Icon.Types.String.dump(str) == Icon.Types.String.cast(str)
    end
  end
end
