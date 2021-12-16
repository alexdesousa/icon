defmodule Icon.Schema.Loader do
  @moduledoc false
  alias Icon.Schema

  # Generates a schema loader.
  @spec loader(atom(), Schema.internal_type(), keyword()) ::
          (Schema.t() -> Schema.t())
  def loader(key, type, options) do
    fn %Schema{} = state ->
      state
      |> Schema.retrieve(key, options).()
      |> load(key, type, options).()
    end
  end

  #########
  # Helpers

  @spec load(atom(), Schema.internal_type(), keyword()) ::
          (Schema.state() -> Schema.state())
  defp load(key, module, options)

  defp load(key, module, _options) when is_atom(module) do
    fn %Schema{} = state ->
      if function_exported?(module, :__schema__, 0) do
        load_schema(state, key, module.__schema__())
      else
        load_type(state, key, module)
      end
    end
  end

  defp load(key, {:enum, values}, _options) do
    fn %Schema{} = state ->
      load_enum(state, key, values)
    end
  end

  defp load(key, {:list, type}, _options) do
    fn %Schema{} = state ->
      load_list(state, key, type)
    end
  end

  defp load(key, {:any, types, field}, _options) do
    fn %Schema{} = state ->
      load_any(state, key, types, field: field)
    end
  end

  defp load(key, schema, _options) when is_map(schema) do
    fn %Schema{} = state ->
      load_schema(state, key, schema)
    end
  end

  @spec load_schema(Schema.state(), atom(), Schema.t()) :: Schema.state()
  defp load_schema(state, key, schema)

  defp load_schema(%Schema{} = state, key, schema) do
    validator = fn params ->
      schema
      |> Schema.new(params)
      |> Schema.load()
    end

    with {:found, params} <- Schema.get_value(state, key),
         %Schema{data: data, is_valid?: true} = state <- validator.(params) do
      Schema.add_data(state, key, data)
    else
      :miss ->
        state

      %Schema{errors: errors, is_valid?: false} ->
        Schema.add_error(state, key, errors)
    end
  end

  @spec load_type(Schema.state(), atom(), module()) :: Schema.state()
  defp load_type(%Schema{} = state, key, module) do
    with {:found, value} <- Schema.get_value(state, key),
         {:ok, loaded} <- module.load(value) do
      Schema.add_data(state, key, loaded)
    else
      :miss ->
        state

      _ ->
        Schema.add_error(state, key, :is_invalid)
    end
  end

  @spec load_enum(Schema.state(), atom(), [atom()]) :: Schema.state()
  defp load_enum(%Schema{} = state, key, values) do
    with {:found, value} <- Schema.get_value(state, key),
         choice when not is_nil(choice) <-
           Enum.find(values, &("#{&1}" == value or &1 == value)) do
      Schema.add_data(state, key, choice)
    else
      :miss ->
        state

      _ ->
        Schema.add_error(state, key, :is_invalid)
    end
  end

  @spec load_list(Schema.state(), atom(), Schema.internal_type()) ::
          Schema.state()
  defp load_list(state, key, type)

  defp load_list(%Schema{} = state, key, type) do
    loader = fn value ->
      %{__value__: type}
      |> Schema.generate()
      |> Schema.new(%{__value__: value})
      |> Schema.load()
      |> Schema.apply()
      |> case do
        {:ok, %{__value__: loaded}} ->
          {:ok, loaded}

        {:error, _} ->
          :error
      end
    end

    with {:found, values} <- Schema.get_value(state, key),
         loaded = Enum.map(values, loader),
         false <- Enum.any?(loaded, &(&1 == :error)) do
      loaded = Enum.map(loaded, &elem(&1, 1))

      Schema.add_data(state, key, loaded)
    else
      :miss ->
        state

      _ ->
        Schema.add_error(state, key, :is_invalid)
    end
  end

  @spec load_any(Schema.state(), atom(), keyword(), keyword()) :: Schema.state()
  defp load_any(%Schema{} = state, key, choices, options) do
    with field when not is_nil(field) <- options[:field],
         loader = state.schema[field].loader,
         %Schema{data: data, is_valid?: true} <- loader.(state),
         value = data[field],
         type when not is_nil(type) <- choices[value] do
      load(key, type, options).(state)
    else
      _ ->
        Schema.add_error(state, key, :is_invalid)
    end
  end
end
