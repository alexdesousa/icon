defmodule Icon.Schema.Types.Block do
  @moduledoc """
  This module defines a block.

  A block has the following keys:

  Key                          | Type                                        | Description
  :--------------------------- | :------------------------------------------ | :----------
  `block_hash`                 | `Icon.Schema.Types.Hash.t()`                | Block hash.
  `confirmed_transaction_list` | List of `Icon.Schema.Types.Transaction.t()` | List of confirmed transactions.
  `height`                     | `Icon.Schema.Types.Integer.t()`             | Block height.
  `merkle_tree_root_hash`      | `Icon.Schema.Types.Hash.t()`                | Merkle tree root hash.
  `peer_id`                    | `Icon.Schema.Types.EOA.t()`                 | Unique address of the node.
  `prev_block_hash`            | `Icon.Schema.Types.Hash.t()`                | Previous block hash.
  `signature`                  | `Icon.Schema.Types.Signature.t()`           | Block signature.
  `time_stamp`                 | `Icon.Schema.Types.Timestamp.t()`           | Block timestamp.
  `version`                    | `Icon.Schema.Types.String.t()`              | Block version.
  """
  use Icon.Schema

  alias Icon.Schema.Types.Transaction

  defschema(%{
    version: :string,
    time_stamp: :timestamp,
    signature: :signature,
    prev_block_hash: :hash,
    peer_id: :eoa_address,
    merkle_tree_root_hash: :hash,
    height: :integer,
    block_hash: :hash,
    confirmed_transaction_list: list(Transaction)
  })
end
