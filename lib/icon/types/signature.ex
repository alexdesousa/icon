defmodule Icon.Types.Signature do
  @moduledoc """
  This module defines an ICON 2.0 signature.
  """
  use Ecto.Type

  @typedoc """
  A signature.
  """
  @type t :: binary()

  @spec type() :: :string
  @impl Ecto.Type
  def type, do: :string

  @spec cast(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  def cast(value)

  def cast(signature) when is_binary(signature) do
    case Base.decode64(signature) do
      {:ok, _} ->
        {:ok, signature}

      _ ->
        :error
    end
  end

  def cast(_value) do
    :error
  end

  @spec load(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  defdelegate load(signature), to: __MODULE__, as: :cast

  @spec dump(any()) :: {:ok, t()} | :error
  @impl Ecto.Type
  defdelegate dump(signature), to: __MODULE__, as: :cast
end
