defmodule Icon.Types.BooleanTest do
  use ExUnit.Case, async: true

  alias Icon.Types.Boolean

  describe "type/0" do
    test "it's a boolean" do
      assert :boolean = Boolean.type()
    end
  end

  describe "cast/1" do
    test "when a boolean is provided, returns said boolean" do
      assert {:ok, true} = Boolean.cast(true)
      assert {:ok, false} = Boolean.cast(false)
    end

    test "when a valid hex string is provided, returns the equivalent boolean" do
      assert {:ok, false} = Boolean.cast("0x0")
      assert {:ok, true} = Boolean.cast("0x1")
    end

    test "when an invalid hex string is provided, errors" do
      assert :error = Boolean.cast("0x2A")
    end

    test "when an unsupported type is provided, errors" do
      assert :error = Boolean.cast("")
      assert :error = Boolean.cast(42)
      assert :error = Boolean.cast(nil)
      assert :error = Boolean.cast(:atom)
      assert :error = Boolean.cast(%{})
      assert :error = Boolean.cast([])
    end
  end

  describe "load/1" do
    test "when a valid hex is provided, returns the equivalent boolean" do
      assert {:ok, false} = Boolean.load("0x0")
      assert {:ok, true} = Boolean.load("0x1")
    end

    test "when an unsupported type is provided, errors" do
      assert :error = Boolean.load("")
      assert :error = Boolean.load("0x2A")
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
