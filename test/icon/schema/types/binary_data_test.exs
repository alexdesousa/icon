defmodule Icon.Schema.Types.BinaryDataTest do
  use ExUnit.Case, async: true

  alias Icon.Schema.Types.BinaryData

  describe "load/1" do
    test "when it's a valid binary data, returns the decoded binary" do
      assert {:ok, "ICON 2.0"} = BinaryData.load("0x49434f4e20322e30")
    end

    test "when it's a valid binary, returns said binary" do
      assert {:ok, "ICON 2.0"} = BinaryData.load("ICON 2.0")
    end

    test "when it's not a valid binary, errors" do
      assert :error = BinaryData.load(42)
      assert :error = BinaryData.load(nil)
      assert :error = BinaryData.load(:atom)
      assert :error = BinaryData.load("")
      assert :error = BinaryData.load(%{})
      assert :error = BinaryData.load([])
    end
  end

  describe "dump/1" do
    test "converts a binary into the binary data representation" do
      assert {:ok, "0x49434f4e20322e30"} = BinaryData.dump("ICON 2.0")
    end

    test "when it's not a valid binary, errors" do
      assert :error = BinaryData.dump(42)
      assert :error = BinaryData.dump(nil)
      assert :error = BinaryData.dump(:atom)
      assert :error = BinaryData.dump("")
      assert :error = BinaryData.dump(%{})
      assert :error = BinaryData.dump([])
    end
  end
end
