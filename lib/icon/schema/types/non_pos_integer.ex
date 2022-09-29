defmodule Icon.Schema.Types.NonPosInteger do
  @moduledoc """
  This module defines a non-positive integer.
  """
  use Icon.Schema.Type

  @typedoc """
  A non-positive integer.
  """
  @type t() :: -0 | 0 | neg_integer()

  @spec load(any()) :: {:ok, t()} | :error
  @impl Icon.Schema.Type
  def load(value) do
    case Icon.Schema.Types.Integer.load(value) do
      {:ok, int} when int <= 0 -> {:ok, int}
      _ -> :error
    end
  end

  @spec dump(any()) :: {:ok, binary()} | :error
  @impl Icon.Schema.Type
  def dump(value) do
    case Icon.Schema.Types.Integer.dump(value) do
      {:ok, "0x0"} -> {:ok, "0x0"}
      {:ok, "-0x" <> _ = value} -> {:ok, value}
      _ -> :error
    end
  end
end
