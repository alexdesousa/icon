defmodule Icon.Schema.Types.Transaction do
  @moduledoc """
  This module defines a transaction.

  A transaction has the following keys:

  Key           | Type                                               | Description
  :------------ | :------------------------------------------------- | :----------
  `blockHash`   | `Icon.Schema.Types.Hash.t()`                       | Hash of the block that includes the transaction.
  `blockHeight` | `Icon.Schema.Types.Integer.t()`                    | Height of the block that includes the transaction.
  `data`        | Depends on `dataType`.                             | Data of the transaction.
  `dataType`    | Either `message`, `:call`, `:deploy` or `:deposit` | Data type of the transaction.
  `from`        | `Icon.Schema.Types.EOA.t()`                        | EOA address that sent the transaction.
  `nid`         | `Icon.Schema.Types.Integer.t()`                    | Network ID (see `Icon.RPC.Identity` for more information).
  `nonce`       | `Icon.Schema.Types.Integer.t()`                    | An arbitrary number used to prevent transaction hash collision.
  `signature`   | `Icon.Schema.Types.Signature.t()`                  | Signature of the transaction.
  `stepLimit`   | `Icon.Schema.Types.Loop.t()`                       | Maximum step allowance that can be used by the transaction.
  `timestamp`   | `Icon.Schema.Types.Timestamp.t()`                  | Transaction creation time. Timestamp is in microsecond.
  `to`          | `Icon.Schema.Types.Address.t()`                    | EOA address to receive coins, or SCORE address to execute the transaction.
  `txHash`      | `Icon.Schema.Types.Hash.t()`                       | Transaction hash.
  `txIndex`     | `Icon.Schema.Types.Integer.t()`                    | Transaction index in a block. `nil` when it is pending.
  `value`       | `Icon.Schema.Types.Loop.t()`                       | Amount of ICX coins in loop to transfer. When omitted, assumes 0. (1 ICX = 1¹⁸ loop).
  `version`     | `Icon.Schema.Types.Integer.t()`                    | Protocol version.
  """
  use Icon.Schema

  defschema(%{
    version: :integer,
    from: :eoa_address,
    to: :address,
    value: :loop,
    stepLimit: :loop,
    timestamp: :timestamp,
    nid: :integer,
    nonce: :integer,
    txHash: :hash,
    txIndex: :integer,
    blockHash: :hash,
    blockHeight: :integer,
    signature: :signature,
    dataType: enum([:message, :call, :deploy, :deposit, :base]),
    data:
      any(
        [
          base: %{
            result: %{
              coveredByFee: :loop,
              coveredByOverIssuedICX: :loop,
              issue: :loop
            }
          },
          message: :binary_data,
          call: %{
            method: {:string, required: true},
            params: :any
          },
          deploy: %{
            contentType: {:string, required: true},
            content: {:binary_data, required: true},
            params: :any
          },
          deposit: %{
            action: {enum([:add, :withdraw]), required: true},
            id: :hash,
            amount: :loop
          }
        ],
        :dataType
      )
  })
end
