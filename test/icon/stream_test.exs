defmodule Icon.StreamTest do
  use ExUnit.Case, async: true

  alias Icon.RPC.Identity
  alias Icon.Schema.Types.Block.Tick

  describe "new_block_stream/2" do
    test "should create a new stream without any parameters" do
      assert {:ok, %Icon.Stream{}} = Icon.Stream.new_block_stream()
    end

    test "should create an identity when none is provided" do
      assert {:ok, %Icon.Stream{identity: %Identity{}}} =
               Icon.Stream.new_block_stream([], from_height: 0)
    end

    test "should use the identity provided" do
      identity = Identity.new()

      assert {:ok, %Icon.Stream{identity: ^identity}} =
               Icon.Stream.new_block_stream([],
                 identity: identity,
                 from_height: 0
               )
    end

    test "should set the source as block" do
      assert {:ok, %Icon.Stream{source: :block}} =
               Icon.Stream.new_block_stream([], from_height: 0)
    end

    test "should set the height to the one provided" do
      assert {:ok, %Icon.Stream{height: 42, type: :past}} =
               Icon.Stream.new_block_stream([], from_height: 42)
    end

    test "should create an empty buffer" do
      assert {:ok, %Icon.Stream{buffer: buffer}} =
               Icon.Stream.new_block_stream([], from_height: 0)

      assert :queue.is_empty(buffer)
    end

    test "should set the default max buffer size when none provided" do
      assert {:ok, %Icon.Stream{max_buffer_size: 1_000}} =
               Icon.Stream.new_block_stream([], from_height: 0)
    end

    test "should set the max buffer size when provided" do
      assert {:ok, %Icon.Stream{max_buffer_size: 1}} =
               Icon.Stream.new_block_stream([],
                 from_height: 0,
                 max_buffer_size: 1
               )
    end

    test "should encode the list of events" do
      events = [
        %{
          event: "Transfer(Address,Address,int)"
        },
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

      assert {:ok,
              %Icon.Stream{
                events: [
                  %{event: "Transfer(Address,Address,int)"},
                  %{
                    addr: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                    event: "Transfer(Address,Address,int)",
                    indexed: [
                      nil,
                      "hxbe258ceb872e08851f1f59694dac2558708ece11"
                    ],
                    data: ["0x2a"]
                  }
                ]
              }} = Icon.Stream.new_block_stream(events, from_height: 0)
    end

    test "should fail when the event doesn't have a header" do
      assert_raise ArgumentError, fn ->
        Icon.Stream.new_block_stream([%{}], from_height: 0)
      end
    end

    test "should encode int type" do
      events = [
        %{
          event: "Event(int)",
          indexed: [42]
        }
      ]

      assert {:ok,
              %Icon.Stream{
                events: [
                  %{
                    event: "Event(int)",
                    indexed: ["0x2a"]
                  }
                ]
              }} = Icon.Stream.new_block_stream(events, from_height: 0)
    end

    test "should encode str type" do
      events = [
        %{
          event: "Event(str)",
          indexed: ["hello"]
        }
      ]

      assert {:ok,
              %Icon.Stream{
                events: [
                  %{
                    event: "Event(str)",
                    indexed: ["hello"]
                  }
                ]
              }} = Icon.Stream.new_block_stream(events, from_height: 0)
    end

    test "should encode bytes type" do
      events = [
        %{
          event: "Event(bytes)",
          indexed: ["hello"]
        }
      ]

      assert {:ok,
              %Icon.Stream{
                events: [
                  %{
                    event: "Event(bytes)",
                    indexed: ["0x68656c6c6f"]
                  }
                ]
              }} = Icon.Stream.new_block_stream(events, from_height: 0)
    end

    test "should encode bool type" do
      events = [
        %{
          event: "Event(bool)",
          indexed: [true]
        }
      ]

      assert {:ok,
              %Icon.Stream{
                events: [
                  %{
                    event: "Event(bool)",
                    indexed: ["0x1"]
                  }
                ]
              }} = Icon.Stream.new_block_stream(events, from_height: 0)
    end

    test "should encode address type" do
      events = [
        %{
          event: "Event(Address)",
          indexed: ["hxbe258ceb872e08851f1f59694dac2558708ece11"]
        }
      ]

      assert {:ok,
              %Icon.Stream{
                events: [
                  %{
                    event: "Event(Address)",
                    indexed: ["hxbe258ceb872e08851f1f59694dac2558708ece11"]
                  }
                ]
              }} = Icon.Stream.new_block_stream(events, from_height: 0)
    end

    test "should set the latest height when none is provided" do
      bypass = Bypass.open()
      identity = Identity.new(node: "http://localhost:#{bypass.port}")

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "block_hash" =>
              "d579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "confirmed_transaction_list" => [],
            "height" => 42,
            "merkle_tree_root_hash" =>
              "0xce5aa42a762ee88a32fc2a792dfb5975858a71a8abf4ec51fb1218e3b827aa01",
            "peer_id" => "hxb97c82a5577a0a436f51a41421ad2d3b28da3f25",
            "prev_block_hash" =>
              "0xfe8138afd24512cc0e9f4da8df350300a759a480f15c8a00b04b2d753ea62ac3",
            "signature" => "",
            "time_stamp" => 1_642_849_581_258_886,
            "version" => "2.0"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, %Icon.Stream{height: 42, type: :latest}} =
               Icon.Stream.new_block_stream([], identity: identity)
    end

    test "should error when height is not provided and the node returns an error" do
      bypass = Bypass.open()
      identity = Identity.new(node: "http://localhost:#{bypass.port}")

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, response)
      end)

      assert {:error, %Icon.Schema.Error{reason: :system_error}} =
               Icon.Stream.new_block_stream([], identity: identity)
    end
  end

  describe "new_event_stream/2" do
    test "should create a new stream without any parameters" do
      assert {:ok, %Icon.Stream{}} = Icon.Stream.new_event_stream()
    end

    test "should create an identity when none is provided" do
      assert {:ok, %Icon.Stream{identity: %Identity{}}} =
               Icon.Stream.new_event_stream(nil, from_height: 0)
    end

    test "should use the identity provided" do
      identity = Identity.new()

      assert {:ok, %Icon.Stream{identity: ^identity}} =
               Icon.Stream.new_event_stream(nil,
                 identity: identity,
                 from_height: 0
               )
    end

    test "should set the source as event" do
      assert {:ok, %Icon.Stream{source: :event}} =
               Icon.Stream.new_event_stream(nil, from_height: 0)
    end

    test "should set the height to the one provided" do
      assert {:ok, %Icon.Stream{height: 42, type: :past}} =
               Icon.Stream.new_event_stream(nil, from_height: 42)
    end

    test "should create an empty buffer" do
      assert {:ok, %Icon.Stream{buffer: buffer}} =
               Icon.Stream.new_event_stream(nil, from_height: 0)

      assert :queue.is_empty(buffer)
    end

    test "should set the default max buffer size when none provided" do
      assert {:ok, %Icon.Stream{max_buffer_size: 1_000}} =
               Icon.Stream.new_event_stream(nil, from_height: 0)
    end

    test "should set the max buffer size when provided" do
      assert {:ok, %Icon.Stream{max_buffer_size: 1}} =
               Icon.Stream.new_event_stream(nil,
                 from_height: 0,
                 max_buffer_size: 1
               )
    end

    test "should encode a single event" do
      event = %{
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

      assert {:ok,
              %Icon.Stream{
                events: [
                  %{
                    addr: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
                    event: "Transfer(Address,Address,int)",
                    indexed: [
                      nil,
                      "hxbe258ceb872e08851f1f59694dac2558708ece11"
                    ],
                    data: ["0x2a"]
                  }
                ]
              }} = Icon.Stream.new_event_stream(event, from_height: 0)
    end

    test "should fail when the event doesn't have a header" do
      assert_raise ArgumentError, fn ->
        Icon.Stream.new_event_stream(%{}, from_height: 0)
      end
    end

    test "should encode int type" do
      event = %{
        event: "Event(int)",
        indexed: [42]
      }

      assert {:ok,
              %Icon.Stream{
                events: [
                  %{
                    event: "Event(int)",
                    indexed: ["0x2a"]
                  }
                ]
              }} = Icon.Stream.new_event_stream(event, from_height: 0)
    end

    test "should encode str type" do
      event = %{
        event: "Event(str)",
        indexed: ["hello"]
      }

      assert {:ok,
              %Icon.Stream{
                events: [
                  %{
                    event: "Event(str)",
                    indexed: ["hello"]
                  }
                ]
              }} = Icon.Stream.new_event_stream(event, from_height: 0)
    end

    test "should encode bytes type" do
      event = %{
        event: "Event(bytes)",
        indexed: ["hello"]
      }

      assert {:ok,
              %Icon.Stream{
                events: [
                  %{
                    event: "Event(bytes)",
                    indexed: ["0x68656c6c6f"]
                  }
                ]
              }} = Icon.Stream.new_event_stream(event, from_height: 0)
    end

    test "should encode bool type" do
      event = %{
        event: "Event(bool)",
        indexed: [true]
      }

      assert {:ok,
              %Icon.Stream{
                events: [
                  %{
                    event: "Event(bool)",
                    indexed: ["0x1"]
                  }
                ]
              }} = Icon.Stream.new_event_stream(event, from_height: 0)
    end

    test "should encode address type" do
      event = %{
        event: "Event(Address)",
        indexed: ["hxbe258ceb872e08851f1f59694dac2558708ece11"]
      }

      assert {:ok,
              %Icon.Stream{
                events: [
                  %{
                    event: "Event(Address)",
                    indexed: ["hxbe258ceb872e08851f1f59694dac2558708ece11"]
                  }
                ]
              }} = Icon.Stream.new_event_stream(event, from_height: 0)
    end

    test "should set the latest height when none is provided" do
      bypass = Bypass.open()
      identity = Identity.new(node: "http://localhost:#{bypass.port}")

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          result(%{
            "block_hash" =>
              "d579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
            "confirmed_transaction_list" => [],
            "height" => 42,
            "merkle_tree_root_hash" =>
              "0xce5aa42a762ee88a32fc2a792dfb5975858a71a8abf4ec51fb1218e3b827aa01",
            "peer_id" => "hxb97c82a5577a0a436f51a41421ad2d3b28da3f25",
            "prev_block_hash" =>
              "0xfe8138afd24512cc0e9f4da8df350300a759a480f15c8a00b04b2d753ea62ac3",
            "signature" => "",
            "time_stamp" => 1_642_849_581_258_886,
            "version" => "2.0"
          })

        Plug.Conn.resp(conn, 200, response)
      end)

      assert {:ok, %Icon.Stream{height: 42, type: :latest}} =
               Icon.Stream.new_event_stream(nil, identity: identity)
    end

    test "should error when height is not provided and the node returns an error" do
      bypass = Bypass.open()
      identity = Identity.new(node: "http://localhost:#{bypass.port}")

      Bypass.expect_once(bypass, "POST", "/api/v3", fn conn ->
        response =
          error(%{
            code: -31_000,
            message: "System error"
          })

        Plug.Conn.resp(conn, 400, response)
      end)

      assert {:error, %Icon.Schema.Error{reason: :system_error}} =
               Icon.Stream.new_event_stream(nil, identity: identity)
    end
  end

  describe "to_uri/1" do
    test "should generate a uri for block events" do
      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_block_stream([], from_height: 0)

      assert %URI{
               scheme: "https",
               authority: "ctz.solidwallet.io",
               host: "ctz.solidwallet.io",
               port: 443,
               path: "/api/v3/icon_dex/block"
             } = Icon.Stream.to_uri(stream)
    end

    test "should generate a uri for events" do
      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_event_stream(nil, from_height: 0)

      assert %URI{
               scheme: "https",
               authority: "ctz.solidwallet.io",
               host: "ctz.solidwallet.io",
               port: 443,
               path: "/api/v3/icon_dex/event"
             } = Icon.Stream.to_uri(stream)
    end
  end

  describe "encode/1" do
    test "should encode the message with a list of events" do
      events = [
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

      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_block_stream(events, from_height: 0)

      expected =
        Jason.encode!(%{
          "height" => "0x0",
          "eventFilters" => [
            %{
              "event" => "Transfer(Address,Address,int)",
              "addr" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
              "indexed" => [nil, "hxbe258ceb872e08851f1f59694dac2558708ece11"],
              "data" => ["0x2a"]
            }
          ]
        })

      assert ^expected = Icon.Stream.encode(stream)
    end

    test "should encode the message with a single event" do
      event = %{
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

      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_event_stream(event, from_height: 0)

      expected =
        Jason.encode!(%{
          "height" => "0x0",
          "event" => "Transfer(Address,Address,int)",
          "addr" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
          "indexed" => [nil, "hxbe258ceb872e08851f1f59694dac2558708ece11"],
          "data" => ["0x2a"]
        })

      assert ^expected = Icon.Stream.encode(stream)
    end

    test "should encode the message when there are no events" do
      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_block_stream([], from_height: 0)

      assert ~s({"height":"0x0"}) == Icon.Stream.encode(stream)

      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_event_stream(nil, from_height: 0)

      assert ~s({"height":"0x0"}) == Icon.Stream.encode(stream)
    end
  end

  describe "put/2" do
    test "should store the ticks in the buffer" do
      ticks = [
        %Tick{height: 0},
        %Tick{height: 1},
        %Tick{height: 2}
      ]

      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_block_stream([], from_height: 0)

      stream = Icon.Stream.put(stream, ticks)
      assert {^ticks, _stream} = Icon.Stream.pop(stream, 3)
    end
  end

  describe "pop/2" do
    test "should pop the amount of ticks requested if they exist" do
      ticks = [
        %Tick{height: 0},
        %Tick{height: 1},
        %Tick{height: 2}
      ]

      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_block_stream([], from_height: 0)

      stream = Icon.Stream.put(stream, ticks)
      assert {^ticks, _stream} = Icon.Stream.pop(stream, 3)
    end

    test "should pop all ticks when the amount is greater than the buffer size" do
      ticks = [
        %Tick{height: 0},
        %Tick{height: 1},
        %Tick{height: 2}
      ]

      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_block_stream([], from_height: 0)

      stream = Icon.Stream.put(stream, ticks)
      assert {^ticks, _stream} = Icon.Stream.pop(stream, 100)
    end

    test "should return an empty list when the buffer is empty" do
      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_block_stream([], from_height: 0)

      assert {[], _stream} = Icon.Stream.pop(stream, 1)
    end

    test "should change the height if the buffer is not empty" do
      ticks = [
        %Tick{height: 0},
        %Tick{height: 1},
        %Tick{height: 2}
      ]

      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_block_stream([], from_height: 0)

      stream = Icon.Stream.put(stream, ticks)
      assert {[_, _], %Icon.Stream{height: 1}} = Icon.Stream.pop(stream, 2)
    end

    test "should keep the current height if the buffer is empty" do
      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_block_stream([], from_height: 0)

      assert {[], %Icon.Stream{height: 0}} = Icon.Stream.pop(stream, 1)
    end
  end

  describe "is_full?" do
    test "should return true when the buffer is full" do
      ticks = [
        %Tick{height: 0},
        %Tick{height: 1},
        %Tick{height: 2}
      ]

      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_block_stream([],
                 from_height: 0,
                 max_buffer_size: 3
               )

      stream = Icon.Stream.put(stream, ticks)

      assert Icon.Stream.is_full?(stream)
    end

    test "should return false when the buffer is not full" do
      ticks = [
        %Tick{height: 0},
        %Tick{height: 1},
        %Tick{height: 2}
      ]

      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_block_stream([],
                 from_height: 0,
                 max_buffer_size: 4
               )

      stream = Icon.Stream.put(stream, ticks)

      refute Icon.Stream.is_full?(stream)
    end
  end

  describe "check_capacity/1" do
    test "should return the percentage of space left in the buffer" do
      ticks = [
        %Tick{height: 0},
        %Tick{height: 1},
        %Tick{height: 2}
      ]

      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_block_stream([],
                 from_height: 0,
                 max_buffer_size: 4
               )

      stream = Icon.Stream.put(stream, ticks)

      assert_in_delta Icon.Stream.check_space_left(stream), 0.25, 0.001
    end

    test "should return 0 if the buffer is full" do
      ticks = [
        %Tick{height: 0},
        %Tick{height: 1},
        %Tick{height: 2}
      ]

      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_block_stream([],
                 from_height: 0,
                 max_buffer_size: 3
               )

      stream = Icon.Stream.put(stream, ticks)

      assert_in_delta Icon.Stream.check_space_left(stream), 0.0, 0.001
    end

    test "should return 0 when the buffer is overflowed" do
      ticks = [
        %Tick{height: 0},
        %Tick{height: 1},
        %Tick{height: 2}
      ]

      assert {:ok, %Icon.Stream{} = stream} =
               Icon.Stream.new_block_stream([],
                 from_height: 0,
                 max_buffer_size: 2
               )

      stream = Icon.Stream.put(stream, ticks)

      assert_in_delta Icon.Stream.check_space_left(stream), 0.0, 0.001
    end
  end

  @spec result(any()) :: binary()
  defp result(result) do
    %{
      "jsonrpc" => "2.0",
      "id" => :erlang.system_time(:microsecond),
      "result" => result
    }
    |> Jason.encode!()
  end

  @spec error(map()) :: binary()
  defp error(error) when is_map(error) do
    %{
      "jsonrpc" => "2.0",
      "id" => :erlang.system_time(:microsecond),
      "error" => error
    }
    |> Jason.encode!()
  end
end
