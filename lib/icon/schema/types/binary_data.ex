defmodule Icon.Schema.Types.BinaryData do
  @moduledoc """
  This module defines an ICON 2.0 binary data.
  """
  use Icon.Schema.Type

  @typedoc """
  A binary with:
  - 2 bytes prefix `0x`.
  - hexadecimal lowercase string with even length.
  """
  @type t :: binary()

  @spec load(any()) :: {:ok, t()} | :error
  @impl Icon.Schema.Type
  def load(value)

  def load(<<"0x", x::bytes-size(1), xs::binary>>) do
    Base.decode16("#{x}#{xs}", case: :lower)
  end

  def load(<<_::bytes-size(1), _::binary>> = data) do
    {:ok, data}
  end

  def load(_value) do
    :error
  end

  @spec dump(any()) :: {:ok, t()} | :error
  @impl Icon.Schema.Type
  def dump(<<_::bytes-size(1), _::binary>> = data) do
    encoded = Base.encode16(data, case: :lower)

    {:ok, "0x#{encoded}"}
  end

  def dump(_data) do
    :error
  end
end
