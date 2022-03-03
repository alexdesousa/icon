defmodule Icon.Schema.Types.Block.Tick do
  @moduledoc """
  This module defines a minimal block that only has two keys:

  Key      | Type                            | Description
  :------- | :------------------------------ | :----------
  `hash`   | `Icon.Schema.Types.Hash.t()`    | Block hash.
  `height` | `Icon.Schema.Types.Integer.t()` | Block height.
  """
  use Icon.Schema

  defschema(%{
    hash: :hash,
    height: :integer
  })
end
