defmodule Icon.Types.Boolean do
  @moduledoc """
  This module defines an ICON 2.0 boolean.
  """
  use Icon.Types.Schema.Type

  @typedoc """
  An boolean.
  """
  @type t :: boolean()

  @spec load(any()) :: {:ok, t()} | :error
  @impl Icon.Types.Schema.Type
  def load(value)
  def load(0), do: {:ok, false}
  def load(1), do: {:ok, true}
  def load(false), do: {:ok, false}
  def load(true), do: {:ok, true}
  def load("0x0"), do: {:ok, false}
  def load("0x1"), do: {:ok, true}
  def load(_value), do: :error

  @spec dump(any()) :: {:ok, binary()} | :error
  @impl Icon.Types.Schema.Type
  def dump(false), do: {:ok, "0x0"}
  def dump(true), do: {:ok, "0x1"}
  def dump(_value), do: :error
end
