defmodule Icon.Schema.Types.NegIntegerTest do
  use ExUnit.Case, async: true

  alias Icon.Schema.Types.NegInteger

  describe "load/1" do
    test "when a negative integer is provided, returns said integer" do
      assert {:ok, -42} = NegInteger.load(-42)
    end

    test "when a valid hex string is provided, returns the equivalent integer" do
      assert {:ok, -42} = NegInteger.load("-0x2A")
      assert {:ok, -42} = NegInteger.load("-0x2a")
    end

    test "when a valid integer string is provided, returns the equivalent integer" do
      assert {:ok, -42} = NegInteger.load("-42")
    end

    test "when positive integer is provided, errors" do
      assert :error = NegInteger.load(42)
      assert :error = NegInteger.load("0x2A")
      assert :error = NegInteger.load("0x2a")
      assert :error = NegInteger.load("42")
    end

    test "when zero is provided, errors" do
      assert :error = NegInteger.load(0)
      assert :error = NegInteger.load("0x0")
      assert :error = NegInteger.load("0")
    end

    test "when an invalid hex string is provided, errors" do
      assert :error = NegInteger.load("0xINVALID")
    end

    test "when an invalid string is provided, errors" do
      assert :error = NegInteger.load("INVALID")
    end

    test "when an unsupported type is provided, errors" do
      assert :error = NegInteger.load(nil)
      assert :error = NegInteger.load(:atom)
      assert :error = NegInteger.load(%{})
      assert :error = NegInteger.load([])
    end
  end

  describe "dump/1" do
    test "when a negative integer is provided, returns the equivalent hex string" do
      assert {:ok, "-0x2a"} = NegInteger.dump(-42)
    end

    test "when a positive integer is provided, errors" do
      assert :error = NegInteger.dump(42)
    end

    test "when a zero is provided, errors" do
      assert :error = NegInteger.dump(0)
    end

    test "when an unsupported type is provided, errors" do
      assert :error = NegInteger.dump("0x2A")
      assert :error = NegInteger.dump("0x2a")
      assert :error = NegInteger.dump("42")
      assert :error = NegInteger.dump(nil)
      assert :error = NegInteger.dump(:atom)
      assert :error = NegInteger.dump(%{})
      assert :error = NegInteger.dump([])
    end
  end
end
