defmodule Yggdrasil.Subscriber.Adapter.Icon.MessageTest do
  use ExUnit.Case, async: true

  alias Yggdrasil.Channel
  alias Yggdrasil.Subscriber.Adapter.Icon.Message

  describe "encoding/2 for block" do
    test "sets height" do
      height = 42
      channel = %Channel{name: %{source: :block}}

      assert {:text, data} = Message.encode(height, channel)

      assert %{"height" => "0x2a"} = Jason.decode!(data)
    end

    test "sets events" do
      height = 42

      channel = %Channel{
        name: %{
          source: :block,
          data: [
            %{
              addr: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
              event: "Transfer(Address,Address,int)",
              indexed: [
                nil,
                "hxbe258ceb872e08851f1f59694dac2558708ece11"
              ],
              data: [
                42
              ]
            }
          ]
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{
               "height" => "0x2a",
               "eventFilters" => [
                 %{
                   "addr" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                   "event" => "Transfer(Address,Address,int)",
                   "indexed" => [
                     nil,
                     "hxbe258ceb872e08851f1f59694dac2558708ece11"
                   ],
                   "data" => [
                     "0x2a"
                   ]
                 }
               ]
             } = Jason.decode!(data)
    end

    test "raises error when event is missing" do
      height = 42

      channel = %Channel{
        name: %{
          source: :block,
          data: [
            %{
              addr: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
            }
          ]
        }
      }

      assert_raise ArgumentError, fn ->
        Message.encode(height, channel)
      end
    end
  end

  describe "encoding/2 for event" do
    test "sets height" do
      height = 42
      channel = %Channel{name: %{source: :event, data: %{event: "Event()"}}}

      assert {:text, data} = Message.encode(height, channel)

      assert %{"height" => "0x2a"} = Jason.decode!(data)
    end

    test "sets addr" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event()",
            addr: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"addr" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"} =
               Jason.decode!(data)
    end

    test "sets integer indexed value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(int)",
            indexed: [42]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"indexed" => ["0x2a"]} = Jason.decode!(data)
    end

    test "sets string indexed value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(str)",
            indexed: ["hello"]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"indexed" => ["hello"]} = Jason.decode!(data)
    end

    test "sets bytes indexed value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(bytes)",
            indexed: ["hello"]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"indexed" => ["0x68656c6c6f"]} = Jason.decode!(data)
    end

    test "sets bool indexed value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(bool)",
            indexed: [true]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"indexed" => ["0x1"]} = Jason.decode!(data)
    end

    test "sets address indexed value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(Address)",
            indexed: ["hxbe258ceb872e08851f1f59694dac2558708ece11"]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"indexed" => ["hxbe258ceb872e08851f1f59694dac2558708ece11"]} =
               Jason.decode!(data)
    end

    test "sets nil indexed value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(Address)",
            indexed: [nil]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)
      assert %{"indexed" => [nil]} = Jason.decode!(data)
    end

    test "sets integer data value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(int)",
            indexed: [],
            data: [42]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"data" => ["0x2a"]} = Jason.decode!(data)
    end

    test "sets string data value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(str)",
            indexed: [],
            data: ["hello"]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"data" => ["hello"]} = Jason.decode!(data)
    end

    test "sets bytes data value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(bytes)",
            indexed: [],
            data: ["hello"]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"data" => ["0x68656c6c6f"]} = Jason.decode!(data)
    end

    test "sets bool data value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(bool)",
            indexed: [],
            data: [true]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"data" => ["0x1"]} = Jason.decode!(data)
    end

    test "sets address data value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(Address)",
            indexed: [],
            data: ["hxbe258ceb872e08851f1f59694dac2558708ece11"]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)

      assert %{"data" => ["hxbe258ceb872e08851f1f59694dac2558708ece11"]} =
               Jason.decode!(data)
    end

    test "sets nil data value" do
      height = 42

      channel = %Channel{
        name: %{
          source: :event,
          data: %{
            event: "Event(Address)",
            indexed: [],
            data: [nil]
          }
        }
      }

      assert {:text, data} = Message.encode(height, channel)
      assert %{"data" => [nil]} = Jason.decode!(data)
    end
  end
end
