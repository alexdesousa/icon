defmodule Icon do
  @moduledoc """
  `Icon` is a library for interacting with the interoperable decentralized
  aggregator network [ICON 2.0](https://icon.foundation).
  """
  alias Icon.RPC.{Identity, Request}
  alias Icon.Schema

  alias Icon.Schema.{
    Error,
    Types.Address,
    Types.Hash,
    Types.Loop,
    Types.Transaction
  }

  @doc """
  Gets the balance of an EOA or SCORE `address`. If the `address` is not provided,
  it uses the one in the `identity`. The balance is returned in loop
  (1 ICX = 10¹⁸ loop).

  ## Examples

  - Requesting the balance of the loaded identity:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.get_balance(identity)
  {:ok, 2_045_995_000_000_000_000_000}
  ```

  - Requesting the balance of a wallet:

  ```elixir
  iex> identity = Icon.RPC.Identity.new()
  iex> Icon.get_balance(identity, "hxbe258ceb872e08851f1f59694dac2558708ece11")
  {:ok, 0}
  ```
  """
  @spec get_balance(Identity.t()) :: {:ok, Loop.t()} | {:error, Error.t()}
  @spec get_balance(Identity.t(), nil | Address.t()) ::
          {:ok, Loop.t()}
          | {:error, Error.t()}
  def get_balance(identity, address \\ nil)

  def get_balance(%Identity{} = identity, address) do
    with {:ok, request} <- Request.Goloop.get_balance(identity, address),
         {:ok, response} <- Request.send(request),
         :error <- Loop.load(response) do
      reason =
        Error.new(
          reason: :server_error,
          message: "cannot cast balance to loop"
        )

      {:error, reason}
    end
  end

  @doc """
  Gets the ICX's total supply in loop (1 ICX = 10¹⁸ loop).

  ## Examples

  - Requesting ICX's total supply:

  ```elixir
  iex> identity = Icon.RPC.Identity.new()
  iex> Icon.get_balance(identity)
  {:ok, 1_300_163_572_018_865_530_968_203_250}
  ```
  """
  @spec get_total_supply(Identity.t()) :: {:ok, Loop.t()} | {:error, Error.t()}
  def get_total_supply(identity)

  def get_total_supply(%Identity{} = identity) do
    with {:ok, request} <- Request.Goloop.get_total_supply(identity),
         {:ok, response} <- Request.send(request),
         :error <- Loop.load(response) do
      reason =
        Error.new(
          reason: :server_error,
          message: "cannot cast total supply to loop"
        )

      {:error, reason}
    end
  end

  @doc """
  Gets a transaction result by `hash`.

  ## Examples

  - Requesting a transaction result by `hash`:

  ```elixir
  iex> identity = Icon.RPC.Identity.new()
  iex> Icon.get_balance(identity, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b")
  {
    :ok,
    %Icon.Schema.Types.Transaction.Result{
      blockHash: "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
      blockHeight: 2_427_717,
      cummulativeStepUsed: nil,
      failure: nil,
      logsBloom: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...>>,
      scoreAddress: nil,
      status: :success,
      stepPrice: 12_500_000_000,
      stepUsed: 100_000,
      to: "hxdd3ead969f0dfb0b72265ca584092a3fb25d27e0",
      txHash: "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
      txIndex: 1
    }
  }
  ```
  """
  @spec get_transaction_result(Identity.t(), Hash.t()) ::
          {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  def get_transaction_result(identity, tx_hash)

  def get_transaction_result(%Identity{} = identity, hash) do
    with {:ok, request} <-
           Request.Goloop.get_transaction_result(identity, hash),
         {:ok, response} <- Request.send(request) do
      load_transaction_result(response)
    end
  end

  #########
  # Helpers

  @spec load_transaction_result(any()) ::
          {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  defp load_transaction_result(data)

  defp load_transaction_result(data) when is_map(data) do
    Transaction.Result
    |> Schema.generate()
    |> Schema.new(data)
    |> Schema.load()
    |> Schema.apply(into: Transaction.Result)
  end

  defp load_transaction_result(_) do
    reason =
      Error.new(
        reason: :server_error,
        message: "cannot cast transaction result"
      )

    {:error, reason}
  end
end
