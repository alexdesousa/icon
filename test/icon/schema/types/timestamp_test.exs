defmodule Icon.Schema.Types.TimestampTest do
  use ExUnit.Case, async: true

  alias Icon.Schema.Types.Timestamp

  describe "load/1" do
    test "when a valid timestamp in microseconds is provided, returns equivalent datetime" do
      timestamp = 155_920_469_933_036
      expected = DateTime.from_unix!(timestamp, :microsecond)

      assert {:ok, ^expected} = Timestamp.load(timestamp)
    end

    test "when a valid datetime is provided, returns it" do
      datetime = DateTime.from_unix!(155_920_469_933_036, :microsecond)

      assert {:ok, ^datetime} = Timestamp.load(datetime)
    end

    test "when the timestamp is invalid, errors" do
      timestamp = -3_777_051_168_000_000_000

      assert :error = Timestamp.load(timestamp)
    end

    test "when it's not a valid timestamp, errors" do
      assert :error = Timestamp.load(nil)
      assert :error = Timestamp.load(:atom)
      assert :error = Timestamp.load("")
      assert :error = Timestamp.load(%{})
      assert :error = Timestamp.load([])
    end
  end

  describe "dump/1" do
    test "delegates to load/1" do
      timestamp = 155_920_469_933_036

      assert Timestamp.dump(timestamp) == Timestamp.load(timestamp)
    end
  end
end
