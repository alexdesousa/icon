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
    test "converts datetime to unix timestamp in microseconds" do
      timestamp = 155_920_469_933_036
      datetime = DateTime.from_unix!(timestamp, :microsecond)

      assert {:ok, ^timestamp} = Timestamp.dump(datetime)
    end

    test "when unix timestamp in microseconds i" do
      timestamp = 155_920_469_933_036
      assert {:ok, ^timestamp} = Timestamp.dump(timestamp)
    end

    test "when it's not a valid datetime or timestamp, errors" do
      assert :error = Timestamp.dump(-377_705_116_800_000_001)
      assert :error = Timestamp.dump(nil)
      assert :error = Timestamp.dump(:atom)
      assert :error = Timestamp.dump("")
      assert :error = Timestamp.dump(%{})
      assert :error = Timestamp.dump([])
    end
  end
end
