defmodule Icon.Types.Address do
  @moduledoc """
  This module defines an ICON 2.0 address (either EOA or SCORE).
  """
  use Ecto.Type

  @typedoc """
  An address:
  - 2 bytes prefix either `cx` or `hx`
  - 40 bytes hexadecimal lowercase string.
  """
  @type t :: <<_::336>>

  @spec type() :: :string
  @impl Ecto.Type
  def type, do: :string

  @spec cast(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  def cast(value)

  def cast(<<prefix::bytes-size(2), bytes::bytes-size(40)>>)
      when prefix in ["hx", "cx"] do
    do_cast(prefix, bytes)
  end

  def cast(_value) do
    :error
  end

  @spec do_cast(<<_::16>>, <<_::320>>) :: {:ok, t()} | :error
  defp do_cast(prefix, bytes) do
    bytes = String.downcase(bytes)

    if String.match?(bytes, ~r/[a-f0-9]+/) do
      {:ok, prefix <> bytes}
    else
      :error
    end
  end

  @spec load(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  defdelegate load(address), to: __MODULE__, as: :cast

  @spec dump(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  defdelegate dump(address), to: __MODULE__, as: :cast
end
