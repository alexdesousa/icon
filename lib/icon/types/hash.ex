defmodule Icon.Types.Hash do
  @moduledoc """
  This module defines an ICON 2.0 hash.
  """
  use Ecto.Type

  @typedoc """
  A hash:
  - 2 bytes for `0x` prefix.
  - 64 bytes hexadecimal lowercase string.
  """
  @type t :: <<_::528>>

  @spec type() :: :string
  @impl Ecto.Type
  def type, do: :string

  @spec cast(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  def cast(value)

  def cast(<<"0x", bytes::bytes-size(64)>>) do
    cast(bytes)
  end

  def cast(<<bytes::bytes-size(64)>>) do
    bytes = String.downcase(bytes)

    if String.match?(bytes, ~r/[a-f0-9]+/) do
      {:ok, "0x#{bytes}"}
    else
      :error
    end
  end

  def cast(_value) do
    :error
  end

  @spec load(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  defdelegate load(hash), to: __MODULE__, as: :cast

  @spec dump(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  defdelegate dump(hash), to: __MODULE__, as: :cast
end
