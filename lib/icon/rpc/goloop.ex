defmodule Icon.RPC.Goloop do
  @moduledoc """
  This module defines the Goloop API payloads.
  """
  alias Icon.RPC
  alias Icon.Types.{Error, Schema}

  @typedoc """
  Supported methods.
  """
  @type method ::
          :get_last_block
          | :get_block_by_height
          | :get_block_by_hash
          | :get_balance
          | :get_score_api
          | :get_total_supply
          | :get_transaction_result
          | :get_transaction_by_hash
          | :wait_transaction_result

  @doc """
  Gets block.

  Options:
  - `hash` - Block hash.
  - `height` - Block height.

  If `hash` and `height` are both present in the options, `hash` will take
  precedence.
  """
  @spec get_block() :: {:ok, RPC.t()} | {:error, Error.t()}
  @spec get_block(keyword() | map()) ::
          {:ok, RPC.t()}
          | {:error, Error.t()}
  def get_block(options \\ [])

  def get_block(params) do
    schema = %{height: :integer, hash: :hash}

    case validate(schema, params) do
      {:ok, %{hash: hash}} ->
        {:ok, get_block_by_hash(hash)}

      {:ok, %{height: height}} ->
        {:ok, get_block_by_height(height)}

      {:ok, _} ->
        {:ok, get_last_block()}

      {:error, %Error{}} = error ->
        error
    end
  end

  @doc """
  Given an EOA or SCORE `address`, returns its balance.
  """
  @spec get_balance(Icon.Types.Address.t()) ::
          {:ok, RPC.t()}
          | {:error, Error.t()}
  def get_balance(address) do
    schema = %{address: {:address, required: true}}

    case validate(schema, address: address) do
      {:ok, %{address: _address} = params} ->
        rpc =
          :get_balance
          |> method()
          |> RPC.build(params, schema: schema)

        {:ok, rpc}

      {:error, %Error{}} = error ->
        error
    end
  end

  @doc """
  Given a SCORE `address`, returns its API.
  """
  @spec get_score_api(Icon.Types.SCORE.t()) ::
          {:ok, RPC.t()}
          | {:error, Error.t()}
  def get_score_api(address) do
    schema = %{address: {:score_address, required: true}}

    case validate(schema, address: address) do
      {:ok, %{address: _address} = params} ->
        rpc =
          :get_score_api
          |> method()
          |> RPC.build(params, schema: schema)

        {:ok, rpc}

      {:error, %Error{}} = error ->
        error
    end
  end

  @doc """
  Returns the total ICX supply.
  """
  @spec get_total_supply() :: {:ok, RPC.t()}
  def get_total_supply do
    rpc =
      :get_total_supply
      |> method()
      |> RPC.build()

    {:ok, rpc}
  end

  @doc """
  Given a `tx_hash`, returns the transaction result.

  Options:

  - `wait_for` (default: `0` milliseconds) - Timeout for waiting for the result.
  - `format` (default: `:result`) - Whether the output should be in `:result` or
  `:transaction` format.
  """
  @spec get_transaction(Icon.Types.Hash.t(), keyword()) ::
          {:ok, RPC.t()}
          | {:error, Error.t()}
  def get_transaction(tx_hash, options \\ [])

  def get_transaction(tx_hash, options) do
    schema = %{
      txHash: :hash,
      wait_for: {:integer, default: 0},
      format: {{:enum, [:transaction, :result]}, default: :result}
    }

    case validate(schema, [{:txHash, tx_hash} | options]) do
      {:ok, %{txHash: tx_hash, wait_for: 0, format: :result}} ->
        {:ok, get_transaction_result(tx_hash)}

      {:ok, %{txHash: tx_hash, wait_for: 0, format: :transaction}} ->
        {:ok, get_transaction_by_hash(tx_hash)}

      {:ok, %{txHash: tx_hash, wait_for: timeout, format: format}}
      when timeout > 0 and format in [:result, :transaction] ->
        options = [timeout: timeout, format: format]
        {:ok, wait_transaction_result(tx_hash, options)}

      {:error, %Error{}} = error ->
        error
    end
  end

  #########
  # Helpers

  @spec validate(Schema.t(), map() | keyword()) ::
          {:ok, map()}
          | {:error, Error.t()}
  defp validate(schema, params) do
    schema
    |> Schema.generate()
    |> Schema.new(params)
    |> Schema.load()
    |> Schema.apply()
  end

  @spec method(method :: method()) :: binary()
  defp method(:get_last_block), do: "icx_getLastBlock"
  defp method(:get_block_by_height), do: "icx_getBlockByHeight"
  defp method(:get_block_by_hash), do: "icx_getBlockByHash"
  defp method(:get_balance), do: "icx_getBalance"
  defp method(:get_score_api), do: "icx_getScoreApi"
  defp method(:get_total_supply), do: "icx_getTotalSupply"
  defp method(:get_transaction_result), do: "icx_getTransactionResult"
  defp method(:get_transaction_by_hash), do: "icx_getTransactionByHash"
  defp method(:wait_transaction_result), do: "icx_waitTransactionResult"

  @spec get_last_block() :: RPC.t()
  defp get_last_block do
    :get_last_block
    |> method()
    |> RPC.build()
  end

  @spec get_block_by_hash(Icon.Types.Hash.t()) :: RPC.t()
  defp get_block_by_hash(hash) do
    schema = %{hash: {:hash, required: true}}

    :get_block_by_hash
    |> method()
    |> RPC.build(%{hash: hash}, schema: schema)
  end

  @spec get_block_by_height(Icon.Types.Integer.t()) :: RPC.t()
  defp get_block_by_height(height) do
    schema = %{height: {:integer, required: true}}

    :get_block_by_height
    |> method()
    |> RPC.build(%{height: height}, schema: schema)
  end

  @spec get_transaction_result(Icon.Types.Hash.t()) :: RPC.t()
  defp get_transaction_result(tx_hash) do
    schema = %{txHash: {:hash, required: true}}

    :get_transaction_result
    |> method()
    |> RPC.build(%{txHash: tx_hash}, schema: schema)
  end

  @spec get_transaction_by_hash(Icon.Types.Hash.t()) :: RPC.t()
  defp get_transaction_by_hash(tx_hash) do
    schema = %{txHash: {:hash, required: true}}

    :get_transaction_by_hash
    |> method()
    |> RPC.build(%{txHash: tx_hash}, schema: schema)
  end

  @spec wait_transaction_result(Icon.Types.Hash.t(), keyword()) ::
          RPC.t()
  defp wait_transaction_result(tx_hash, options) do
    schema = %{txHash: {:hash, required: true}}
    options = Keyword.put(options, :schema, schema)

    :wait_transaction_result
    |> method()
    |> RPC.build(%{txHash: tx_hash}, options)
  end
end
