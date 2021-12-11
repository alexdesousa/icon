defmodule Icon.Types.AddressTest do
  use ExUnit.Case, async: true

  alias Icon.Types.Address

  describe "type/0" do
    test "it's a string" do
      assert :string = Address.type()
    end
  end

  describe "cast/1" do
    test "when it's a valid EOA address, returns said address" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert {:ok, ^address} = Address.cast(address)
    end

    test "when it's a valid SCORE address, returns said address" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {:ok, ^address} = Address.cast(address)
    end

    test "when there are capital letters in the address, returns them as lowercase" do
      address = "hxBE258CEB872E08851F1F59694DAC2558708ECE11"
      expected = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert {:ok, ^expected} = Address.cast(address)
    end

    test "when the address is too short, errors" do
      address = "hx0"

      assert :error = Address.cast(address)
    end

    test "when the address is too long, errors" do
      address = "hx000000000000000000000000000000000000000000"

      assert :error = Address.cast(address)
    end

    test "when it's not a valid address, errors" do
      assert :error = Address.cast(42)
      assert :error = Address.cast(nil)
      assert :error = Address.cast(:atom)
      assert :error = Address.cast("")
      assert :error = Address.cast(%{})
      assert :error = Address.cast([])
    end
  end

  describe "load/1" do
    test "delegates EOA addresses to cast/1" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert Address.load(address) == Address.cast(address)
    end

    test "delegates SCORE addresses to cast/1" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert Address.load(address) == Address.cast(address)
    end
  end

  describe "dump/1" do
    test "delegates to cast/1" do
      address = "hxbe258ceb872e08851f1f59694dac2558708ece11"

      assert Address.dump(address) == Address.cast(address)
    end

    test "delegates SCORE addresses to cast/1" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert Address.dump(address) == Address.cast(address)
    end
  end
end
