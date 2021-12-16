defmodule Icon.Schema.Types.EOATest do
  use ExUnit.Case, async: true

  alias Icon.Schema.Types.EOA

  describe "load/1" do
    test "when it's a valid EOA address, returns said address" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert {:ok, ^address} = EOA.load(address)
    end

    test "when there are capital letters in the address, returns them as lowercase" do
      address = "hxBE258CEB872E08851F1F59694DAC2558708ECE11"
      expected = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert {:ok, ^expected} = EOA.load(address)
    end

    test "when the address is too short, errors" do
      address = "hx0"

      assert :error = EOA.load(address)
    end

    test "when the address is too long, errors" do
      address = "hx000000000000000000000000000000000000000000"

      assert :error = EOA.load(address)
    end

    test "when it's not a valid address, errors" do
      assert :error = EOA.load(42)
      assert :error = EOA.load(nil)
      assert :error = EOA.load(:atom)
      assert :error = EOA.load("")
      assert :error = EOA.load(%{})
      assert :error = EOA.load([])
    end
  end

  describe "dump/1" do
    test "delegates to load/1" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert EOA.dump(address) == EOA.load(address)
    end
  end
end
