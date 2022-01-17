defmodule Icon.Schema.Types.Transaction.StatusTest do
  use ExUnit.Case, async: true

  alias Icon.Schema.Types.Transaction.Status

  describe "load/1" do
    test "when is a valid hex status, loads it" do
      assert {:ok, :failure} = Status.load("0x0")
      assert {:ok, :success} = Status.load("0x1")
    end

    test "when is a valid integer, loads it" do
      assert {:ok, :failure} = Status.load(0)
      assert {:ok, :success} = Status.load(1)
    end

    test "when is a valid status, does nothing" do
      assert {:ok, :failure} = Status.load(:failure)
      assert {:ok, :success} = Status.load(:success)
    end

    test "when is invalid, errors" do
      assert :error = Status.load("0x2a")
      assert :error = Status.load("1")
      assert :error = Status.load(nil)
      assert :error = Status.load(:atom)
      assert :error = Status.load(%{})
      assert :error = Status.load([])
    end
  end

  describe "dump/1" do
    test "when is a valid hex status, loads it" do
      assert {:ok, "0x0"} = Status.dump("0x0")
      assert {:ok, "0x1"} = Status.dump("0x1")
    end

    test "when is a valid integer, loads it" do
      assert {:ok, "0x0"} = Status.dump(0)
      assert {:ok, "0x1"} = Status.dump(1)
    end

    test "when is a valid status, dumps it" do
      assert {:ok, "0x0"} = Status.dump(:failure)
      assert {:ok, "0x1"} = Status.dump(:success)
    end

    test "when is invalid, errors" do
      assert :error = Status.dump("0x2a")
      assert :error = Status.dump("1")
      assert :error = Status.dump(nil)
      assert :error = Status.dump(:atom)
      assert :error = Status.dump(%{})
      assert :error = Status.dump([])
    end
  end
end
