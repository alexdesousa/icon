defmodule Icon.Types.HashTest do
  use ExUnit.Case, async: true

  alias Icon.Types.Hash

  describe "type/0" do
    test "it's a string" do
      assert :string = Hash.type()
    end
  end

  describe "cast/1" do
    test "when it's a valid hash, returns said hash" do
      hash =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      assert {:ok, ^hash} = Hash.cast(hash)
    end

    test "when it doesn't have the 0x prefix, adds it" do
      hash = "c71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      expected =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      assert {:ok, ^expected} = Hash.cast(hash)
    end

    test "when there are capital letters in the hash, returns them as lowercase" do
      hash =
        "0xC71303EF8543D04B5DC1BA6579132B143087C68DB1B2168786408FCBCE568238"

      expected =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      assert {:ok, ^expected} = Hash.cast(hash)
    end

    test "when the hash is too short, errors" do
      hash = "0x0"

      assert :error = Hash.cast(hash)
    end

    test "when the hash is too long, errors" do
      hash =
        "0x000000000000000000000000000000000000000000000000000000000000000000"

      assert :error = Hash.cast(hash)
    end

    test "when it's not a valid hash, errors" do
      assert :error = Hash.cast(42)
      assert :error = Hash.cast(nil)
      assert :error = Hash.cast(:atom)
      assert :error = Hash.cast("")
      assert :error = Hash.cast(%{})
      assert :error = Hash.cast([])
    end
  end

  describe "load/1" do
    test "delegates to cast/1" do
      hash =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      assert Hash.load(hash) == Hash.cast(hash)
    end
  end

  describe "dump/1" do
    test "delegates to cast/1" do
      hash =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      assert Hash.dump(hash) == Hash.cast(hash)
    end
  end
end
