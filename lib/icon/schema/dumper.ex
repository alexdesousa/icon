defmodule Icon.Schema.Dumper do
  @moduledoc false
  alias Icon.Schema
  alias Icon.Schema.Loader

  @spec dumper(atom(), Schema.internal_type(), keyword()) ::
          (Schema.t() -> Schema.t())
  def dumper(key, type, options) do
    fn %Schema{} = state ->
      state
      |> Schema.retrieve(key, options).()
      |> dump(key, type).()
    end
  end

  #########
  # Helpers

  @spec dump(atom(), Schema.internal_type()) ::
          (Schema.state() -> Schema.state())
  defp dump(key, module)

  defp dump(key, module) when is_atom(module) do
    fn %Schema{} = state ->
      if function_exported?(module, :__schema__, 0) do
        dump_schema(state, key, module.__schema__())
      else
        dump_type(state, key, module)
      end
    end
  end

  defp dump(key, {:enum, values}) do
    fn %Schema{} = state ->
      dump_enum(state, key, values)
    end
  end

  defp dump(key, {:list, type}) do
    fn %Schema{} = state ->
      dump_list(state, key, type)
    end
  end

  defp dump(key, {:any, types, field}) do
    fn %Schema{} = state ->
      dump_any(state, key, types, field: field)
    end
  end

  defp dump(key, schema) when is_map(schema) do
    fn %Schema{} = state ->
      dump_schema(state, key, schema)
    end
  end

  @spec dump_schema(Schema.state(), atom(), Schema.t()) :: Schema.state()
  defp dump_schema(state, key, schema)

  defp dump_schema(%Schema{} = state, key, schema) do
    validator = fn params ->
      schema
      |> Schema.new(params)
      |> Schema.dump()
    end

    with {:found, params} <- Schema.get_value(state, key),
         %Schema{data: data, is_valid?: true} <- validator.(params) do
      Schema.add_data(state, key, data)
    else
      :miss ->
        state

      %Schema{errors: errors, is_valid?: false} ->
        Schema.add_error(state, key, errors)
    end
  end

  @spec dump_type(Schema.state(), atom(), module()) :: Schema.state()
  defp dump_type(%Schema{} = state, key, module) do
    with {:found, value} <- Schema.get_value(state, key),
         {:ok, dumped} <- module.dump(value) do
      Schema.add_data(state, key, dumped)
    else
      :miss ->
        state

      _ ->
        Schema.add_error(state, key, :is_invalid)
    end
  end

  @spec dump_enum(Schema.state(), atom(), [atom()]) :: Schema.state()
  defp dump_enum(%Schema{} = state, key, values) do
    with {:found, value} <- Schema.get_value(state, key),
         true <- Enum.any?(values, &("#{&1}" == value or &1 == value)) do
      Schema.add_data(state, key, "#{value}")
    else
      :miss ->
        state

      _ ->
        Schema.add_error(state, key, :is_invalid)
    end
  end

  @spec dump_list(Schema.state(), atom(), Schema.internal_type()) ::
          Schema.state()
  defp dump_list(state, key, type)

  defp dump_list(%Schema{} = state, key, type) do
    dumper = fn value ->
      %{__value__: type}
      |> Schema.generate()
      |> Schema.new(%{__value__: value})
      |> Schema.dump()
      |> Schema.apply()
      |> case do
        {:ok, %{__value__: dumped}} ->
          {:ok, dumped}

        {:error, _} ->
          :error
      end
    end

    with {:found, values} <- Schema.get_value(state, key),
         dumped = Enum.map(values, dumper),
         false <- Enum.any?(dumped, &(&1 == :error)) do
      dumped = Enum.map(dumped, &elem(&1, 1))

      Schema.add_data(state, key, dumped)
    else
      :miss ->
        state

      _ ->
        Schema.add_error(state, key, :is_invalid)
    end
  end

  @spec dump_any(Schema.state(), atom(), keyword(), keyword()) :: Schema.state()
  defp dump_any(%Schema{} = state, key, choices, options) do
    with {:ok, field} <- Loader.load_field(state, options[:field]),
         type when not is_nil(type) <- choices[field] do
      dump(key, type).(state)
    else
      :ok ->
        state

      _ ->
        Schema.add_error(state, key, :is_invalid)
    end
  end
end
