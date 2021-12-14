defmodule Icon.Types.Schema do
  @moduledoc """
  This module defines a schema.
  """

  @typedoc """
  Schema.
  """
  @type schema :: map()

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
          | {:any, [external_type()]}
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
          | {:any, [internal_type()]}
          | schema()
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

  @doc """
  Uses the schema behaviour.
  """
  @spec __using__(any()) :: Macro.t()
  defmacro __using__(_) do
    quote do
      @behaviour Icon.Types.Schema
      import Icon.Types.Schema, only: [list: 1, any: 1, enum: 1]

      @doc false
      @spec __schema__() :: boolean()
      def __schema__, do: true
    end
  end

  @doc """
  Generates a full `schema`, given a schema definition.
  """
  @spec generate(schema()) :: schema()
  def generate(schema) do
    schema
    |> Stream.map(fn {key, type} -> expand(key, type) end)
    |> Map.new()
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

  @spec expand(atom(), type()) :: {atom(), internal_type()}
  defp expand(key, type)

  defp expand(key, {:list, _type} = type), do: expand(key, {type, []})
  defp expand(key, {:any, _types} = type), do: expand(key, {type, []})
  defp expand(key, {:enum, _values} = type), do: expand(key, {type, []})
  defp expand(key, schema) when is_map(schema), do: expand(key, {schema, []})
  defp expand(key, type) when is_atom(type), do: expand(key, {type, []})

  defp expand(key, {type, options}) do
    type = expand_type(key, type)

    expand(key, type, options)
  end

  @spec expand(atom(), internal_type(), keyword()) ::
          {atom(), {internal_type(), keyword()}}
  defp expand(key, type, options) do
    {key, {type, options}}
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
    {:any, Enum.map(types, &expand_type(key, &1))}
  end

  defp expand_type(key, module) when is_atom(module) do
    with {:module, module} <- Code.ensure_compiled(module),
         true <- function_exported?(module, :__schema__, 0) do
      module
    else
      _ ->
        raise ArgumentError,
          message: "#{key}'s type (#{module})is not a valid schema or type"
    end
  end
end
