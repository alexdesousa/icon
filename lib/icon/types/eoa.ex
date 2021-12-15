defmodule Icon.Types.EOA do
  @moduledoc """
  This module defines an ICON 2.0 Externally Owned Account (EOA) address.
  """
  use Icon.Types.Schema.Type

  alias Icon.Types.Address

  @typedoc """
  An Externally Owned Account (EOA) address:
  - 2 bytes for the `hx` prefix.
  - 40 bytes for a lowercase hex string.
  """
  @type t :: Address.t()

  @spec load(any()) :: {:ok, t()} | :error
  @impl Icon.Types.Schema.Type
  def load(value)
  def load(<<"hx", _::bytes-size(40)>> = address), do: Address.load(address)
  def load(_value), do: :error

  @spec dump(any()) :: {:ok, t()} | :error
  @impl Icon.Types.Schema.Type
  defdelegate dump(address), to: __MODULE__, as: :load
end
