defmodule Icon.Types.BinaryDataTest do
  use ExUnit.Case, async: true

  alias Icon.Types.BinaryData

  describe "load/1" do
    test "when it's a valid binary, returns said binary" do
      binary = "0x34b2"

      assert {:ok, ^binary} = BinaryData.load(binary)
    end

    test "when there are capital letters in the binary, returns them as lowercase" do
      binary = "0x34B2"
      expected = "0x34b2"

      assert {:ok, ^expected} = BinaryData.load(binary)
    end

    test "when the binary is too short, errors" do
      binary = "0x0"

      assert :error = BinaryData.load(binary)
    end

    test "when the binary is doesn't have even length, errors" do
      binary = "0x000"

      assert :error = BinaryData.load(binary)
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
    test "delegates to load/1" do
      binary = "0x34b2"

      assert BinaryData.dump(binary) == BinaryData.load(binary)
    end
  end
end
