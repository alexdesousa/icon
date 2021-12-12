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

  #########
  # Helpers

  @spec method(method :: method()) :: binary()
  defp method(:get_last_block), do: "icx_getLastBlock"
  defp method(:get_block_by_height), do: "icx_getBlockByHeight"
  defp method(:get_block_by_hash), do: "icx_getBlockByHash"

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
