defmodule Icon.Types.String do
  @moduledoc """
  This module defines an ICON 2.0 string.
  """
  use Ecto.Type

  @typedoc """
  A string.
  """
  @type t :: binary()

  @spec type() :: :string
  @impl Ecto.Type
  def type, do: :string

  @spec cast(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  def cast(value)

  def cast(str) when is_binary(str), do: {:ok, str}
  def cast(_value), do: :error

  @spec load(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  defdelegate load(str), to: __MODULE__, as: :cast

  @spec dump(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  defdelegate dump(str), to: __MODULE__, as: :cast
end
