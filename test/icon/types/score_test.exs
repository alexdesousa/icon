defmodule Icon.Types.SCORETest do
  use ExUnit.Case, async: true

  alias Icon.Types.SCORE

  describe "load/1" do
    test "when it's a valid SCORE address, returns said address" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {:ok, ^address} = SCORE.load(address)
    end

    test "when there are capital letters in the address, returns them as lowercase" do
      address = "cxB0776EE37F5B45BFAEA8CFF1D8232FBB6122EC32"
      expected = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {:ok, ^expected} = SCORE.load(address)
    end

    test "when the address is too short, errors" do
      address = "cx0"

      assert :error = SCORE.load(address)
    end

    test "when the address is too long, errors" do
      address = "cx000000000000000000000000000000000000000000"

      assert :error = SCORE.load(address)
    end

    test "when it's not a valid address, errors" do
      assert :error = SCORE.load(42)
      assert :error = SCORE.load(nil)
      assert :error = SCORE.load(:atom)
      assert :error = SCORE.load("")
      assert :error = SCORE.load(%{})
      assert :error = SCORE.load([])
    end
  end

  describe "dump/1" do
    test "delegates to load/1" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert SCORE.dump(address) == SCORE.load(address)
    end
  end
end
