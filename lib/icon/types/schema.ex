defmodule Icon.Types.Schema do
  @moduledoc """
  This module defines a schema.

  Schemas serve the purpose of validating both requests and responses. The idea
  is to have a map defining the types and validations for our JSON payloads.

  ## Defining Schemas

  A schema can be either anonymous or not. For non-anonymous schemas, we need to
  `use` this module and define the callback `init/1` e.g. the following is an
  (incomplete) transaction.

  ```elixir
  defmodule Transaction do
    use Icon.Types.Schema

    @spec Icon.Types.Schema
    def init do
      %{
        version: {:string, default: "2.0"},
        from: {:eoa_address, required: true},
        to: {:address, required: true},
        value: :integer
        dataType: {enum([:call, :deploy]), required: true},
        data: any(
          [
            call: CallSchema,
            deploy: DeploySchema
          ],
          field: :dataType,
          required: true
        )
      }
    end
  end
  ```

  As seen in the previous example, the values change depending on the types and
  options each key has. The available primitive types are:

  - `:address` (same as `Icon.Types.Address`).
  - `:binary_data` (same as `Icon.Types.BinaryData`).
  - `:boolean` (same as `Icon.Types.Boolean`).
  - `:eoa_address` (same as `Icon.Types.EOA`).
  - `:hash` (same as `Icon.Types.Hash`).
  - `:integer` (same as `Icon.Types.Integer`).
  - `:score_address` (same as `Icon.Types.SCORE`).
  - `:signature` (same as `Icon.Types.Signature`).
  - `:string` (same as `Icon.Types.String`).
  - `enum([atom()])` (same as `{:enum, [atom()]}`).

  Then we have complex types:

  - Anonymous schema: `t()`.
  - A homogeneous list of type `t`: `list(t)`.
  - Any of the types listed in the list: `any([{atom(), t}])`. This type depends on the
  option `field` for choosing the right type.

  Additionally, we can implement our own primite types and named schemas with
  the `Icon.Types.Schema.Type` behaviour and this behaviour respectively. The
  module name should be used as the actual type.

  The available options are the following:

  - `default` - Default value for the key.
  - `required` - Whether the key is required or not.
  - `field` - Name of the key to check to choose the right `any()` type. This
  value should be an `atom()`, so it'll probably come from an `enum()` type.

  > Note: `nil` and `""` are considered empty values. They will be ignored for
  > not mandatory keys and will add errors for mandatory keys.

  ## Schema Caching

  When a schema is generated with the function `generate/1`, it is also cached
  as a `:persistent_term` in order to avoid generating the same thing twice.
  This makes the first schema generation slower, but accessing the generated
  schema should be then quite fast.
  """
  alias __MODULE__, as: State
  alias Icon.Types.Error

  @typedoc """
  Schema.
  """
  @type t :: map()

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
          | {:any, [{atom(), external_type()}]}
          | {:enum, [atom()]}
          | :address
          | :binary_data
          | :boolean
          | :eoa_address
          | :hash
          | :integer
          | :score_address
          | :signature
          | :string

  @typedoc """
  Internal types.
  """
  @type internal_type ::
          {:list, internal_type()}
          | {:any, [{atom(), internal_type()}]}
          | {:enum, [atom()]}
          | t()
          | Icon.Types.Address
          | Icon.Types.BinaryData
          | Icon.Types.Boolean
          | Icon.Types.EOA
          | Icon.Types.Hash
          | Icon.Types.Integer
          | Icon.Types.SCORE
          | Icon.Types.Signature
          | Icon.Types.String
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
  @type state :: %State{
          schema: t(),
          params: map(),
          data: map(),
          errors: map(),
          is_valid?: boolean()
        }

  @spec add_data(state(), atom(), any()) :: state()
  defp add_data(state, key, value)

  defp add_data(%State{data: data} = state, key, value) do
    %{state | data: Map.put(data, key, value)}
  end

  @spec add_error(state(), atom(), :is_required | :is_invalid | map()) ::
          state()
  defp add_error(state, key, type)

  defp add_error(%State{errors: errors} = state, key, :is_required) do
    %{state | errors: Map.put(errors, key, "is required"), is_valid?: false}
  end

  defp add_error(%State{errors: errors} = state, key, :is_invalid) do
    %{state | errors: Map.put(errors, key, "is invalid"), is_valid?: false}
  end

  defp add_error(%State{errors: errors} = state, key, inner_errors)
       when is_map(inner_errors) do
    %{state | errors: Map.put(errors, key, inner_errors), is_valid?: false}
  end

  @spec get_field(state(), binary() | atom(), any()) :: any()
  defp get_field(state, key, default)

  defp get_field(%State{params: params}, key, default)
       when is_map_key(params, key) do
    value = params[key]

    if value in [nil, ""], do: default, else: value
  end

  defp get_field(%State{} = state, key, default) when is_atom(key) do
    get_field(state, "#{key}", default)
  end

  defp get_field(%State{}, _key, default) do
    default
  end

  @spec get_value(state(), atom()) :: {:found, any()} | :miss
  defp get_value(%State{data: data}, key) do
    case data[key] do
      nil -> :miss
      value -> {:found, value}
    end
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
      @behaviour Icon.Types.Schema
      import Icon.Types.Schema, only: [list: 1, any: 1, enum: 1]

      @spec __schema__() :: Icon.Types.Schema.t()
      def __schema__ do
        schema = __MODULE__.init()
        # credo:disable-for-next-line Credo.Check.Design.AliasUsage
        Icon.Types.Schema.generate(schema)
      end
    end
  end

  @doc """
  Generates a new schema state.
  """
  @spec new(t(), map() | keyword()) :: state()
  def new(schema, params)

  def new(schema, params) when is_list(params) do
    new(schema, Map.new(params))
  end

  def new(schema, params) when is_map(params) do
    %State{schema: schema, params: params}
  end

  @doc """
  Validates a schema state.
  """
  @spec validate(state()) :: state()
  def validate(%State{schema: schema} = state) do
    Enum.reduce(schema, state, fn {_, validator}, state ->
      validator.(state)
    end)
  end

  @doc """
  Generates a full `schema`, given a schema definition. It caches the generated
  schema, to avoid regenarating the same every time.
  """
  @spec generate(t()) :: t()
  def generate(schema) do
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
          {:ok, map()}
          | {:error, Error.t()}
  def apply(state)

  def apply(%State{is_valid?: true, data: data}) do
    {:ok, data}
  end

  def apply(%State{is_valid?: false} = state) do
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
  @spec any([external_type()]) :: {:any, [external_type()]}
  def any(types), do: {:any, types}

  @doc """
  Generates an enum type.
  """
  @spec enum([atom()]) :: {:enum, [atom()]}
  def enum(values), do: {:enum, values}

  ##################
  # Schema expansion

  @spec expand(atom(), type()) ::
          {atom(), (state() -> state())}
  defp expand(key, type)

  defp expand(key, {:list, _type} = type), do: expand(key, {type, []})
  defp expand(key, {:enum, _values} = type), do: expand(key, {type, []})
  defp expand(key, schema) when is_map(schema), do: expand(key, {schema, []})
  defp expand(key, type) when is_atom(type), do: expand(key, {type, []})

  defp expand(key, {type, options}) do
    type = expand_type(key, type)

    expand(key, type, options)
  end

  @spec expand(atom(), internal_type(), keyword()) ::
          {atom(), (state() -> state())}
  defp expand(key, type, options) do
    {key, validate(key, type, options)}
  end

  @spec expand_type(atom(), external_type()) :: internal_type() | no_return()
  defp expand_type(key, external_type)

  defp expand_type(_key, :address), do: Icon.Types.Address
  defp expand_type(_key, :binary_data), do: Icon.Types.BinaryData
  defp expand_type(_key, :boolean), do: Icon.Types.Boolean
  defp expand_type(_key, :eoa_address), do: Icon.Types.EOA
  defp expand_type(_key, :hash), do: Icon.Types.Hash
  defp expand_type(_key, :integer), do: Icon.Types.Integer
  defp expand_type(_key, :score_address), do: Icon.Types.SCORE
  defp expand_type(_key, :signature), do: Icon.Types.Signature
  defp expand_type(_key, :string), do: Icon.Types.String

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
    {:list, expand_type(key, type)}
  end

  defp expand_type(key, {:any, types}) when is_list(types) do
    types =
      Enum.map(types, fn {value, type} ->
        {value, expand_type(key, type)}
      end)

    {:any, types}
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

  ##################
  # Schema validator

  @spec validate(atom(), internal_type(), keyword()) :: (t() -> t())
  defp validate(key, type, options) do
    fn %State{} = state ->
      state
      |> retrieve(key, options).()
      |> load(key, type, options).()
    end
  end

  @spec retrieve(atom(), keyword()) :: (t() -> t())
  defp retrieve(key, options) do
    fn %State{} = state ->
      required? = options[:required] || false
      default = options[:default]

      state
      |> get_field(key, default)
      |> case do
        nil when required? ->
          add_error(state, key, :is_required)

        "" when required? ->
          add_error(state, key, :is_required)

        nil ->
          state

        "" ->
          state

        value ->
          add_data(state, key, value)
      end
    end
  end

  #########
  # Loaders

  @spec load(atom(), internal_type(), keyword()) :: (state() -> state())
  defp load(key, module, options)

  defp load(key, module, _options) when is_atom(module) do
    fn %State{} = state ->
      if function_exported?(module, :__schema__, 0) do
        load_schema(state, key, module.__schema__())
      else
        load_type(state, key, module)
      end
    end
  end

  defp load(key, {:enum, values}, _options) do
    fn %State{} = state ->
      load_enum(state, key, values)
    end
  end

  defp load(key, {:list, module}, _options) do
    fn %State{} = state ->
      load_list(state, key, module)
    end
  end

  defp load(key, {:any, types}, options) do
    fn %State{} = state ->
      load_any(state, key, types, options)
    end
  end

  defp load(key, schema, _options) when is_map(schema) do
    fn %State{} = state ->
      load_schema(state, key, schema)
    end
  end

  @spec load_schema(state(), atom(), t()) :: state()
  defp load_schema(state, key, schema)

  defp load_schema(%State{} = state, key, schema) do
    validator = fn params ->
      schema
      |> new(params)
      |> validate()
    end

    with {:found, params} <- get_value(state, key),
         %State{data: data, is_valid?: true} = state <- validator.(params) do
      add_data(state, key, data)
    else
      :miss ->
        state

      %State{errors: errors, is_valid?: false} ->
        add_error(state, key, errors)
    end
  end

  @spec load_type(state(), atom(), module()) :: state()
  defp load_type(%State{} = state, key, module) do
    with {:found, value} <- get_value(state, key),
         {:ok, loaded} <- module.load(value) do
      add_data(state, key, loaded)
    else
      :miss ->
        state

      _ ->
        add_error(state, key, :is_invalid)
    end
  end

  @spec load_enum(state(), atom(), [atom()]) :: state()
  defp load_enum(%State{} = state, key, values) do
    with {:found, value} <- get_value(state, key),
         true <- Enum.any?(values, &("#{&1}" == value)) do
      choice = String.to_existing_atom(value)
      add_data(state, key, choice)
    else
      :miss ->
        state

      _ ->
        add_error(state, key, :is_invalid)
    end
  end

  @spec load_list(state(), atom(), module()) :: state()
  defp load_list(%State{} = state, key, module) do
    with {:found, values} <- get_value(state, key),
         loaded = Enum.map(values, &module.load/1),
         false <- Enum.any?(loaded, &(&1 == :error)) do
      loaded = Enum.map(loaded, &elem(&1, 1))

      add_data(state, key, loaded)
    else
      :miss ->
        state

      _ ->
        add_error(state, key, :is_invalid)
    end
  end

  @spec load_any(state(), atom(), keyword(), keyword()) :: state()
  defp load_any(%State{} = state, key, choices, options) do
    with field when not is_nil(field) <- options[:field],
         %State{data: data, is_valid?: true} <- state.schema[field].(state),
         value = data[field],
         type when not is_nil(type) <- choices[value] do
      load(key, type, options).(state)
    else
      _ ->
        add_error(state, key, :is_invalid)
    end
  end
end
