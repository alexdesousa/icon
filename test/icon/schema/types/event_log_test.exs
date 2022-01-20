defmodule Icon.Schema.Types.EventLogTest do
  use ExUnit.Case, async: true

  alias Icon.Schema.Types.EventLog

  describe "load/1" do
    setup do
      event_log = %{
        "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        "indexed" => [
          "Transfer(Address,Address,int,str,bool,bytes)",
          "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
          "hx2e243ad926ac48d15156756fce28314357d49d83"
        ],
        "data" => [
          "0x2a",
          "Hello",
          "0x1",
          "0x49434f4e20322e30"
        ]
      }

      {:ok, event_log: event_log}
    end

    test "when it's a valid event log, loads the event header" do
      event_log = %{
        "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        "indexed" => [
          "Transfer(Address,Address,int)",
          "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
          "hx2e243ad926ac48d15156756fce28314357d49d83"
        ],
        "data" => [
          "0x2a"
        ]
      }

      assert {:ok,
              %EventLog{
                header: "Transfer(Address,Address,int)"
              }} = EventLog.load(event_log)
    end

    test "when it's a valid event log, loads the event name" do
      event_log = %{
        "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        "indexed" => [
          "Transfer(Address,Address,int)",
          "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
          "hx2e243ad926ac48d15156756fce28314357d49d83"
        ],
        "data" => [
          "0x2a"
        ]
      }

      assert {:ok, %EventLog{name: "Transfer"}} = EventLog.load(event_log)
    end

    test "when it's a valid event log, loads the SCORE address" do
      score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"

      event_log = %{
        "scoreAddress" => score_address,
        "indexed" => [
          "Transfer(Address,Address,int)",
          "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
          "hx2e243ad926ac48d15156756fce28314357d49d83"
        ],
        "data" => [
          "0x2a"
        ]
      }

      assert {:ok, %EventLog{score_address: ^score_address}} =
               EventLog.load(event_log)
    end

    test "when it's a valid event log, loads indexed parameters" do
      event_log = %{
        "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        "indexed" => [
          "Transfer(Address,Address,int)",
          "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
          "hx2e243ad926ac48d15156756fce28314357d49d83"
        ],
        "data" => [
          "0x2a"
        ]
      }

      assert {:ok,
              %EventLog{
                indexed: [
                  "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
                  "hx2e243ad926ac48d15156756fce28314357d49d83"
                ]
              }} = EventLog.load(event_log)
    end

    test "when it's a valid event log, loads data parameters" do
      event_log = %{
        "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        "indexed" => [
          "Transfer(Address,Address,int)",
          "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
          "hx2e243ad926ac48d15156756fce28314357d49d83"
        ],
        "data" => [
          "0x2a"
        ]
      }

      assert {:ok, %EventLog{data: [42]}} = EventLog.load(event_log)
    end

    test "when it's a valid event log, loads int type" do
      event_log = %{
        "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        "indexed" => [
          "Transfer(Address,Address,int)",
          "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
          "hx2e243ad926ac48d15156756fce28314357d49d83"
        ],
        "data" => [
          "0x2a"
        ]
      }

      assert {:ok, %EventLog{data: [42]}} = EventLog.load(event_log)
    end

    test "when it's a valid event log, loads str type" do
      event_log = %{
        "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        "indexed" => [
          "Transfer(Address,Address,str)",
          "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
          "hx2e243ad926ac48d15156756fce28314357d49d83"
        ],
        "data" => [
          "Hello"
        ]
      }

      assert {:ok, %EventLog{data: ["Hello"]}} = EventLog.load(event_log)
    end

    test "when it's a valid event log, loads bool type" do
      event_log = %{
        "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        "indexed" => [
          "Transfer(Address,Address,bool)",
          "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
          "hx2e243ad926ac48d15156756fce28314357d49d83"
        ],
        "data" => [
          "0x1"
        ]
      }

      assert {:ok, %EventLog{data: [true]}} = EventLog.load(event_log)
    end

    test "when it's a valid event log, loads bytes type" do
      event_log = %{
        "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        "indexed" => [
          "Transfer(Address,Address,bytes)",
          "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
          "hx2e243ad926ac48d15156756fce28314357d49d83"
        ],
        "data" => [
          "0x49434f4e20322e30"
        ]
      }

      assert {:ok, %EventLog{data: ["ICON 2.0"]}} = EventLog.load(event_log)
    end

    test "when it's a valid event log, loads Address type" do
      event_log = %{
        "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        "indexed" => [
          "Transfer(Address,Address,Address)",
          "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
          "hx2e243ad926ac48d15156756fce28314357d49d83"
        ],
        "data" => [
          "hx2e243ad926ac48d15156756fce28314357d49d83"
        ]
      }

      assert {:ok,
              %EventLog{data: ["hx2e243ad926ac48d15156756fce28314357d49d83"]}} =
               EventLog.load(event_log)
    end

    test "when the map is invalid, errors" do
      key = "#{:erlang.phash2(make_ref())}"

      event_log =
        %{
          "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
          "indexed" => [
            "Transfer(Address,Address,int)",
            "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
            "hx2e243ad926ac48d15156756fce28314357d49d83"
          ],
          "data" => [
            "0x2a"
          ]
        }
        |> Map.put(key, nil)

      assert :error = EventLog.load(event_log)
    end

    test "when value is invalid, errors" do
      assert :error = EventLog.load([])
      assert :error = EventLog.load(nil)
      assert :error = EventLog.load("")
      assert :error = EventLog.load(42)
    end
  end

  describe "dump/1" do
    test "dumps a valid event log" do
      expected = %{
        "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        "indexed" => [
          "Transfer(Address,Address,int)",
          "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
          "hx2e243ad926ac48d15156756fce28314357d49d83"
        ],
        "data" => [
          "0x2a"
        ]
      }

      assert {:ok, event_log} = EventLog.load(expected)
      assert {:ok, ^expected} = EventLog.dump(event_log)
    end

    test "when event log is invalid, errors" do
      assert {:ok, event_log} =
               EventLog.load(%{
                 "scoreAddress" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                 "indexed" => [
                   "Transfer(Address,Address,int)",
                   "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
                   "hx2e243ad926ac48d15156756fce28314357d49d83"
                 ],
                 "data" => [
                   "0x2a"
                 ]
               })

      event_log = %{event_log | header: "Transfer(Address,Address,Address)"}
      assert :error = EventLog.dump(event_log)
    end

    test "when value is invalid, errors" do
      assert :error = EventLog.dump(%{})
      assert :error = EventLog.dump([])
      assert :error = EventLog.dump(nil)
      assert :error = EventLog.dump("")
      assert :error = EventLog.dump(42)
    end
  end
end
