defmodule Icon.Types.HashTest do
  use ExUnit.Case, async: true

  alias Icon.Types.Hash

  describe "load/1" do
    test "when it's a valid hash, returns said hash" do
      hash =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      assert {:ok, ^hash} = Hash.load(hash)
    end

    test "when it doesn't have the 0x prefix, adds it" do
      hash = "c71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      expected =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      assert {:ok, ^expected} = Hash.load(hash)
    end

    test "when there are capital letters in the hash, returns them as lowercase" do
      hash =
        "0xC71303EF8543D04B5DC1BA6579132B143087C68DB1B2168786408FCBCE568238"

      expected =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      assert {:ok, ^expected} = Hash.load(hash)
    end

    test "when the hash is too short, errors" do
      hash = "0x0"

      assert :error = Hash.load(hash)
    end

    test "when the hash is too long, errors" do
      hash =
        "0x000000000000000000000000000000000000000000000000000000000000000000"

      assert :error = Hash.load(hash)
    end

    test "when it's not a valid hash, errors" do
      assert :error = Hash.load(42)
      assert :error = Hash.load(nil)
      assert :error = Hash.load(:atom)
      assert :error = Hash.load("")
      assert :error = Hash.load(%{})
      assert :error = Hash.load([])
    end
  end

  describe "dump/1" do
    test "delegates to load/1" do
      hash =
        "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"

      assert Hash.dump(hash) == Hash.load(hash)
    end
  end
end
