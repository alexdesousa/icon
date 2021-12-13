defmodule Icon.RPC.Goloop do
  @moduledoc """
  This module defines the Goloop API payloads.
  """
  alias Icon.RPC

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
  @spec get_block() :: {:ok, RPC.t()} | {:error, Ecto.Changeset.t()}
  @spec get_block(keyword() | map()) ::
          {:ok, RPC.t()}
          | {:error, Ecto.Changeset.t()}
  def get_block(options \\ [])

  def get_block(options) when is_list(options) do
    options
    |> Map.new()
    |> get_block()
  end

  def get_block(params) when is_map(params) do
    types = %{
      height: Icon.Types.Integer,
      hash: Icon.Types.Hash
    }

    {%{}, types}
    |> Ecto.Changeset.cast(params, [:height, :hash])
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, %{hash: hash}} ->
        {:ok, get_block_by_hash(hash, types)}

      {:ok, %{height: height}} ->
        {:ok, get_block_by_height(height, types)}

      {:ok, _} ->
        {:ok, get_last_block()}

      {:error, %Ecto.Changeset{}} = error ->
        error
    end
  end

  @doc """
  Given an EOA or SCORE `address`, returns its balance.
  """
  @spec get_balance(Icon.Types.Address.t()) ::
          {:ok, RPC.t()}
          | {:error, Ecto.Changeset.t()}
  def get_balance(address) do
    types = %{
      address: Icon.Types.Address
    }

    {%{}, types}
    |> Ecto.Changeset.cast(%{address: address}, [:address])
    |> Ecto.Changeset.validate_required([:address])
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, %{address: _address} = params} ->
        rpc =
          :get_balance
          |> method()
          |> RPC.build(params, types: types)

        {:ok, rpc}

      {:error, %Ecto.Changeset{}} = error ->
        error
    end
  end

  @doc """
  Given a SCORE `address`, returns its API.
  """
  @spec get_score_api(Icon.Types.SCORE.t()) ::
          {:ok, RPC.t()}
          | {:error, Ecto.Changeset.t()}
  def get_score_api(address) do
    types = %{
      address: Icon.Types.SCORE
    }

    {%{}, types}
    |> Ecto.Changeset.cast(%{address: address}, [:address])
    |> Ecto.Changeset.validate_required([:address])
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, %{address: _address} = params} ->
        rpc =
          :get_score_api
          |> method()
          |> RPC.build(params, types: types)

        {:ok, rpc}

      {:error, %Ecto.Changeset{}} = error ->
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
  Given a `transaction_hash`, returns the transaction result.

  Options:

  - `wait_for` (default: `0` milliseconds) - Timeout for waiting for the result.
  - `format` (default: `:result`) - Whether the output should be in `:result` or
  `:transaction` format.
  """
  @spec get_transaction(Icon.Types.Hash.t(), keyword()) ::
          {:ok, RPC.t()}
          | {:error, Ecto.Changeset.t()}
          | no_return()
  def get_transaction(transaction_hash, options \\ [])

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def get_transaction(transaction_hash, options) do
    timeout = options[:wait_for] || 0
    format = options[:format] || :result

    types = %{
      txHash: Icon.Types.Hash
    }

    {%{}, types}
    |> Ecto.Changeset.cast(%{txHash: transaction_hash}, [:txHash])
    |> Ecto.Changeset.validate_required([:txHash])
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, %{txHash: tx_hash}}
      when timeout == 0 and format == :result ->
        {:ok, get_transaction_result(tx_hash, types)}

      {:ok, %{txHash: tx_hash}}
      when timeout == 0 and format == :transaction ->
        {:ok, get_transaction_by_hash(tx_hash, types)}

      {:ok, %{txHash: tx_hash}}
      when timeout > 0 and format in [:result, :transaction] ->
        options = [timeout: timeout, format: format]
        {:ok, wait_transaction_result(tx_hash, types, options)}

      {:ok, _} ->
        raise ArgumentError, message: "invalid options"

      {:error, %Ecto.Changeset{}} = error ->
        error
    end
  end

  #########
  # Helpers

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

  @spec get_block_by_hash(Icon.Types.Hash.t(), map()) :: RPC.t()
  defp get_block_by_hash(hash, types) do
    :get_block_by_hash
    |> method()
    |> RPC.build(%{hash: hash}, types: types)
  end

  @spec get_block_by_height(Icon.Types.Integer.t(), map()) :: RPC.t()
  defp get_block_by_height(height, types) do
    :get_block_by_height
    |> method()
    |> RPC.build(%{height: height}, types: types)
  end

  @spec get_transaction_result(Icon.Types.Hash.t(), map()) :: RPC.t()
  defp get_transaction_result(tx_hash, types) do
    :get_transaction_result
    |> method()
    |> RPC.build(%{txHash: tx_hash}, types: types)
  end

  @spec get_transaction_by_hash(Icon.Types.Hash.t(), map()) :: RPC.t()
  defp get_transaction_by_hash(tx_hash, types) do
    :get_transaction_by_hash
    |> method()
    |> RPC.build(%{txHash: tx_hash}, types: types)
  end

  @spec wait_transaction_result(Icon.Types.Hash.t(), map(), keyword()) ::
          RPC.t()
  defp wait_transaction_result(tx_hash, types, options) do
    options = Keyword.put(options, :types, types)

    :wait_transaction_result
    |> method()
    |> RPC.build(%{txHash: tx_hash}, options)
  end
end
