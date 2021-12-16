defmodule Icon.Schema.Types.BooleanTest do
  use ExUnit.Case, async: true

  alias Icon.Schema.Types.Boolean

  describe "load/1" do
    test "when an integer is provided, returns the equivalent boolean" do
      assert {:ok, false} = Boolean.load(0)
      assert {:ok, true} = Boolean.load(1)
    end

    test "when a boolean is provided, returns said boolean" do
      assert {:ok, false} = Boolean.load(false)
      assert {:ok, true} = Boolean.load(true)
    end

    test "when a valid hex string is provided, returns the equivalent boolean" do
      assert {:ok, false} = Boolean.load("0x0")
      assert {:ok, true} = Boolean.load("0x1")
    end

    test "when an invalid hex string is provided, errors" do
      assert :error = Boolean.load("0x2A")
    end

    test "when an unsupported type is provided, errors" do
      assert :error = Boolean.load("")
      assert :error = Boolean.load(42)
      assert :error = Boolean.load(nil)
      assert :error = Boolean.load(:atom)
      assert :error = Boolean.load(%{})
      assert :error = Boolean.load([])
    end
  end

  describe "dump/1" do
    test "when a boolean is provided, returns the equivalent hex string" do
      assert {:ok, "0x0"} = Boolean.dump(false)
      assert {:ok, "0x1"} = Boolean.dump(true)
    end

    test "when an unsupported type is provided, errors" do
      assert :error = Boolean.dump("")
      assert :error = Boolean.dump(42)
      assert :error = Boolean.dump(nil)
      assert :error = Boolean.dump(:atom)
      assert :error = Boolean.dump(%{})
      assert :error = Boolean.dump([])
    end
  end
end
