defmodule Icon.Schema.Types.NonNegIntegerTest do
  use ExUnit.Case, async: true

  alias Icon.Schema.Types.NonNegInteger

  describe "load/1" do
    test "when a non-negative integer is provided, returns said integer" do
      assert {:ok, 42} = NonNegInteger.load(42)
      assert {:ok, 0} = NonNegInteger.load(0)
      assert {:ok, 0} = NonNegInteger.load(-0)
    end

    test "when a valid hex string is provided, returns the equivalent integer" do
      assert {:ok, 42} = NonNegInteger.load("0x2A")
      assert {:ok, 42} = NonNegInteger.load("0x2a")
      assert {:ok, 0} = NonNegInteger.load("0x0")
      assert {:ok, 0} = NonNegInteger.load("-0x0")
    end

    test "when a valid integer string is provided, returns the equivalent integer" do
      assert {:ok, 42} = NonNegInteger.load("42")
      assert {:ok, 0} = NonNegInteger.load("0")
      assert {:ok, 0} = NonNegInteger.load("-0")
    end

    test "when negative integer is provided, errors" do
      assert :error = NonNegInteger.load(-42)
      assert :error = NonNegInteger.load("-0x2A")
      assert :error = NonNegInteger.load("-0x2a")
      assert :error = NonNegInteger.load("-42")
    end

    test "when an invalid hex string is provided, errors" do
      assert :error = NonNegInteger.load("0xINVALID")
    end

    test "when an invalid string is provided, errors" do
      assert :error = NonNegInteger.load("INVALID")
    end

    test "when an unsupported type is provided, errors" do
      assert :error = NonNegInteger.load(nil)
      assert :error = NonNegInteger.load(:atom)
      assert :error = NonNegInteger.load(%{})
      assert :error = NonNegInteger.load([])
    end
  end

  describe "dump/1" do
    test "when a non-negative integer is provided, returns the equivalent hex string" do
      assert {:ok, "0x2a"} = NonNegInteger.dump(42)
      assert {:ok, "0x0"} = NonNegInteger.dump(0)
      assert {:ok, "0x0"} = NonNegInteger.dump(-0)
    end

    test "when a negative integer is provided, errors" do
      assert :error = NonNegInteger.dump(-42)
    end

    test "when an unsupported type is provided, errors" do
      assert :error = NonNegInteger.dump("0x2A")
      assert :error = NonNegInteger.dump("0x2a")
      assert :error = NonNegInteger.dump("42")
      assert :error = NonNegInteger.dump(nil)
      assert :error = NonNegInteger.dump(:atom)
      assert :error = NonNegInteger.dump(%{})
      assert :error = NonNegInteger.dump([])
    end
  end
end
