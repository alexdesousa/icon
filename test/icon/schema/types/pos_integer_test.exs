defmodule Icon.Schema.Types.PosIntegerTest do
  use ExUnit.Case, async: true

  alias Icon.Schema.Types.PosInteger

  describe "load/1" do
    test "when a positive integer is provided, returns said integer" do
      assert {:ok, 42} = PosInteger.load(42)
    end

    test "when a valid hex string is provided, returns the equivalent integer" do
      assert {:ok, 42} = PosInteger.load("0x2A")
      assert {:ok, 42} = PosInteger.load("0x2a")
    end

    test "when a valid integer string is provided, returns the equivalent integer" do
      assert {:ok, 42} = PosInteger.load("42")
    end

    test "when negative integer is provided, errors" do
      assert :error = PosInteger.load(-42)
      assert :error = PosInteger.load("-0x2A")
      assert :error = PosInteger.load("-0x2a")
      assert :error = PosInteger.load("-42")
    end

    test "when zero is provided, errors" do
      assert :error = PosInteger.load(0)
      assert :error = PosInteger.load("0x0")
      assert :error = PosInteger.load("0")
    end

    test "when an invalid hex string is provided, errors" do
      assert :error = PosInteger.load("0xINVALID")
    end

    test "when an invalid string is provided, errors" do
      assert :error = PosInteger.load("INVALID")
    end

    test "when an unsupported type is provided, errors" do
      assert :error = PosInteger.load(nil)
      assert :error = PosInteger.load(:atom)
      assert :error = PosInteger.load(%{})
      assert :error = PosInteger.load([])
    end
  end

  describe "dump/1" do
    test "when a positive integer is provided, returns the equivalent hex string" do
      assert {:ok, "0x2a"} = PosInteger.dump(42)
    end

    test "when a negative integer is provided, errors" do
      assert :error = PosInteger.dump(-42)
    end

    test "when a zero is provided, errors" do
      assert :error = PosInteger.dump(0)
    end

    test "when an unsupported type is provided, errors" do
      assert :error = PosInteger.dump("0x2A")
      assert :error = PosInteger.dump("0x2a")
      assert :error = PosInteger.dump("42")
      assert :error = PosInteger.dump(nil)
      assert :error = PosInteger.dump(:atom)
      assert :error = PosInteger.dump(%{})
      assert :error = PosInteger.dump([])
    end
  end
end
