defmodule Icon.Schema.Types.Loop do
  @moduledoc """
  This module defines a loop (1 ICX = 10¹⁸ loop).
  """
  use Icon.Schema.Type

  @typedoc """
  A loop (1 ICX = 10¹⁸ loop).
  """
  @type t() :: Icon.Schema.Types.Integer.t()

  @spec load(any()) :: {:ok, t()} | :error
  @impl Icon.Schema.Type
  defdelegate load(value), to: Icon.Schema.Types.Integer

  @spec dump(any()) :: {:ok, t()} | :error
  @impl Icon.Schema.Type
  defdelegate dump(value), to: Icon.Schema.Types.Integer
end
