defmodule Icon do
  @moduledoc """
  `Icon` is a library for interacting with the interoperable decentralized
  aggregator network [ICON 2.0](https://icon.foundation).
  """
  alias Icon.RPC.{Identity, Request}
  alias Icon.Schema.{Error, Types.Address, Types.Loop}

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
end
