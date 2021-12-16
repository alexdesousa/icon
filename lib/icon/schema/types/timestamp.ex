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

  @spec dump(any()) :: {:ok, t()} | :error
  @impl Icon.Schema.Type
  def dump(value)

  def dump(%DateTime{} = datetime) do
    {:ok, DateTime.to_unix(datetime, :microsecond)}
  end

  def dump(timestamp)
      when is_integer(timestamp) and timestamp >= -377_705_116_800_000_000 do
    {:ok, timestamp}
  end

  def dump(_) do
    :error
  end
end
