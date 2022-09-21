defmodule Icon.Stream do
  @moduledoc """
  This module defines an Icon websocket stream.
  """
  alias Icon.RPC.Identity

  alias Icon.Schema.{
    Error,
    Type,
    Types,
    Types.Block,
    Types.Block.Tick,
    Types.SCORE
  }

  @max_buffer_size 1_000

  @doc """
  An Icon websocket stream representation.
  """
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
  An Icon websocket stream.
  """
  @type t :: %__MODULE__{
          identity: identity :: Identity.t(),
          source: source :: source(),
          events: events :: events(),
          height: height :: non_neg_integer(),
          type: height_type :: :latest | :past,
          buffer: buffer :: :queue.queue(Tick.t()),
          max_buffer_size: buffer_size :: pos_integer()
        }

  @typedoc """
  Event source type
  """
  @type source ::
          :block
          | :event

  @typedoc """
  Event.
  """
  @type event :: %{
          required(:event) => binary(),
          optional(:addr) => SCORE.t(),
          optional(:indexed) => [any()],
          optional(:data) => [any()]
        }

  @typedoc """
  Events.
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
  @spec new_block_stream(events()) :: {:ok, t()} | {:error, Error.t()}
  @spec new_block_stream(events(), options()) ::
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
  @spec new_event_stream(nil | event()) :: {:ok, t()} | {:error, Error.t()}
  @spec new_event_stream(nil | event(), options()) ::
          {:ok, t()}
          | {:error, Error.t()}
  def new_event_stream(event \\ nil, options \\ [])

  def new_event_stream(nil, options) do
    new(:event, [], options)
  end

  def new_event_stream(event, options) when is_map(event) do
    new(:event, [event], options)
  end

  @doc """
  Converts a stream into an `URI.t()`.
  """
  @spec to_uri(t()) :: URI.t()
  def to_uri(stream)

  def to_uri(%__MODULE__{source: source, identity: %Identity{node: node}}) do
    url = "#{node}/api/v3/icon_dex/#{source}"
    URI.parse(url)
  end

  @doc """
  Encodes stream to Icon representation.
  """
  @spec encode(t()) :: binary()
  def encode(stream)

  def encode(%__MODULE__{
        source: :event,
        height: height,
        events: [event]
      }) do
    event
    |> Map.put(:height, encode_height(height))
    |> Jason.encode!()
  end

  def encode(%__MODULE__{
        source: :block,
        height: height,
        events: [_ | _] = events
      }) do
    Jason.encode!(%{
      height: encode_height(height),
      eventFilters: events
    })
  end

  def encode(%__MODULE__{height: height}) do
    Jason.encode!(%{height: encode_height(height)})
  end

  @doc """
  Puts new ticks into the buffer.
  """
  @spec put(t(), [Tick.t()]) :: t()
  def put(stream, ticks)

  def put(%__MODULE__{buffer: buffer} = stream, ticks)
      when is_list(ticks) do
    %__MODULE__{stream | buffer: Enum.reduce(ticks, buffer, &:queue.in/2)}
  end

  @doc """
  Pops an `amount` of `Tick.t()` from the stream buffer.
  """
  @spec pop(t(), non_neg_integer()) :: {[Tick.t()], t()}
  def pop(stream, amount)

  def pop(%__MODULE__{buffer: buffer, height: height} = stream, amount)
      when amount >= 0 do
    buffer_size = :queue.len(buffer)
    amount = if buffer_size >= amount, do: amount, else: buffer_size

    {to_pop, new_buffer} = :queue.split(amount, buffer)

    new_height =
      case :queue.peek_r(to_pop) do
        :empty ->
          height

        {:value, %Tick{height: height}} ->
          height
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

  def is_full?(%__MODULE__{buffer: buffer, max_buffer_size: max_buffer_size}) do
    :queue.len(buffer) >= max_buffer_size
  end

  @doc """
  Checks space left in the buffer in percentage.
  """
  @spec check_space_left(t()) :: float()
  def check_space_left(stream)

  def check_space_left(%__MODULE__{
        buffer: buffer,
        max_buffer_size: max_buffer_size
      }) do
    value = 1.0 - :queue.len(buffer) / max_buffer_size

    if value < 0.0, do: 0.0, else: value
  end

  ##################
  # Helper functions

  @spec new(source(), nil | events(), options()) ::
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

      {:ok, stream}
    end
  end

  @spec get_height(Identity.t(), :latest | non_neg_integer()) ::
          {:ok, non_neg_integer()}
          | {:error, Error.t()}
  defp get_height(identity, height)

  defp get_height(%Identity{} = identity, :latest) do
    with {:ok, %Block{height: height}} <- Icon.get_block(identity) do
      get_height(identity, height)
    end
  end

  defp get_height(%Identity{} = _identity, height) when height >= 0 do
    {:ok, height}
  end

  @spec encode_event(event()) :: map()
  defp encode_event(%{event: header} = data) when is_binary(header) do
    %{event: header}
    |> maybe_add_addr(data)
    |> maybe_add_indexed(data)
    |> maybe_add_data(data)
  end

  defp encode_event(_data) do
    raise ArgumentError, message: "missing event header"
  end

  @spec maybe_add_addr(map(), event()) :: map()
  defp maybe_add_addr(event, %{addr: addr}) do
    Map.put(event, :addr, Type.dump!(Icon.Schema.Types.SCORE, addr))
  end

  defp maybe_add_addr(event, _) do
    event
  end

  @spec maybe_add_indexed(map(), event()) :: map()
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

  @spec maybe_add_data(map(), event()) :: map()
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

  @spec encode_height(non_neg_integer()) :: Types.Integer
  defp encode_height(height) when height >= 0 do
    Type.dump!(Types.Integer, height)
  end
end
