defmodule Icon.Schema do
  @moduledoc """
  This module defines a schema.

  Schemas serve the purpose of validating both requests and responses. The idea
  is to have a map defining the types and validations for our JSON payloads.

  ## Defining Schemas

  A schema can be either anonymous or not. For non-anonymous schemas, we need to
  `use` this module and define a schema using `defschema/1` e.g. the following is
  an (incomplete) transaction.

  ```elixir
  defmodule Transaction do
    use Icon.Schema

    defschema(%{
      from: {:eoa_address, required: true},
      to: {:address, required: true},
      value: {:loop, default: 0}
    })
  end
  ```

  As seen in the previous example, the values change depending on the types and
  options each key has. The available primitive types are:

  - `:address` (same as `Icon.Schema.Types.Address`).
  - `:any` (does nothing with the data).
  - `:binary_data` (same as `Icon.Schema.Types.BinaryData`).
  - `:boolean` (same as `Icon.Schema.Types.Boolean`).
  - `:eoa_address` (same as `Icon.Schema.Types.EOA`).
  - `:error` (same as `Icon.Schema.Error`).
  - `:event_log` (same as `Icon.Schema.Types.EventLog`).
  - `:hash` (same as `Icon.Schema.Types.Hash`).
  - `:integer` (same as `Icon.Schema.Types.Integer`).
  - `:loop` (same as `Icon.Schema.Types.Loop`).
  - `:neg_integer` (same as `Icon.Schema.Types.NegInteger`)
  - `:non_neg_integer` (same as `Icon.Schema.Types.NonNegInteger`)
  - `:non_pos_integer` (same as `Icon.Schema.Types.NonPosInteger`)
  - `:pos_integer` (same as `Icon.Schema.Types.PosInteger`).
  - `:score_address` (same as `Icon.Schema.Types.SCORE`).
  - `:signature` (same as `Icon.Schema.Types.Signature`).
  - `:string` (same as `Icon.Schema.Types.String`).
  - `:timestamp` (same as `Icon.Schema.Types.Timestamp`).
  - `enum([atom()])` (same as `{:enum, [atom()]}`).

  Then we have complex types:

  - Anonymous schema: `t()`.
  - A homogeneous list of type `t`: `list(t)`.
  - Any of the types listed in the list: `any([{atom(), t}], atom())`. The first
  atom is the value of the second atom in the params.

  Additionally, we can implement our own primite types and named schemas with
  the `Icon.Schema.Type` behaviour and this behaviour respectively. The
  module name should be used as the actual type.

  The available options are the following:

  - `default` - Default value for the key. It can be a closure for late binding.
  - `required` - Whether the key is required or not.
  - `field` - Name of the key to check to choose the right `any()` type. This
  value should be an `atom()`, so it'll probably come from an `enum()` type.

  > Note: `nil` and `""` are considered empty values. They will be ignored for
  > not mandatory keys and will add errors for mandatory keys.

  ## Variable Keys

  In certain cases, the keys of a map will not be defined in advaced. The
  wildcard key `":$variable"` can be used to catch those variable keys e.g. the
  following schema defines a map of variable keys that map to `:loop` values:

  ```elixir
  %{"$variable": :loop}
  ```

  So, if we get the following:

  ```elixir
  %{
    "0" => "0x2a",
    "1" => "0x54"
  }
  ```

  it will load it as follows:

  ```elixir
  %{
    "0" => 42,
    "1" => 84
  }
  ```

  ## Schema Caching

  When a schema is generated with the function `generate/1`, it is also cached
  as a `:persistent_term` in order to avoid generating the same thing twice.
  This makes the first schema generation slower, but accessing the generated
  schema should be then quite fast.

  ## Schema Struct

  When defining a schema with `use Icon.Schema`, we can use the `apply/2`
  function to put the loaded data into the struct e.g. for the following schema:

  ```elixir
  defmodule Block do
    use Icon.Schema

    defschema(%{
      height: :non_neg_integer,
      hash: :hash
      transactions: list(Transaction)
    })
  end
  ```

  we can then validate a payload with the following:

  ```elixir
  payload = %{
    "height" => "0x2a",
    "hash" => "c71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
    "transactions" => [
      %{
        "from" => "hxbe258ceb872e08851f1f59694dac2558708ece11",
        "to" => "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        "value" => "0x2a"
      }
    ]
  }

  {
    :ok,
    %Block{
      height: 42,
      hash: "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238",
      transactions: [
        %Transaction{
          from: "hxbe258ceb872e08851f1f59694dac2558708ece11",
          to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
          value: 42
        }
      ]
    }
  } =
    Block
    |> Icon.Schema.generate()
    |> Icon.Schema.new(payload)
    |> Icon.Schema.load()
    |> Icon.Schema.apply(into: Block)
  ```
  """
  alias __MODULE__, as: Schema
  alias Icon.Schema.Error
  alias Icon.Schema.{Dumper, Loader}

  @typedoc """
  Schema.
  """
  @type t :: module() | map()

  @typedoc """
  Type.
  """
  @type type ::
          external_type()
          | {external_type(), keyword()}

  @typedoc """
  External types.
  """
  @type external_type ::
          internal_type()
          | {:list, external_type()}
          | {:any, [{atom(), external_type()}], atom()}
          | {:enum, [atom()]}
          | :address
          | :any
          | :binary_data
          | :boolean
          | :eoa_address
          | :error
          | :event_log
          | :hash
          | :integer
          | :loop
          | :neg_integer
          | :non_neg_integer
          | :non_pos_integer
          | :pos_integer
          | :score_address
          | :signature
          | :string
          | :timestamp

  @typedoc """
  Internal types.
  """
  @type internal_type ::
          {:list, internal_type()}
          | {:any, [{atom(), internal_type()}], atom()}
          | {:enum, [atom()]}
          | t()
          | Icon.Schema.Error
          | Icon.Schema.Types.Address
          | Icon.Schema.Types.Any
          | Icon.Schema.Types.BinaryData
          | Icon.Schema.Types.Boolean
          | Icon.Schema.Types.EOA
          | Icon.Schema.Types.EventLog
          | Icon.Schema.Types.Hash
          | Icon.Schema.Types.Integer
          | Icon.Schema.Types.Loop
          | Icon.Schema.Types.PosInteger
          | Icon.Schema.Types.SCORE
          | Icon.Schema.Types.Signature
          | Icon.Schema.Types.String
          | Icon.Schema.Types.Timestamp
          | module()

  ##############
  # Schema state

  @doc """
  Schema state.
  """
  defstruct schema: %{},
            params: %{},
            data: %{},
            errors: %{},
            is_valid?: true

  @typedoc """
  Schema state.
  """
  @type state :: %Schema{
          schema: t(),
          params: map(),
          data: map(),
          errors: map(),
          is_valid?: boolean()
        }

  @doc false
  @spec add_data(state(), atom(), any()) :: state()
  def add_data(state, key, value)

  def add_data(%Schema{data: data} = state, key, value) do
    %{state | data: Map.put(data, key, value)}
  end

  @doc false
  @spec add_error(state(), atom(), :is_required | :is_invalid | map()) ::
          state()
  def add_error(state, key, type)

  def add_error(%Schema{errors: errors} = state, key, :is_required) do
    %{state | errors: Map.put(errors, key, "is required"), is_valid?: false}
  end

  def add_error(%Schema{errors: errors} = state, key, :is_invalid) do
    %{state | errors: Map.put(errors, key, "is invalid"), is_valid?: false}
  end

  def add_error(%Schema{errors: errors} = state, key, inner_errors)
      when is_map(inner_errors) do
    %{state | errors: Map.put(errors, key, inner_errors), is_valid?: false}
  end

  @doc false
  @spec get_value(state(), atom()) :: {:found, any()} | :miss
  def get_value(%Schema{data: data}, key) do
    case data[key] do
      nil -> :miss
      value -> {:found, value}
    end
  end

  @doc false
  @spec retrieve(atom(), keyword()) :: (state() -> state())
  def retrieve(key, options)

  def retrieve(:"$variable", _options) do
    fn %Schema{params: params} = state ->
      %{state | data: params}
    end
  end

  def retrieve(key, options) do
    fn %Schema{} = state ->
      required? = options[:required] || false
      nullable? = options[:nullable] || false
      default = options[:default]

      default = if is_function(default, 1), do: default.(state), else: default

      state
      |> get_field(key, default)
      |> case do
        value when value in [nil, ""] and required? ->
          add_error(state, key, :is_required)

        value when value in [nil, ""] and not nullable? ->
          state

        value ->
          add_data(state, key, value)
      end
    end
  end

  @spec get_field(state(), binary() | atom(), any()) :: any()
  defp get_field(state, key, default)

  defp get_field(%Schema{params: params}, key, default)
       when is_map_key(params, key) do
    value = params[key]

    if value in [nil, ""], do: default, else: value
  end

  defp get_field(%Schema{} = state, key, default) when is_atom(key) do
    get_field(state, "#{key}", default)
  end

  defp get_field(%Schema{}, _key, default) do
    default
  end

  ############
  # Public API

  @doc """
  Callback for defining a schema.
  """
  @callback init() :: t()

  @doc """
  Uses the schema behaviour.
  """
  @spec __using__(any()) :: Macro.t()
  defmacro __using__(_) do
    quote do
      @behaviour Schema
      import Schema, only: [list: 1, any: 2, enum: 1, defschema: 1]

      @spec __schema__() :: Schema.t()
      def __schema__ do
        __MODULE__.init()
        |> Schema.generate()
      end
    end
  end

  @doc """
  Generates a schema and its struct.
  """
  @spec defschema(map()) :: Macro.t()
  defmacro defschema(map) do
    quote do
      @behaviour Access

      @keys Map.keys(unquote(map))

      defstruct @keys

      @type t :: %__MODULE__{}

      @impl Schema
      def init do
        unquote(map)
      end

      @impl Access
      defdelegate fetch(v, key), to: Map

      @impl Access
      defdelegate get_and_update(v, key, func), to: Map

      @impl Access
      defdelegate pop(v, key), to: Map
    end
  end

  @doc """
  Generates a new schema state.
  """
  @spec new(t(), map() | keyword() | any()) :: state()
  def new(schema, params)

  def new(%{"$__SCHEMA__": _} = schema, params) do
    %Schema{schema: schema, params: %{"$__SCHEMA__": params}}
  end

  def new(schema, params) when is_map(params) do
    %Schema{schema: schema, params: params}
  end

  def new(schema, params) when is_list(params) do
    new(schema, Map.new(params))
  end

  @doc """
  Loads data from a schema state.
  """
  @spec load(state()) :: state()
  def load(%Schema{schema: schema} = state) do
    schema
    |> Stream.map(fn {key, %{loader: loader}} -> {key, loader} end)
    |> Enum.reduce(state, fn {_, validator}, state ->
      validator.(state)
    end)
  end

  @doc """
  Dumps data from a schema state.
  """
  @spec dump(state()) :: state()
  def dump(%Schema{schema: schema} = state) do
    schema
    |> Stream.map(fn {key, %{dumper: dumper}} -> {key, dumper} end)
    |> Enum.reduce(state, fn {_, validator}, state ->
      validator.(state)
    end)
  end

  @doc """
  Generates a full `type_or_schema`, given a schema definition. It caches the
  generated schema, to avoid regenarating the same every time.
  """
  @spec generate(type() | t()) :: t() | no_return()
  def generate(type_or_schema)

  def generate({:any, _, _}) do
    raise ArgumentError, message: "any/3 cannot be used as primitive schema"
  end

  def generate({:list, _} = list), do: generate(%{"$__SCHEMA__": list})
  def generate({:enum, _} = enum), do: generate(%{"$__SCHEMA__": enum})
  def generate({_, _} = type), do: generate(%{"$__SCHEMA__": type})

  def generate(primitive)
      when primitive in [
             :address,
             :any,
             :binary_data,
             :boolean,
             :eoa_address,
             :error,
             :event_log,
             :hash,
             :integer,
             :loop,
             :neg_integer,
             :non_neg_integer,
             :non_pos_integer,
             :pos_integer,
             :score_address,
             :signature,
             :string,
             :timestamp
           ] do
    generate(%{"$__SCHEMA__": primitive})
  end

  def generate(module)
      when module in [
             Icon.Schema.Error,
             Icon.Schema.Types.Address,
             Icon.Schema.Types.Any,
             Icon.Schema.Types.BinaryData,
             Icon.Schema.Types.Boolean,
             Icon.Schema.Types.EOA,
             Icon.Schema.Types.EventLog,
             Icon.Schema.Types.Hash,
             Icon.Schema.Types.Integer,
             Icon.Schema.Types.Loop,
             Icon.Schema.Types.NegInteger,
             Icon.Schema.Types.NonNegInteger,
             Icon.Schema.Types.NonPosInteger,
             Icon.Schema.Types.PosInteger,
             Icon.Schema.Types.SCORE,
             Icon.Schema.Types.Signature,
             Icon.Schema.Types.String,
             Icon.Schema.Types.Timestamp
           ] do
    generate(%{"$__SCHEMA__": module})
  end

  def generate(schema) when is_atom(schema) do
    with {:module, module} <- Code.ensure_compiled(schema),
         true <- function_exported?(module, :__schema__, 0),
         true <- function_exported?(module, :init, 0) do
      module.init()
      |> generate()
    else
      _ ->
        raise ArgumentError, message: "Schema #{schema} not found"
    end
  end

  def generate(schema) when is_map(schema) do
    key = {__MODULE__, :erlang.phash2(schema)}

    with :miss <- :persistent_term.get(key, :miss) do
      generated =
        schema
        |> Stream.map(fn {key, type} -> expand(key, type) end)
        |> Map.new()

      :persistent_term.put(key, generated)

      generated
    end
  end

  @doc """
  Applies schema `state`.
  """
  @spec apply(state()) ::
          {:ok, any()}
          | {:error, Error.t()}
  @spec apply(state(), keyword()) ::
          {:ok, any()}
          | {:error, Error.t()}
  def apply(state, options \\ [])

  def apply(%Schema{is_valid?: true, data: %{"$__SCHEMA__": data}}, _options) do
    {:ok, data}
  end

  def apply(%Schema{is_valid?: true, data: data}, options) do
    case options[:into] do
      nil ->
        {:ok, data}

      module ->
        {:ok, into(data, module)}
    end
  end

  def apply(%Schema{is_valid?: false} = state, _options) do
    {:error, Error.new(state)}
  end

  ################
  # Public helpers

  @doc """
  Generates a list of types.
  """
  @spec list(external_type()) :: {:list, external_type()}
  def list(type), do: {:list, type}

  @doc """
  Generates a union of types.
  """
  @spec any([{atom(), external_type()}], atom()) ::
          {:any, [{atom(), external_type()}], atom()}
  def any(types, field), do: {:any, types, field}

  @doc """
  Generates an enum type.
  """
  @spec enum([atom()]) :: {:enum, [atom()]}
  def enum(values), do: {:enum, values}

  ##################
  # Schema expansion

  @spec expand(atom(), type()) ::
          {atom(), %{type: internal_type(), loader: loader, dumper: dumper}}
        when loader: (state() -> state()),
             dumper: (state() -> state())
  defp expand(key, type)

  defp expand(key, {:list, _type} = type), do: expand(key, {type, []})
  defp expand(key, {:enum, _values} = type), do: expand(key, {type, []})
  defp expand(key, {:any, _types, _field} = type), do: expand(key, {type, []})
  defp expand(key, schema) when is_map(schema), do: expand(key, {schema, []})
  defp expand(key, type) when is_atom(type), do: expand(key, {type, []})

  defp expand(key, {type, options}) do
    type = expand_type(key, type)

    expand(key, type, options)
  end

  @spec expand(atom(), internal_type(), keyword()) ::
          {atom(), %{type: internal_type(), loader: loader, dumper: dumper}}
        when loader: (state() -> state()),
             dumper: (state() -> state())
  defp expand(key, type, options) do
    {
      key,
      %{
        type: type,
        loader: Loader.loader(key, type, options),
        dumper: Dumper.dumper(key, type, options)
      }
    }
  end

  @spec expand_type(atom(), external_type()) :: internal_type() | no_return()
  defp expand_type(key, external_type)

  defp expand_type(_key, :address), do: Icon.Schema.Types.Address
  defp expand_type(_key, :any), do: Icon.Schema.Types.Any
  defp expand_type(_key, :binary_data), do: Icon.Schema.Types.BinaryData
  defp expand_type(_key, :boolean), do: Icon.Schema.Types.Boolean
  defp expand_type(_key, :eoa_address), do: Icon.Schema.Types.EOA
  defp expand_type(_key, :error), do: Icon.Schema.Error
  defp expand_type(_key, :event_log), do: Icon.Schema.Types.EventLog
  defp expand_type(_key, :hash), do: Icon.Schema.Types.Hash
  defp expand_type(_key, :integer), do: Icon.Schema.Types.Integer
  defp expand_type(_key, :loop), do: Icon.Schema.Types.Loop
  defp expand_type(_key, :neg_integer), do: Icon.Schema.Types.NegInteger
  defp expand_type(_key, :non_neg_integer), do: Icon.Schema.Types.NonNegInteger
  defp expand_type(_key, :non_pos_integer), do: Icon.Schema.Types.NonPosInteger
  defp expand_type(_key, :pos_integer), do: Icon.Schema.Types.PosInteger
  defp expand_type(_key, :score_address), do: Icon.Schema.Types.SCORE
  defp expand_type(_key, :signature), do: Icon.Schema.Types.Signature
  defp expand_type(_key, :string), do: Icon.Schema.Types.String
  defp expand_type(_key, :timestamp), do: Icon.Schema.Types.Timestamp

  defp expand_type(key, {:enum, values} = type) when is_list(values) do
    if Enum.all?(values, &is_atom/1) do
      type
    else
      raise ArgumentError, message: "#{key} values need to be atoms"
    end
  end

  defp expand_type(_key, schema) when is_map(schema) do
    generate(schema)
  end

  defp expand_type(key, {:list, type}) do
    case expand_type(key, type) do
      {:any, _, _} ->
        raise ArgumentError, message: "Lists do not support any/3 as type"

      expanded_type ->
        {:list, expanded_type}
    end
  end

  defp expand_type(key, {:any, types, field})
       when is_list(types) and is_atom(field) do
    types =
      Enum.map(types, fn {value, type} ->
        {value, expand_type(key, type)}
      end)

    {:any, types, field}
  end

  defp expand_type(key, module) when is_atom(module) do
    case Code.ensure_compiled(module) do
      {:module, module} ->
        module

      _ ->
        raise ArgumentError,
          message: "#{key}'s type (#{module}) is not a valid schema or type"
    end
  end

  @spec into(map(), any()) :: map() | struct() | no_return()
  defp into(data, value)

  defp into(data, value) when is_atom(value) do
    with data when is_map(data) <- data,
         {:module, module} <- Code.ensure_compiled(value),
         true <- function_exported?(module, :__schema__, 0),
         true <- function_exported?(module, :init, 0),
         true <- function_exported?(module, :__struct__, 1) do
      module.init()
      |> Enum.map(fn
        {key, {:list, type}} when is_atom(type) ->
          {key, Enum.map(data[key] || [], fn value -> into(value, type) end)}

        {key, {{:list, type}, _}} when is_atom(type) ->
          {key, Enum.map(data[key] || [], fn value -> into(value, type) end)}

        {key, type} when is_atom(type) ->
          {key, into(data[key], type)}

        {key, {type, _}} when is_atom(type) ->
          {key, into(data[key], type)}

        {key, _type} ->
          {key, data[key]}
      end)
      |> module.__struct__()
    else
      _ ->
        data
    end
  end
end
