defmodule Icon.Schema.Types.Transaction.Result do
  @moduledoc """
  This module defines a transaction result.
  """
  use Icon.Schema

  alias Icon.Schema.Types.Transaction.Status

  defschema(%{
    blockHash: :hash,
    blockHeight: :integer,
    cummulativeStepUsed: :loop,
    failure: %{
      code: :integer,
      message: :string,
      data: :hash
    },
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
