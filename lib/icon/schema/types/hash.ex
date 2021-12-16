defmodule Icon.Schema.Types.Hash do
  @moduledoc """
  This module defines an ICON 2.0 hash.
  """
  use Icon.Schema.Type

  @typedoc """
  A hash:
  - 2 bytes for `0x` prefix.
  - 64 bytes hexadecimal lowercase string.
  """
  @type t :: <<_::528>>

  @spec load(any()) :: {:ok, t()} | :error
  @impl Icon.Schema.Type
  def load(value)

  def load(<<"0x", bytes::bytes-size(64)>>) do
    load(bytes)
  end

  def load(<<bytes::bytes-size(64)>>) do
    bytes = String.downcase(bytes)

    if String.match?(bytes, ~r/[a-f0-9]+/) do
      {:ok, "0x#{bytes}"}
    else
      :error
    end
  end

  def load(_value) do
    :error
  end

  @spec dump(any()) :: {:ok, t()} | :error
  @impl Icon.Schema.Type
  defdelegate dump(hash), to: __MODULE__, as: :load
end
