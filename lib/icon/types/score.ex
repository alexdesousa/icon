defmodule Icon.Types.SCORE do
  @moduledoc """
  This module defines an ICON 2.0 SCORE address.
  """
  use Ecto.Type

  @typedoc """
  A SCORE address:
  - 2 bytes for the `cx` prefix.
  - 40 bytes for a lowercase hex string.
  """
  @type t :: <<_::336>>

  @spec type() :: :string
  @impl Ecto.Type
  def type, do: :string

  @spec cast(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  def cast(value)

  def cast(<<"cx", bytes::bytes-size(40)>>) do
    bytes = String.downcase(bytes)

    if String.match?(bytes, ~r/[a-f0-9]+/) do
      {:ok, "cx#{bytes}"}
    else
      :error
    end
  end

  def cast(_value) do
    :error
  end

  @spec load(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  defdelegate load(address), to: __MODULE__, as: :cast

  @spec dump(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  defdelegate dump(address), to: __MODULE__, as: :cast
end
