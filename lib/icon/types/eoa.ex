defmodule Icon.Types.EOA do
  @moduledoc """
  This module defines an ICON 2.0 Externally Owned Account (EOA) address.
  """
  use Ecto.Type

  alias Icon.Types.Address

  @typedoc """
  An Externally Owned Account (EOA) address:
  - 2 bytes for the `hx` prefix.
  - 40 bytes for a lowercase hex string.
  """
  @type t :: Address.t()

  @spec type() :: :string
  @impl Ecto.Type
  def type, do: :string

  @spec cast(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  def cast(value)
  def cast(<<"hx", _::bytes-size(40)>> = address), do: Address.cast(address)
  def cast(_value), do: :error

  @spec load(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  defdelegate load(address), to: __MODULE__, as: :cast

  @spec dump(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  defdelegate dump(address), to: __MODULE__, as: :cast
end
