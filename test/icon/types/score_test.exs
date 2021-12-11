defmodule Icon.Types.SCORETest do
  use ExUnit.Case, async: true

  alias Icon.Types.SCORE

  describe "type/0" do
    test "it's a string" do
      assert :string = SCORE.type()
    end
  end

  describe "cast/1" do
    test "when it's a valid SCORE address, returns said address" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {:ok, ^address} = SCORE.cast(address)
    end

    test "when there are capital letters in the address, returns them as lowercase" do
      address = "cxB0776EE37F5B45BFAEA8CFF1D8232FBB6122EC32"
      expected = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert {:ok, ^expected} = SCORE.cast(address)
    end

    test "when the address is too short, errors" do
      address = "cx0"

      assert :error = SCORE.cast(address)
    end

    test "when the address is too long, errors" do
      address = "cx000000000000000000000000000000000000000000"

      assert :error = SCORE.cast(address)
    end

    test "when it's not a valid address, errors" do
      assert :error = SCORE.cast(42)
      assert :error = SCORE.cast(nil)
      assert :error = SCORE.cast(:atom)
      assert :error = SCORE.cast("")
      assert :error = SCORE.cast(%{})
      assert :error = SCORE.cast([])
    end
  end

  describe "load/1" do
    test "delegates to cast/1" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert SCORE.load(address) == SCORE.cast(address)
    end
  end

  describe "dump/1" do
    test "delegates to cast/1" do
      address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      assert SCORE.dump(address) == SCORE.cast(address)
    end
  end
end
