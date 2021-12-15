defmodule Icon.Types.String do
  @moduledoc """
  This module defines an ICON 2.0 string.
  """
  use Icon.Types.Schema.Type

  @typedoc """
  A string.
  """
  @type t :: binary()

  @spec load(any()) :: {:ok, t()} | :error
  @impl Icon.Types.Schema.Type
  def load(value)
  def load(str) when is_binary(str), do: {:ok, str}
  def load(_value), do: :error

  @spec dump(any()) :: {:ok, t()} | :error
  @impl Icon.Types.Schema.Type
  defdelegate dump(str), to: __MODULE__, as: :load
end
