defmodule Icon.Schema.Types.StringTest do
  use ExUnit.Case, async: true

  describe "load/1" do
    test "when it's a string, returns said string" do
      assert {:ok, "ICON 2.0"} = Icon.Schema.Types.String.load("ICON 2.0")
    end

    test "when it's not a string, errors" do
      assert :error = Icon.Schema.Types.String.load(42)
      assert :error = Icon.Schema.Types.String.load(nil)
      assert :error = Icon.Schema.Types.String.load(:atom)
      assert :error = Icon.Schema.Types.String.load(%{})
      assert :error = Icon.Schema.Types.String.load([])
    end
  end

  describe "dump/1" do
    test "delegates to load/1" do
      str = "ICON 2.0"

      assert Icon.Schema.Types.String.dump(str) ==
               Icon.Schema.Types.String.load(str)
    end
  end
end
