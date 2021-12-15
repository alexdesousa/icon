defmodule Icon.Types.IntegerTest do
  use ExUnit.Case, async: true

  describe "load/1" do
    test "when an integer is provided, returns said integer" do
      assert {:ok, 42} = Icon.Types.Integer.load(42)
    end

    test "when a valid hex string is provided, returns the equivalent integer" do
      assert {:ok, 42} = Icon.Types.Integer.load("0x2A")
      assert {:ok, 42} = Icon.Types.Integer.load("0x2a")
    end

    test "when a valid integer string is provided, returns the equivalent integer" do
      assert {:ok, 42} = Icon.Types.Integer.load("42")
    end

    test "when an integer is negative, errors" do
      assert :error = Icon.Types.Integer.load(-42)
    end

    test "when an invalid hex string is provided, errors" do
      assert :error = Icon.Types.Integer.load("0xINVALID")
    end

    test "when an invalid string is provided, errors" do
      assert :error = Icon.Types.Integer.load("INVALID")
    end

    test "when an unsupported type is provided, errors" do
      assert :error = Icon.Types.Integer.load(nil)
      assert :error = Icon.Types.Integer.load(:atom)
      assert :error = Icon.Types.Integer.load(%{})
      assert :error = Icon.Types.Integer.load([])
    end
  end

  describe "dump/1" do
    test "when an integer is provided, returns the equivalent hex string" do
      assert {:ok, "0x2a"} = Icon.Types.Integer.dump(42)
    end

    test "when an integer is negative, errors" do
      assert :error = Icon.Types.Integer.dump(-42)
    end

    test "when an unsupported type is provided, errors" do
      assert :error = Icon.Types.Integer.dump("0x2A")
      assert :error = Icon.Types.Integer.dump("0x2a")
      assert :error = Icon.Types.Integer.dump("42")
      assert :error = Icon.Types.Integer.dump(nil)
      assert :error = Icon.Types.Integer.dump(:atom)
      assert :error = Icon.Types.Integer.dump(%{})
      assert :error = Icon.Types.Integer.dump([])
    end
  end
end
