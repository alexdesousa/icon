defmodule Icon.Types.Address do
  @moduledoc """
  This module defines an ICON 2.0 address (either EOA or SCORE).
  """
  use Icon.Types.Schema.Type

  @typedoc """
  An address:
  - 2 bytes prefix either `cx` or `hx`
  - 40 bytes hexadecimal lowercase string.
  """
  @type t :: <<_::336>>

  @spec load(any()) :: {:ok, t()} | :error
  @impl Icon.Types.Schema.Type
  def load(value)

  def load(<<prefix::bytes-size(2), bytes::bytes-size(40)>>)
      when prefix in ["hx", "cx"] do
    do_load(prefix, bytes)
  end

  def load(_value) do
    :error
  end

  @spec do_load(<<_::16>>, <<_::320>>) :: {:ok, t()} | :error
  defp do_load(prefix, bytes) do
    bytes = String.downcase(bytes)

    if String.match?(bytes, ~r/[a-f0-9]+/) do
      {:ok, prefix <> bytes}
    else
      :error
    end
  end

  @spec dump(any()) :: {:ok, t()} | :error
  @impl Icon.Types.Schema.Type
  defdelegate dump(address), to: __MODULE__, as: :load
end
