defmodule Icon.Types.BinaryData do
  @moduledoc """
  This module defines an ICON 2.0 binary data.
  """
  use Icon.Types.Schema.Type

  @typedoc """
  A binary:
  - 2 bytes prefix either `cx` or `hx`
  - hexadecimal lowercase string with even length.
  """
  @type t :: binary()

  @spec load(any()) :: {:ok, t()} | :error
  @impl Icon.Types.Schema.Type
  def load(value)

  def load("0x" <> data) do
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

  def load(_value) do
    :error
  end

  @spec dump(any()) :: {:ok, t()} | :error
  @impl Icon.Types.Schema.Type
  defdelegate dump(data), to: __MODULE__, as: :load
end
