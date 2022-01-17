defmodule Icon.Schema.Types.Transaction.Status do
  @moduledoc """
  This module defines a transaction status.
  """
  use Icon.Schema.Type

  @typedoc """
  A transaction status.
  """
  @type t() :: :success | :failure

  @spec load(any()) :: {:ok, t()} | :error
  @impl Icon.Schema.Type
  def load(0), do: load(:failure)
  def load(1), do: load(:success)
  def load(value) when value in [:success, :failure], do: {:ok, value}

  def load("0x" <> _ = value) do
    with {:ok, value} <- Icon.Schema.Types.Integer.load(value) do
      load(value)
    end
  end

  def load(_) do
    :error
  end

  @spec dump(any()) :: {:ok, binary()} | :error
  @impl Icon.Schema.Type
  def dump(value)

  def dump(:failure), do: dump(0)
  def dump(:success), do: dump(1)
  def dump(0), do: Icon.Schema.Types.Integer.dump(0)
  def dump(1), do: Icon.Schema.Types.Integer.dump(1)

  def dump("0x" <> _ = value) do
    with {:ok, loaded} <- load(value) do
      dump(loaded)
    end
  end

  def dump(_), do: :error
end
