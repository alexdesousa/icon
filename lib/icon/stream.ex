defmodule Icon.Stream do
  @moduledoc """
  This module defines an Icon websocket stream.
  """
  import Icon.Schema, only: [list: 1]

  alias Icon.RPC.Identity
  alias Icon.Schema
  alias Icon.Schema.{Error, Type, Types}

  @max_buffer_size 1_000

  @doc """
  An Icon websocket stream representation.
  """
  @enforce_keys [
    :identity,
    :source,
    :events,
    :height,
    :type,
    :buffer,
    :max_buffer_size
  ]
  defstruct [
    :identity,
    :source,
    :events,
    :height,
    :type,
    :buffer,
    :max_buffer_size
  ]

  @typedoc """
  An Icon instanciated websocket stream.
  """
  @type t :: pid()

  @typedoc """
  An Icon websocket stream representation.
  """
  @type stream :: %__MODULE__{
          identity: identity :: Identity.t(),
          source: source :: source(),
          events: events_subscriptions :: event_subscriptions(),
          height: height :: non_neg_integer(),
          type: height_type :: :latest | :past,
          buffer: buffer :: :queue.queue(map()),
          max_buffer_size: buffer_size :: pos_integer()
        }

  @typedoc """
  Event source type
  """
  @type source ::
          :block
          | :event

  @typedoc """
  Event suscription.
  """
  @type event_subscription :: %{
          required(:event) => signature :: binary(),
          optional(:addr) => contract_address :: Types.SCORE.t(),
          optional(:indexed) => indexed_parameters :: [any()],
          optional(:data) => data_parameters :: [any()]
        }

  @typedoc """
  Events.
  """
  @type event_subscriptions :: [event_subscription()]

  @typedoc """
  Transaction index.
  """
  @type transaction_index :: non_neg_integer()

  @typedoc """
  Event log index.
  """
  @type event_log_index :: non_neg_integer()

  @typedoc """
  Incoming event.
  """
  @type event :: %{
          :height => height :: non_neg_integer(),
          :hash => hash :: Types.Hash.t(),
          optional(:events) =>
            events :: %{
              optional(transaction_index()) => [event_log_index()]
            }
        }

  @typedoc """
  Incoming events.
  """
  @type events :: [event()]

  @typedoc """
  Stream option.
  """
  @type option ::
          {:identity, Identity.t()}
          | {:from_height, non_neg_integer() | :latest}
          | {:max_buffer_size, pos_integer()}

  @typedoc """
  Stream options.
  """
  @type options :: [option()]

  @doc """
  Creates a new block stream.

  Options:
  - `identity` - The `Icon.RPC.Identity` to be used. If no identity is used,
  a random one will be created.
  - `from_height` - The block height where the stream should start. Defaults to
    the latest block.
  - `max_buffer_size` - The maximum size of the stream buffer. Defaults to
  `1_000`.
  """
  @spec new_block_stream() :: {:ok, t()} | {:error, Error.t()}
  @spec new_block_stream(event_subscriptions()) ::
          {:ok, t()}
          | {:error, Error.t()}
  @spec new_block_stream(event_subscriptions(), options()) ::
          {:ok, t()}
          | {:error, Error.t()}
  def new_block_stream(events \\ [], options \\ [])

  def new_block_stream(events, options) when is_list(events) do
    new(:block, events, options)
  end

  @doc """
  Creates a new event stream.

  Options:
  - `identity` - The `Icon.RPC.Identity` to be used. If no identity is used,
  a random one will be created.
  - `from_height` - The block height where the stream should start. Defaults to
    the latest block.
  - `max_buffer_size` - The maximum size of the stream buffer. Defaults to
  `1_000`.
  """
  @spec new_event_stream() :: {:ok, t()} | {:error, Error.t()}
  @spec new_event_stream(nil | event_subscription()) ::
          {:ok, t()}
          | {:error, Error.t()}
  @spec new_event_stream(nil | event_subscription(), options()) ::
          {:ok, t()}
          | {:error, Error.t()}
  def new_event_stream(event \\ nil, options \\ [])

  def new_event_stream(nil, options) do
    new(:event, [], options)
  end

  def new_event_stream(event, options) when is_map(event) do
    new(:event, [event], options)
  end

  @doc false
  @spec get(t()) :: stream()
  # Used for testing only.
  def get(stream)

  def get(stream) when is_pid(stream) do
    Agent.get(stream, & &1)
  end

  @doc """
  Gets the unique hash for the stream.
  """
  @spec to_hash(t()) :: pos_integer()
  def to_hash(stream) do
    %__MODULE__{source: source, events: events} = get(stream)

    :erlang.phash2(%{
      source: source,
      events: events,
      stream: stream
    })
  end

  @doc """
  Converts a stream into an `URI.t()`.
  """
  @spec to_uri(t()) :: URI.t()
  def to_uri(stream)

  def to_uri(stream) when is_pid(stream) do
    Agent.get(stream, &do_to_uri/1)
  end

  @spec do_to_uri(stream()) :: URI.t()
  defp do_to_uri(%__MODULE__{source: source, identity: %Identity{node: node}}) do
    url = "#{node}/api/v3/icon_dex/#{source}"
    URI.parse(url)
  end

  @doc """
  Encodes stream to Icon representation.
  """
  @spec encode(t()) :: binary()
  def encode(stream)

  def encode(stream) when is_pid(stream) do
    Agent.get(stream, &do_encode/1)
  end

  @doc """
  Puts new events into the buffer.
  """
  @spec put(t(), [map()]) :: :ok
  def put(stream, events)

  def put(stream, events) when is_pid(stream) and is_list(events) do
    Agent.update(stream, &do_put(&1, events))
  end

  @spec do_put(stream(), [map()]) :: stream()
  defp do_put(%__MODULE__{buffer: buffer} = stream, events)
       when is_list(events) do
    events =
      events
      |> Stream.map(&do_decode(stream, &1))
      |> Enum.reduce(buffer, fn event, queue ->
        case :queue.peek(queue) do
          {:value, ^event} -> queue
          _ -> :queue.in(event, queue)
        end
      end)

    %__MODULE__{stream | buffer: events}
  end

  @doc """
  Pops an `amount` of events from the stream buffer.
  """
  @spec pop(t(), non_neg_integer()) :: events()
  def pop(stream, amount)

  def pop(stream, amount)
      when amount >= 0 do
    Agent.get_and_update(stream, &do_pop(&1, amount))
  end

  @spec do_pop(stream(), non_neg_integer()) :: {events(), stream()}
  defp do_pop(%__MODULE__{buffer: buffer, height: height} = stream, amount)
       when amount >= 0 do
    buffer_size = :queue.len(buffer)
    amount = if buffer_size >= amount, do: amount, else: buffer_size

    {to_pop, new_buffer} = :queue.split(amount, buffer)

    new_height =
      case :queue.peek_r(to_pop) do
        :empty -> height
        {:value, %{height: height}} -> height + 1
      end

    new_stream = %__MODULE__{
      stream
      | buffer: new_buffer,
        height: new_height
    }

    {:queue.to_list(to_pop), new_stream}
  end

  @doc """
  Whether the stream buffer is full or not.
  """
  @spec is_full?(t()) :: boolean()
  def is_full?(stream)

  def is_full?(stream) when is_pid(stream) do
    Agent.get(stream, &do_is_full?/1)
  end

  @spec do_is_full?(stream()) :: boolean()
  def do_is_full?(stream)

  def do_is_full?(%__MODULE__{buffer: buffer, max_buffer_size: max_buffer_size}) do
    :queue.len(buffer) >= max_buffer_size
  end

  @doc """
  Checks space left in the buffer in percentage.
  """
  @spec check_space_left(t()) :: float()
  def check_space_left(stream)

  def check_space_left(stream) when is_pid(stream) do
    Agent.get(stream, &do_check_space_left/1)
  end

  @spec do_check_space_left(stream()) :: float()
  defp do_check_space_left(%__MODULE__{
         buffer: buffer,
         max_buffer_size: max_buffer_size
       }) do
    value = 1.0 - :queue.len(buffer) / max_buffer_size

    if value < 0.0, do: 0.0, else: value
  end

  ##########################
  # Initialization functions

  @spec new(source(), nil | event_subscriptions(), options()) ::
          {:ok, t()} | {:error, Error.t()}
  defp new(source, events, options) do
    identity = options[:identity] || Identity.new()
    max_buffer_size = options[:max_buffer_size] || @max_buffer_size
    from_height = options[:from_height] || :latest
    type = if from_height == :latest, do: :latest, else: :past

    with {:ok, from_height} <- get_height(identity, from_height) do
      stream = %__MODULE__{
        identity: identity,
        source: source,
        events: Enum.map(events, &encode_event/1),
        height: from_height,
        type: type,
        buffer: :queue.new(),
        max_buffer_size: max_buffer_size
      }

      Agent.start_link(fn -> stream end)
    end
  end

  @spec get_height(Identity.t(), :latest | non_neg_integer()) ::
          {:ok, non_neg_integer()}
          | {:error, Error.t()}
  defp get_height(identity, height)

  defp get_height(%Identity{} = identity, :latest) do
    with {:ok, %Types.Block{height: height}} <- Icon.get_block(identity) do
      get_height(identity, height)
    end
  end

  defp get_height(%Identity{} = _identity, height) when height >= 0 do
    {:ok, height}
  end

  ####################
  # Encoding functions

  @spec do_encode(stream()) :: binary()
  defp do_encode(%__MODULE__{
         source: :event,
         height: height,
         events: [event]
       }) do
    event
    |> Map.put(:height, encode_height(height))
    |> Jason.encode!()
  end

  defp do_encode(%__MODULE__{
         source: :block,
         height: height,
         events: [_ | _] = events
       }) do
    Jason.encode!(%{
      height: encode_height(height),
      eventFilters: events
    })
  end

  defp do_encode(%__MODULE__{height: height}) do
    Jason.encode!(%{height: encode_height(height)})
  end

  @spec encode_event(event_subscription()) :: map()
  defp encode_event(%{event: header} = data) when is_binary(header) do
    %{event: header}
    |> maybe_add_addr(data)
    |> maybe_add_indexed(data)
    |> maybe_add_data(data)
  end

  defp encode_event(_data) do
    raise ArgumentError, message: "missing event header"
  end

  @spec maybe_add_addr(map(), event_subscription()) :: map()
  defp maybe_add_addr(event, %{addr: addr}) do
    Map.put(event, :addr, Type.dump!(Types.SCORE, addr))
  end

  defp maybe_add_addr(event, _) do
    event
  end

  @spec maybe_add_indexed(map(), event_subscription()) :: map()
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

  @spec maybe_add_data(map(), event_subscription()) :: map()
  defp maybe_add_data(event, data)

  defp maybe_add_data(%{event: header, indexed: indexed} = event, %{data: data})
       when is_list(indexed) do
    data =
      header
      |> get_types()
      |> Stream.drop(length(indexed))
      |> Stream.zip(data)
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

  @spec encode_height(non_neg_integer()) :: Types.NonNegInteger
  defp encode_height(height) when height >= 0 do
    Type.dump!(Types.NonNegInteger, height)
  end

  ####################
  # Decoding functions

  @spec do_decode(stream(), map()) :: event() | no_return()
  defp do_decode(stream, event)

  defp do_decode(%__MODULE__{} = stream, %{"index" => _} = raw_event) do
    %{
      height: {:non_neg_integer, required: true},
      hash: {:hash, required: true},
      index: {:non_neg_integer, required: true},
      events: {list(:non_neg_integer), required: true}
    }
    |> Schema.generate()
    |> Schema.new(raw_event)
    |> Schema.load()
    |> Schema.apply()
    |> case do
      {:ok, event} ->
        expand_indexes(stream, event)

      {:error, reason} ->
        raise RuntimeError,
          message: "cannot decode incoming event: #{inspect(reason)}"
    end
  end

  defp do_decode(%__MODULE__{} = stream, raw_event) do
    %{
      height: {:non_neg_integer, required: true},
      hash: {:hash, required: true},
      indexes: list(list(:non_neg_integer)),
      events: list(list(list(:non_neg_integer)))
    }
    |> Schema.generate()
    |> Schema.new(raw_event)
    |> Schema.load()
    |> Schema.apply()
    |> case do
      {:ok, event} ->
        expand_indexes(stream, event)

      {:error, reason} ->
        raise RuntimeError,
          message: "cannot decode incoming event: #{inspect(reason)}"
    end
  end

  @spec expand_indexes(stream(), raw_event | raw_block__event) :: event()
        when raw_block__event: %{
               :height => height :: non_neg_integer(),
               :hash => hash :: Types.Hash.t(),
               optional(:indexes) => indexes :: [[non_neg_integer()]],
               optional(:events) => events :: [[[non_neg_integer()]]]
             },
             raw_event: %{
               :height => height :: non_neg_integer(),
               :hash => hash :: Types.Hash.t(),
               optional(:index) => index :: non_neg_integer(),
               optional(:events) => events :: [non_neg_integer()]
             }
  defp expand_indexes(stream, raw_event)

  defp expand_indexes(
         %__MODULE__{events: [_subscription]},
         %{index: index, events: events} = raw_event
       ) do
    %{
      height: raw_event.height,
      hash: raw_event.hash,
      events: Map.put(%{}, index, events)
    }
  end

  defp expand_indexes(
         %__MODULE__{events: subscriptions},
         %{indexes: indexes, events: events} = raw_event
       )
       when is_list(indexes) and is_list(events) do
    events =
      subscriptions
      |> Stream.zip(indexes)
      |> Stream.zip(events)
      |> Stream.map(fn {{_subscription, indexes}, events} ->
        indexes
        |> Enum.zip(events)
        |> Map.new()
      end)
      |> Enum.reduce(%{}, fn event, acc ->
        Map.merge(acc, event, fn _k, v1, v2 ->
          v1
          |> Kernel.++(v2)
          |> Enum.dedup()
        end)
      end)

    %{
      height: raw_event.height,
      hash: raw_event.hash,
      events: events
    }
  end

  defp expand_indexes(%__MODULE__{} = _stream, %{height: height, hash: hash}) do
    %{
      height: height,
      hash: hash
    }
  end
end
