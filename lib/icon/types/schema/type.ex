defmodule Icon.Types.Schema.Type do
  @moduledoc """
  This module defines a behaviour for schema types.
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
