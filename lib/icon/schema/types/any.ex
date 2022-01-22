defmodule Icon.Schema.Types.Any do
  @moduledoc """
  This module defines an any type.
  """
  use Icon.Schema.Type

  @typedoc """
  Any type.
  """
  @type t :: any()

  @spec load(any()) :: {:ok, any()}
  @impl Icon.Schema.Type
  def load(value), do: {:ok, value}

  @spec dump(any()) :: {:ok, any()}
  @impl Icon.Schema.Type
  def dump(value), do: {:ok, value}
end
