defmodule Icon.Schema.Types.Transaction.Result do
  @moduledoc """
  This module defines a transaction result.

  A transaction result has the following keys:

  Key                   | Type                                       | Description
  :-------------------- | :----------------------------------------- | :----------
  `blockHash`           | `Icon.Schema.Types.Hash.t()`               | Hash of the block that includes the transaction.
  `blockHeight`         | `Icon.Schema.Types.Integer.t()`            | Height of the block that includes the transaction.
  `cummulativeStepUsed` | `Icon.Schema.Types.Loop.t()`               | Sum of `stepUsed` by this transaction and all preceding transactions in the same block.
  `failure`             | `Icon.Schema.Error.t()`                    | If the status is `:failure`, this key will have the fauilure details.
  `logsBloom`           | `Icon.Schema.Types.BinaryData.t()`         | Bloom filter to quickly retrieve related event logs.
  `scoreAddress`        | `Icon.Schema.Types.SCORE.t()`              | SCORE address if the transaction created a new SCORE.
  `status`              | `Icon.Schema.Types.Transaction.Status.t()` | Whether the transaction succeeded or not.
  `stepPrice`           | `Icon.Schema.Types.Loop.t()`               | The step price used by this transaction.
  `stepUsed`            | `Icon.Schema.Types.Loop.t()`               | The amount of step used by this transaction.
  `to`                  | `Icon.Schema.Types.Address.t()`            | Recipient address of the transaction.
  `txHash`              | `Icon.Schema.Types.Hash.t()`               | Transaction hash.
  `txIndex`             | `Icon.Schema.Types.Integer.t()`            | Transaction index in the block.
  """
  use Icon.Schema

  alias Icon.Schema.Types.Transaction.Status

  defschema(%{
    blockHash: :hash,
    blockHeight: :integer,
    cummulativeStepUsed: :loop,
    failure: :error,
    logsBloom: :binary_data,
    scoreAddress: :score_address,
    status: Status,
    stepPrice: :loop,
    stepUsed: :loop,
    to: :address,
    txHash: :hash,
    txIndex: :integer
  })
end
