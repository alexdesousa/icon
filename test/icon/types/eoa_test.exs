defmodule Icon.Types.EOATest do
  use ExUnit.Case, async: true

  alias Icon.Types.EOA

  describe "type/0" do
    test "it's a string" do
      assert :string = EOA.type()
    end
  end

  describe "cast/1" do
    test "when it's a valid EOA address, returns said address" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert {:ok, ^address} = EOA.cast(address)
    end

    test "when there are capital letters in the address, returns them as lowercase" do
      address = "hxBE258CEB872E08851F1F59694DAC2558708ECE11"
      expected = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert {:ok, ^expected} = EOA.cast(address)
    end

    test "when the address is too short, errors" do
      address = "hx0"

      assert :error = EOA.cast(address)
    end

    test "when the address is too long, errors" do
      address = "hx000000000000000000000000000000000000000000"

      assert :error = EOA.cast(address)
    end

    test "when it's not a valid address, errors" do
      assert :error = EOA.cast(42)
      assert :error = EOA.cast(nil)
      assert :error = EOA.cast(:atom)
      assert :error = EOA.cast("")
      assert :error = EOA.cast(%{})
      assert :error = EOA.cast([])
    end
  end

  describe "load/1" do
    test "delegates to cast/1" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert EOA.load(address) == EOA.cast(address)
    end
  end

  describe "dump/1" do
    test "delegates to cast/1" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert EOA.dump(address) == EOA.cast(address)
    end
  end
end
