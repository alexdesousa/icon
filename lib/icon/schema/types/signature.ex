defmodule Icon.Schema.Types.Signature do
  @moduledoc """
  This module defines an ICON 2.0 signature.
  """
  use Icon.Schema.Type

  @typedoc """
  A signature.
  """
  @type t :: binary()

  @spec load(any()) :: {:ok, t()} | :error
  @impl Icon.Schema.Type
  def load(value)

  def load(signature) when is_binary(signature) do
    case Base.decode64(signature) do
      {:ok, _} ->
        {:ok, signature}

      _ ->
        :error
    end
  end

  def load(_value) do
    :error
  end

  @spec dump(any()) :: {:ok, t()} | :error
  @impl Icon.Schema.Type
  defdelegate dump(signature), to: __MODULE__, as: :load
end
