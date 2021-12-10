defmodule Icon.Types.Integer do
  @moduledoc """
  This module defines an ICON 2.0 integer.
  """
  use Ecto.Type

  @typedoc """
  An integer.
  """
  @type t :: non_neg_integer()

  @spec type() :: :integer
  @impl Ecto.Type
  def type, do: :integer

  @spec cast(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  def cast(value)

  def cast(int) when is_integer(int) and int >= 0 do
    {:ok, int}
  end

  def cast("0x" <> _ = value) do
    load(value)
  end

  def cast(str) when is_binary(str) do
    case Integer.parse(str) do
      {int, ""} -> cast(int)
      _ -> :error
    end
  end

  def cast(_value) do
    :error
  end

  @spec load(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  def load(value)

  def load("0x" <> hex) do
    case Integer.parse(hex, 16) do
      {int, ""} -> cast(int)
      _ -> :error
    end
  end

  def load(_value) do
    :error
  end

  @spec dump(any()) :: {:ok, binary()} | :error
  @impl Ecto.Type
  def dump(int) when is_integer(int) and int >= 0 do
    value =
      int
      |> Integer.to_string(16)
      |> String.downcase()

    {:ok, "0x" <> value}
  end

  def dump(_value) do
    :error
  end
end
