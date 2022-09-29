defmodule Icon.Schema.Types.NonPosIntegerTest do
  use ExUnit.Case, async: true

  alias Icon.Schema.Types.NonPosInteger

  describe "load/1" do
    test "when a non-positive integer is provided, returns said integer" do
      assert {:ok, -42} = NonPosInteger.load(-42)
      assert {:ok, 0} = NonPosInteger.load(-0)
      assert {:ok, 0} = NonPosInteger.load(0)
    end

    test "when a valid hex string is provided, returns the equivalent integer" do
      assert {:ok, -42} = NonPosInteger.load("-0x2A")
      assert {:ok, 0} = NonPosInteger.load("-0x0")
      assert {:ok, 0} = NonPosInteger.load("0x0")
    end

    test "when a valid integer string is provided, returns the equivalent integer" do
      assert {:ok, -42} = NonPosInteger.load("-42")
    end

    test "when positive integer is provided, errors" do
      assert :error = NonPosInteger.load(42)
      assert :error = NonPosInteger.load("0x2A")
      assert :error = NonPosInteger.load("0x2a")
      assert :error = NonPosInteger.load("42")
    end

    test "when an invalid hex string is provided, errors" do
      assert :error = NonPosInteger.load("0xINVALID")
    end

    test "when an invalid string is provided, errors" do
      assert :error = NonPosInteger.load("INVALID")
    end

    test "when an unsupported type is provided, errors" do
      assert :error = NonPosInteger.load(nil)
      assert :error = NonPosInteger.load(:atom)
      assert :error = NonPosInteger.load(%{})
      assert :error = NonPosInteger.load([])
    end
  end

  describe "dump/1" do
    test "when a non-positive integer is provided, returns the equivalent hex string" do
      assert {:ok, "-0x2a"} = NonPosInteger.dump(-42)
      assert {:ok, "0x0"} = NonPosInteger.dump(-0)
      assert {:ok, "0x0"} = NonPosInteger.dump(0)
    end

    test "when a positive integer is provided, errors" do
      assert :error = NonPosInteger.dump(42)
    end

    test "when an unsupported type is provided, errors" do
      assert :error = NonPosInteger.dump("0x2A")
      assert :error = NonPosInteger.dump("0x2a")
      assert :error = NonPosInteger.dump("42")
      assert :error = NonPosInteger.dump(nil)
      assert :error = NonPosInteger.dump(:atom)
      assert :error = NonPosInteger.dump(%{})
      assert :error = NonPosInteger.dump([])
    end
  end
end
