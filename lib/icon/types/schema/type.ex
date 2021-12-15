defmodule Icon.Types.Schema.Type do
  @moduledoc """
  This module defines a behaviour for schema types.

  This types are compatible with `Icon.Types.Schema` defined schemas.

  ## Behaviour

  The behaviour is simplified version of `Ecto.Type`. The only callbacks to
  implement are:

  - `load/1` for loading the data from ICON 2.0 protocol format.
  - `dump/1` for dumping the data into ICON 2.0 protocol format.

  e.g. we can implement an ICON 2.0 boolean as follows:

  ```elixir
  defmodule Bool do
    use Icon.Types.Schema.Type

    @impl Icon.Types.Schema.Type
    def load("0x0"), do: {:ok, false}
    def load("0x1"), do: {:ok, true}
    def load(_), do: :error

    @impl Icon.Types.Schema.Type
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
    use Icon.Types.Schema.Type, delegate_to: Icon.Types.Integer
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
  Uses the `Icon.Types.Schema.Type` behaviour.
  """
  @spec __using__(any()) :: Macro.t()
  defmacro __using__(options) do
    delegate = options[:delegate_to]

    quote bind_quoted: [delegate: delegate] do
      @behaviour Icon.Types.Schema.Type

      if not is_nil(delegate) and
           {:module, delegate} == Code.ensure_compiled(delegate) do
        @impl Icon.Types.Schema.Type
        defdelegate load(value), to: delegate

        @impl Icon.Types.Schema.Type
        defdelegate dump(value), to: delegate

        defoverridable load: 1, dump: 1
      end
    end
  end
end
