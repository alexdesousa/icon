defmodule Icon.Schema.Type do
  @moduledoc """
  This module defines a behaviour for schema types.

  This types are compatible with `Icon.Schema` defined schemas.

  ## Behaviour

  The behaviour is simplified version of `Ecto.Type`. The only callbacks to
  implement are:

  - `load/1` for loading the data from ICON 2.0 protocol format.
  - `dump/1` for dumping the data into ICON 2.0 protocol format.

  e.g. we can implement an ICON 2.0 boolean as follows:

  ```elixir
  defmodule Bool do
    use Icon.Schema.Type

    @impl Icon.Schema.Type
    def load("0x0"), do: {:ok, false}
    def load("0x1"), do: {:ok, true}
    def load(_), do: :error

    @impl Icon.Schema.Type
    def dump(false), do: {:ok, "0x0"}
    def dump(true), do: {:ok, "0x1"}
    def dump(_), do: :error
  end
  ```

  ## Delegated type

  Sometimes we need want to have an alias for a type for documentation purposes.
  That can be accomplished by delegating the callbacks to another type e.g. if
  we want to highlight an `:integer` is in loop (1 ICX = 10¹⁸ loop), we can do
  the following:

  ```elixir
  defmodule Loop do
    use Icon.Schema.Type, delegate_to: Icon.Schema.Types.Integer
  end
  ```
  """

  @doc """
  Callback for loading the external type into Elixir type.
  """
  @callback load(any()) :: {:ok, any()} | :error

  @doc """
  Callback for dumping the Elixir type into external type.
  """
  @callback dump(any()) :: {:ok, any()} | :error

  @doc """
  Uses the `Icon.Schema.Type` behaviour.
  """
  @spec __using__(any()) :: Macro.t()
  defmacro __using__(options) do
    delegate = options[:delegate_to]

    quote bind_quoted: [delegate: delegate] do
      @behaviour Icon.Schema.Type

      if not is_nil(delegate) do
        if {:module, delegate} == Code.ensure_compiled(delegate) do
          @impl Icon.Schema.Type
          defdelegate load(value), to: delegate

          @impl Icon.Schema.Type
          defdelegate dump(value), to: delegate

          defoverridable load: 1, dump: 1
        else
          raise ArgumentError, message: "delegate module is not compiled"
        end
      end
    end
  end

  @doc """
  Loads a type from some `value` using a `module`.
  """
  @spec load(module(), any()) :: {:ok, any()} | :error
  def load(module, value), do: module.load(value)

  @doc """
  It's the same as `load/2` but it raises when the `value` is not valid.
  """
  @spec load!(module(), any()) :: any()
  def load!(module, value) do
    case load(module, value) do
      {:ok, value} -> value
      :error -> raise ArgumentError, message: "cannot load type"
    end
  end

  @doc """
  Dumps a type from some `value` using a `module`.
  """
  @spec dump(module(), any()) :: {:ok, any()} | :error
  def dump(module, value), do: module.dump(value)

  @doc """
  It's the same as `dump/2` but it raises when the `value` is not valid.
  """
  @spec dump!(module(), any()) :: any()
  def dump!(module, value) do
    case dump(module, value) do
      {:ok, value} -> value
      :error -> raise ArgumentError, message: "cannot dump type"
    end
  end

  @doc """
  Helper function to convert a map with binary keys to a map with atom keys.
  """
  @spec to_atom_map(map() | any()) :: map()
  def to_atom_map(map)

  def to_atom_map(map) when is_map(map) do
    map
    |> Stream.map(fn {key, value} = pair ->
      if is_binary(key), do: {String.to_existing_atom(key), value}, else: pair
    end)
    |> Stream.map(fn {key, value} -> {key, to_atom_map(value)} end)
    |> Map.new()
  end

  def to_atom_map(list) when is_list(list) do
    Enum.map(list, &to_atom_map/1)
  end

  def to_atom_map(value) do
    value
  end
end
