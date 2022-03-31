defmodule Icon.Schema.Types.Integer do
  @moduledoc """
  This module defines an ICON 2.0 integer.
  """
  use Icon.Schema.Type

  @typedoc """
  An integer.
  """
  @type t :: integer()

  @spec load(any()) :: {:ok, t()} | :error
  @impl Icon.Schema.Type
  def load(value)

  def load(int) when is_integer(int) do
    {:ok, int}
  end

  def load("-0x" <> hex) do
    with {:ok, int} <- load("0x" <> hex) do
      {:ok, -int}
    end
  end

  def load("0x" <> hex) do
    case Integer.parse(hex, 16) do
      {int, ""} when int >= 0 -> {:ok, int}
      _ -> :error
    end
  end

  def load(str) when is_binary(str) do
    case Integer.parse(str) do
      {int, ""} -> {:ok, int}
      _ -> :error
    end
  end

  def load(_value) do
    :error
  end

  @spec dump(any()) :: {:ok, binary()} | :error
  @impl Icon.Schema.Type
  def dump(int) when is_integer(int) and int < 0 do
    with {:ok, "0x" <> hex} <- dump(-int) do
      {:ok, "-0x" <> hex}
    end
  end

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
