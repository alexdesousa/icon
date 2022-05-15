defmodule Yggdrasil.Subscriber.Adapter.Icon.Message do
  @moduledoc """
  This module defines functions to deal with ICON 2.0 websocket messages.

  When a connection is established with the ICON 2.0 websocket, we need to send
  a `text` frame with a JSON payload to state our intention. There are two
  channels:

  - `:block` for receiving both ticks on every block and event logs specific to
    the events we're filtering.
  - `:event` for receiving updates for a specific event log.
  """
  alias Icon.RPC.Identity
  alias Icon.Schema
  alias Icon.Schema.Type
  alias Icon.Schema.Types.Block.Tick
  alias Icon.Schema.Types.EventLog
  alias Yggdrasil.Channel

  @typedoc """
  Message.
  """
  @type t :: Tick.t() | EventLog.t()

  @doc """
  Decodes an incoming message from the ICON 2.0 websocket.
  """
  @spec decode(Channel.t(), binary()) ::
          :ok
          | {:ok, [t()]}
          | {:error, Schema.Error.t()}
  def decode(%Channel{} = channel, notification)
      when is_binary(notification) do
    case Jason.decode(notification) do
      {:ok, %{"code" => 0}} ->
        :ok

      {:ok, %{"code" => code, "message" => message}} ->
        {:error, Schema.Error.new(code: code, message: message)}

      {:ok, notification} when is_map(notification) ->
        do_decode(channel, notification)

      {:error, _} ->
        reason = "cannot decode channel message"
        {:error, Schema.Error.new(code: -32_000, message: reason)}
    end
  end

  @doc """
  Encodes a request for the ICON 2.0 websocket. It receives the `height` and
  the `channel` to build the request.
  """
  @spec encode(pos_integer(), Channel.t()) :: WebSockex.frame() | no_return()
  def encode(height, channel) do
    data =
      height
      |> do_encode(channel)
      |> Jason.encode!()

    {:text, data}
  end

  ##################
  # Decoding helpers

  @spec do_decode(Channel.t(), map()) ::
          {:ok, [t()]}
          | {:error, Schema.Error.t()}
  defp do_decode(channel, notification)

  defp do_decode(%Channel{name: %{source: :block}} = channel, notification) do
    decode_block(channel, notification)
  end

  defp do_decode(%Channel{name: %{source: :event}} = channel, notification) do
    decode_event(channel, notification)
  end

  @spec decode_block(Channel.t(), map()) ::
          {:ok, [t()]}
          | {:error, Schema.Error.t()}
  defp decode_block(channel, notification)

  defp decode_block(
         %Channel{name: info} = channel,
         %{
           "height" => height,
           "hash" => hash,
           "indexes" => indexes,
           "events" => events
         }
       ) do
    identity = info[:identity] || Identity.new()
    base = %{"height" => height, "hash" => hash}
    {:ok, [tick]} = decode_block(channel, base)

    indexes
    |> Stream.zip(events)
    |> Stream.map(fn {indexes, events} -> Enum.zip(indexes, events) end)
    |> Stream.flat_map(& &1)
    |> Stream.map(fn {index, events} ->
      %{"index" => index, "events" => events}
    end)
    |> Enum.map(&Map.merge(base, &1))
    |> decode_events(identity)
    |> case do
      {:ok, event_logs} ->
        {:ok, [tick | event_logs]}

      {:error, _} = error ->
        error
    end
  end

  defp decode_block(%Channel{}, notification) do
    Schema.Types.Block.Tick
    |> Schema.generate()
    |> Schema.new(notification)
    |> Schema.load()
    |> Schema.apply(into: Schema.Types.Block.Tick)
    |> case do
      {:ok, %Tick{} = tick} ->
        {:ok, [tick]}

      {:error, _} = error ->
        error
    end
  end

  @spec decode_events(
          [map()],
          Identity.t(),
          nil | Schema.Types.Block.t(),
          [Schema.Types.EventLog.t()]
        ) ::
          {:ok, [t()]}
          | {:error, Schema.Error.t()}
  defp decode_events(notifications, identity, block \\ nil, event_logs \\ [])

  defp decode_events([], _identity, _block, event_logs) do
    {:ok, event_logs}
  end

  defp decode_events([first | _] = notifications, identity, nil, event_logs) do
    with {:ok, height} <- decode_block_height(first),
         {:ok, block} <- Icon.get_block(identity, height - 1),
         {:ok, event_logs} <-
           decode_events(notifications, identity, block, event_logs) do
      {:ok, event_logs}
    else
      :error ->
        reason = "cannot decode information in notification"
        {:error, Schema.Error.new(code: -32_000, message: reason)}

      {:error, _} = error ->
        error
    end
  end

  defp decode_events([notification | notifications], identity, block, events) do
    with {:ok, tx_index} <- decode_transaction_index(notification),
         {:ok, events_indexes} <- decode_events_indexes(notification),
         {:ok, transaction} <- get_transaction(block, tx_index),
         {:ok, new_events} <- get_event_logs(identity, transaction) do
      new_events = filter_logs(new_events, events_indexes)
      decode_events(notifications, identity, block, new_events ++ events)
    end
  end

  @spec decode_event(Channel.t(), map()) ::
          {:ok, [t()]}
          | {:error, Schema.Error.t()}
  defp decode_event(channel, notification)

  defp decode_event(%Channel{name: info}, notification) do
    identity = info[:identity] || Identity.new()

    with {:ok, tx_index} <- decode_transaction_index(notification),
         {:ok, events_indexes} <- decode_events_indexes(notification),
         {:ok, height} <- decode_block_height(notification),
         {:ok, block} <- Icon.get_block(identity, height - 1),
         block_tick = %Tick{hash: block.block_hash, height: block.height},
         {:ok, tx} <- get_transaction(block, tx_index),
         {:ok, event_logs} <- get_event_logs(identity, tx) do
      {:ok, [block_tick | filter_logs(event_logs, events_indexes)]}
    else
      :error ->
        reason = "cannot decode information in notification"
        {:error, Schema.Error.new(code: -32_000, message: reason)}

      {:error, _} = error ->
        error
    end
  end

  @spec decode_transaction_index(map()) ::
          {:ok, Schema.Types.Integer.t()}
          | :error
  defp decode_transaction_index(notification)

  defp decode_transaction_index(%{"index" => encoded}) do
    Schema.Types.Integer.load(encoded)
  end

  defp decode_transaction_index(_), do: :error

  @spec decode_events_indexes(map()) ::
          {:ok, [Schema.Types.Integer.t()]}
          | :error
  defp decode_events_indexes(notification)

  defp decode_events_indexes(%{"events" => events}) do
    Enum.reduce_while(events, {:ok, []}, fn event_index, {:ok, indexes} ->
      case Schema.Types.Integer.load(event_index) do
        {:ok, index} ->
          {:cont, {:ok, [index | indexes]}}

        :error ->
          {:halt, :error}
      end
    end)
  end

  defp decode_events_indexes(_), do: :error

  @spec decode_block_height(map()) :: {:ok, Schema.Types.Integer.t()} | :error
  defp decode_block_height(notification)

  defp decode_block_height(%{"height" => height}) do
    Schema.Types.Integer.load(height)
  end

  defp decode_block_height(_), do: :error

  @spec get_transaction(Schema.Types.Block.t(), non_neg_integer()) ::
          {:ok, Schema.Types.Transaction.t()}
          | {:error, Schema.Error.t()}
  defp get_transaction(block, index)

  defp get_transaction(%Schema.Types.Block{} = block, index) do
    case Enum.at(block.confirmed_transaction_list, index) do
      nil ->
        reason =
          "cannot find the transaction index #{index} on block with height #{block.height}"

        {:error, Schema.Error.new(code: -32_000, message: reason)}

      transaction ->
        {:ok, transaction}
    end
  end

  @spec get_event_logs(Identity.t(), Schema.Types.Transaction.t()) ::
          {:ok, [Schema.Types.EventLog.t()]}
          | {:error, Schema.Error.t()}
  defp get_event_logs(identity, transaction)

  defp get_event_logs(identity, %Schema.Types.Transaction{} = transaction) do
    with {:ok, %Schema.Types.Transaction.Result{} = result} <-
           Icon.get_transaction_result(identity, transaction.txHash) do
      {:ok, result.eventLogs}
    end
  end

  @spec filter_logs([Schema.Types.EventLog.t()], [non_neg_integer()]) ::
          [Schema.Types.EventLog.t()]
  defp filter_logs(event_logs, indexes)

  defp filter_logs(event_logs, indexes) do
    0..(length(event_logs) - 1)
    |> Stream.zip(event_logs)
    |> Stream.filter(fn {x, _event} -> x in indexes end)
    |> Enum.map(fn {_, event_log} -> event_log end)
  end

  ##################
  # Encoding helpers

  @spec do_encode(pos_integer(), Channel.t()) :: map()
  defp do_encode(height, channel)

  defp do_encode(height, %Channel{name: %{source: :block} = info}) do
    data = %{height: Type.dump!(Icon.Schema.Types.Integer, height)}

    case info[:data] do
      [_ | _] = events ->
        Map.put(data, :eventFilters, Enum.map(events, &encode_event/1))

      _ ->
        data
    end
  end

  defp do_encode(height, %Channel{name: %{source: :event} = info}) do
    base = %{height: Type.dump!(Icon.Schema.Types.Integer, height)}

    (info[:data] || %{})
    |> encode_event()
    |> Map.merge(base)
  end

  @spec encode_event(map()) :: map() | no_return()
  defp encode_event(data)

  defp encode_event(%{event: header} = data) when is_binary(header) do
    %{event: header}
    |> maybe_add_addr(data)
    |> maybe_add_indexed(data)
    |> maybe_add_data(data)
  end

  defp encode_event(_data) do
    raise ArgumentError, message: "missing event header"
  end

  @spec maybe_add_addr(map(), map()) :: map()
  defp maybe_add_addr(event, %{addr: addr}) do
    Map.put(event, :addr, Type.dump!(Icon.Schema.Types.SCORE, addr))
  end

  defp maybe_add_addr(event, _) do
    event
  end

  @spec maybe_add_indexed(map(), map()) :: map()
  defp maybe_add_indexed(event, data)

  defp maybe_add_indexed(%{event: header} = event, %{indexed: indexed})
       when is_list(indexed) do
    indexed =
      header
      |> get_types()
      |> Enum.zip(indexed)
      |> Enum.map(fn
        {_module, nil} -> nil
        {module, value} -> Type.dump!(module, value)
      end)

    Map.put(event, :indexed, indexed)
  end

  defp maybe_add_indexed(event, _data), do: event

  @spec maybe_add_data(map(), map()) :: map()
  defp maybe_add_data(event, data)

  defp maybe_add_data(%{event: header, indexed: indexed} = event, %{data: data})
       when is_list(indexed) do
    data =
      header
      |> get_types()
      |> Enum.drop(length(indexed))
      |> Enum.zip(data)
      |> Enum.map(fn
        {_module, nil} -> nil
        {module, value} -> Type.dump!(module, value)
      end)

    Map.put(event, :data, data)
  end

  defp maybe_add_data(event, _data), do: event

  @spec get_types(binary()) :: [module()] | no_return()
  defp get_types(header) do
    header
    |> String.splitter(["(", ",", ")"], trim: true)
    |> Enum.into([])
    |> tl()
    |> Enum.map(fn
      "int" -> Icon.Schema.Types.Integer
      "str" -> Icon.Schema.Types.String
      "bytes" -> Icon.Schema.Types.BinaryData
      "bool" -> Icon.Schema.Types.Boolean
      "Address" -> Icon.Schema.Types.Address
    end)
  end
end
