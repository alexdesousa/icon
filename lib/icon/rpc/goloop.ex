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

  #########
  # Helpers

  @spec method(method :: method()) :: binary()
  defp method(:get_last_block), do: "icx_getLastBlock"
  defp method(:get_block_by_height), do: "icx_getBlockByHeight"
  defp method(:get_block_by_hash), do: "icx_getBlockByHash"
  defp method(:get_balance), do: "icx_getBalance"
  defp method(:get_score_api), do: "icx_getScoreApi"

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
end
