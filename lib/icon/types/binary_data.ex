defmodule Icon.Types.BinaryData do
  @moduledoc """
  This module defines an ICON 2.0 binary data.
  """
  use Ecto.Type

  @typedoc """
  A binary:
  - 2 bytes prefix either `cx` or `hx`
  - hexadecimal lowercase string with even length.
  """
  @type t :: binary()

  @spec type() :: :string
  @impl Ecto.Type
  def type, do: :string

  @spec cast(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  def cast(value)

  def cast("0x" <> data) do
    data = String.downcase(data)
    length = String.length(data)

    with true <- length > 2 and rem(length, 2) == 0,
         true <- String.match?(data, ~r/[a-f0-9]+/) do
      {:ok, "0x#{data}"}
    else
      false ->
        :error
    end
  end

  def cast(_value) do
    :error
  end

  @spec load(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  defdelegate load(data), to: __MODULE__, as: :cast

  @spec dump(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  defdelegate dump(data), to: __MODULE__, as: :cast
end
