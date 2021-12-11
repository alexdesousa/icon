defmodule Icon.Types.BinaryDataTest do
  use ExUnit.Case, async: true

  alias Icon.Types.BinaryData

  describe "type/0" do
    test "it's a string" do
      assert :string = BinaryData.type()
    end
  end

  describe "cast/1" do
    test "when it's a valid binary, returns said binary" do
      binary = "0x34b2"

      assert {:ok, ^binary} = BinaryData.cast(binary)
    end

    test "when there are capital letters in the binary, returns them as lowercase" do
      binary = "0x34B2"
      expected = "0x34b2"

      assert {:ok, ^expected} = BinaryData.cast(binary)
    end

    test "when the binary is too short, errors" do
      binary = "0x0"

      assert :error = BinaryData.cast(binary)
    end

    test "when the binary is doesn't have even length, errors" do
      binary = "0x000"

      assert :error = BinaryData.cast(binary)
    end

    test "when it's not a valid binary, errors" do
      assert :error = BinaryData.cast(42)
      assert :error = BinaryData.cast(nil)
      assert :error = BinaryData.cast(:atom)
      assert :error = BinaryData.cast("")
      assert :error = BinaryData.cast(%{})
      assert :error = BinaryData.cast([])
    end
  end

  describe "load/1" do
    test "delegates EOA binaryes to cast/1" do
      binary = "0x34b2"

      assert BinaryData.load(binary) == BinaryData.cast(binary)
    end
  end

  describe "dump/1" do
    test "delegates to cast/1" do
      binary = "0x34b2"

      assert BinaryData.dump(binary) == BinaryData.cast(binary)
    end
  end
end
