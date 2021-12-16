defmodule Icon.Schema.Types.AddressTest do
  use ExUnit.Case, async: true

  alias Icon.Schema.Types.Address

  describe "load/1" do
    test "when it's a valid EOA address, returns said address" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert {:ok, ^address} = Address.load(address)
    end

    test "when it's a valid SCORE address, returns said address" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {:ok, ^address} = Address.load(address)
    end

    test "when there are capital letters in the address, returns them as lowercase" do
      address = "hxBE258CEB872E08851F1F59694DAC2558708ECE11"
      expected = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert {:ok, ^expected} = Address.load(address)
    end

    test "when the address is too short, errors" do
      address = "hx0"

      assert :error = Address.load(address)
    end

    test "when the address is too long, errors" do
      address = "hx000000000000000000000000000000000000000000"

      assert :error = Address.load(address)
    end

    test "when it's not a valid address, errors" do
      assert :error = Address.load(42)
      assert :error = Address.load(nil)
      assert :error = Address.load(:atom)
      assert :error = Address.load("")
      assert :error = Address.load(%{})
      assert :error = Address.load([])
    end
  end

  describe "dump/1" do
    test "delegates EOA address to load/1" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert Address.dump(address) == Address.load(address)
    end

    test "delegates SCORE address to load/1" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert Address.dump(address) == Address.load(address)
    end
  end
end
