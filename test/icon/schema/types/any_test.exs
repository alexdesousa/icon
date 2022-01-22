defmodule Icon.Schema.Types.AnyTest do
  use ExUnit.Case, async: true

  alias Icon.Schema.Types.Any

  describe "load/1" do
    test "does nothing to the value" do
      assert {:ok, 42} = Any.load(42)
      assert {:ok, ""} = Any.load("")
      assert {:ok, "0x2a"} = Any.load("0x2a")
      assert {:ok, []} = Any.load([])
      assert {:ok, [1, 2, 3]} = Any.load([1, 2, 3])
      assert {:ok, %{key: :value}} = Any.load(%{key: :value})
    end
  end

  describe "dump/1" do
    test "does nothing to the value" do
      assert {:ok, 42} = Any.dump(42)
      assert {:ok, ""} = Any.dump("")
      assert {:ok, "0x2a"} = Any.dump("0x2a")
      assert {:ok, []} = Any.dump([])
      assert {:ok, [1, 2, 3]} = Any.dump([1, 2, 3])
      assert {:ok, %{key: :value}} = Any.dump(%{key: :value})
    end
  end
end
