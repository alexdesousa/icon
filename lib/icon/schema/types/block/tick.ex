defmodule Icon.Schema.Types.Block.Tick do
  @moduledoc """
  This module defines a minimal block that only has two keys:

  Key      | Type                                  | Description
  :------- | :------------------------------------ | :----------
  `hash`   | `Icon.Schema.Types.Hash.t()`          | Block hash.
  `height` | `Icon.Schema.Types.NonNegInteger.t()` | Block height.
  """
  use Icon.Schema

  defschema(%{
    hash: :hash,
    height: :non_neg_integer
  })
end
