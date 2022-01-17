defmodule Icon.Schema.Types.Timestamp do
  @moduledoc """
  This module defines an ICON 2.0 timestamp.
  """
  use Icon.Schema.Type

  @typedoc """
  A timestamp.
  """
  @type t :: DateTime.t()

  @spec load(any()) :: {:ok, t()} | :error
  @impl Icon.Schema.Type
  def load(value)

  def load("0x" <> hex) do
    with {timestamp, ""} <- Integer.parse(hex, 16) do
      load(timestamp)
    end
  end

  def load(timestamp) when is_integer(timestamp) and timestamp >= 0 do
    with {:error, _} <- DateTime.from_unix(timestamp, :microsecond) do
      :error
    end
  end

  def load(%DateTime{} = datetime) do
    {:ok, datetime}
  end

  def load(_value) do
    :error
  end

  @spec dump(any()) :: {:ok, binary()} | :error
  @impl Icon.Schema.Type
  def dump(value)

  def dump(%DateTime{} = datetime) do
    datetime
    |> DateTime.to_unix(:microsecond)
    |> dump()
  end

  def dump(timestamp)
      when is_integer(timestamp) and timestamp >= -377_705_116_800_000_000 do
    Icon.Schema.Types.Integer.dump(timestamp)
  end

  def dump(_) do
    :error
  end
end
