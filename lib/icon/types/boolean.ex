defmodule Icon.Types.Boolean do
  @moduledoc """
  This module defines an ICON 2.0 boolean.
  """
  use Ecto.Type

  @typedoc """
  An boolean.
  """
  @type t :: boolean()

  @spec type() :: :boolean
  @impl Ecto.Type
  def type, do: :boolean

  @spec cast(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  def cast(value)
  def cast(bool) when is_boolean(bool), do: {:ok, bool}
  def cast("0x" <> _ = value), do: load(value)
  def cast(_value), do: :error

  @spec load(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  def load(value)

  def load("0x0"), do: {:ok, false}
  def load("0x1"), do: {:ok, true}
  def load(_value), do: :error

  @spec dump(any()) :: {:ok, binary()} | :error
  @impl Ecto.Type
  def dump(false), do: {:ok, "0x0"}
  def dump(true), do: {:ok, "0x1"}
  def dump(_value), do: :error
end
