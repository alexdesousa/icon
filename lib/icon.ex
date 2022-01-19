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
    Types.BinaryData,
    Types.Hash,
    Types.Loop,
    Types.SCORE,
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

  Options:
  - `timeout` - Timeout in milliseconds for waiting for the result of the
  transaction in case it's pending.

  ## Example

  - Requesting a successful transaction result by `hash`:

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
  @spec get_transaction_result(Identity.t(), Hash.t(), keyword()) ::
          {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  def get_transaction_result(identity, tx_hash, options \\ [])

  def get_transaction_result(%Identity{} = identity, hash, options) do
    with {:ok, request} <-
           Request.Goloop.get_transaction_result(identity, hash, options),
         {:ok, response} <- Request.send(request) do
      load_transaction_result(response)
    end
  end

  @doc """
  Transfers an ICX `amount` to a `recipient`.

  The `identity` should be created using a valid `private_key`, otherwise the
  transfer cannot be executed.

  Options:
  - `timeout` - Time in milliseconds to wait for the transfer result.
  - `params` - Extra transaction parameters for overriding the defaults.

  While technically any parameter can be overriden with the `params` option, not
  all of them make sense to do so. The following are some of the most usuful
  parameters to modify via this option:

  - `nonce` - An arbitrary number used to prevent transaction hash collision.
  - `timestamp` - Transaction creation time. Timestamp is in microsecond.
  - `stepLimit` - Maximum step allowance that can be used by the transaction.

  ## Examples

  - Transfer `1.00` ICX to another wallet:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"
  iex> amount = 1_000_000_000_000_000_000 # 1 ICX in loop
  iex> Icon.transfer(identity, recipient, amount)
  {:ok, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"}
  ```

  - Transfer `1.00` ICX to another wallet and wait 5 seconds for the result:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"
  iex> amount = 1_000_000_000_000_000_000 # 1 ICX in loop
  iex> Icon.transfer(identity, recipient, amount, timeout: 5_000)
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
      to: "hx2e243ad926ac48d15156756fce28314357d49d83",
      txHash: "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
      txIndex: 1
    }
  }
  ```
  """
  @spec transfer(Identity.t(), Address.t(), Loop.t()) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  @spec transfer(Identity.t(), Address.t(), Loop.t(), keyword()) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  def transfer(identity, recipient, amount, options \\ [])

  def transfer(%Identity{} = identity, to, value, options) do
    with {:ok, request} <-
           Request.Goloop.transfer(identity, to, value, options) do
      send_transaction(request)
    end
  end

  @doc """
  Send a signed `message` to a `recipient`.

  The `identity` should be created using a valid `private_key`, otherwise the
  message cannot be sent.

  Options:
  - `timeout` - Time in milliseconds to wait for the transfer result.
  - `params` - Extra transaction parameters for overriding the defaults.

  While technically any parameter can be overriden with the `params` option, not
  all of them make sense to do so. The following are some of the most usuful
  parameters to modify via this option:

  - `nonce` - An arbitrary number used to prevent transaction hash collision.
  - `timestamp` - Transaction creation time. Timestamp is in microsecond.
  - `stepLimit` - Maximum step allowance that can be used by the transaction.

  ## Examples

  - Send a message to another wallet:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"
  iex> Icon.send_message(identity, recipient, "Hello!")
  {:ok, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"}
  ```

  - Send a message to another wallet and wait 5 seconds for the result:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> recipient = "hx2e243ad926ac48d15156756fce28314357d49d83"
  iex> Icon.send_message(identity, recipient, "Hello!", timeout: 5_000)
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
      to: "hx2e243ad926ac48d15156756fce28314357d49d83",
      txHash: "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
      txIndex: 1
    }
  }
  ```
  """
  @spec send_message(Identity.t(), Schema.Types.Address.t(), binary()) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  @spec send_message(
          Identity.t(),
          Schema.Types.Address.t(),
          binary(),
          keyword()
        ) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  def send_message(identity, recipient, message, options \\ [])

  def send_message(%Identity{} = identity, to, message, options) do
    with {:ok, request} <-
           Request.Goloop.send_message(identity, to, message, options) do
      send_transaction(request)
    end
  end

  @doc """
  Creates a new SCORE.

  The `identity` should be created using a valid `private_key`, otherwise the
  message cannot be sent.

  Options:
  - `timeout` - Time in milliseconds to wait for the transfer result.
  - `params` - Extra transaction parameters for overriding the defaults.
  - `content_type` - MIME type of the SCORE contents. Defaults to
    `application/zip`.
  - `on_install_params` - Parameters for the function `on_install/0`.
  - `on_install_schema` - Schema for the parameters of the function
    `on_install/0`.

  While technically any parameter can be overriden with the `params` option, not
  all of them make sense to do so. The following are some of the most usuful
  parameters to modify via this option:

  - `nonce` - An arbitrary number used to prevent transaction hash collision.
  - `timestamp` - Transaction creation time. Timestamp is in microsecond.
  - `stepLimit` - Maximum step allowance that can be used by the transaction.

  ## Examples

  - Creates a new contract:

  ```elixir
  iex> {:ok, content} = File.read("./my-contract.javac")
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.install_score(identity, content)
  {:ok, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"}
  ```

  - Creates a new contract and waits 5 seconds for the result:

  ```elixir
  iex> {:ok, content} = File.read("./my-contract.javac")
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.install_score(identity, content, timeout: 5_000)
  {
    :ok,
    %Icon.Schema.Types.Transaction.Result{
      blockHash: "0x52bab965acf6fa11f7e7450a87947d944ad8a7f88915e27579f21244f68c6285",
      blockHeight: 2_427_717,
      cummulativeStepUsed: nil,
      failure: nil,
      logsBloom: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...>>,
      scoreAddress: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
      status: :success,
      stepPrice: 12_500_000_000,
      stepUsed: 100_000,
      to: "cx0000000000000000000000000000000000000000",
      txHash: "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
      txIndex: 1
    }
  }
  ```

  - Creates a new contract and passes paremeters to the `on_install` function:

  ```elixir
  iex> {:ok, content} = File.read("./my-contract.javac")
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.install_score(identity, content,
  ...>   on_install_params: %{
  ...>     address: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57"
  ...>   },
  ...>   on_install_schema: %{
  ...>     address: {:address, required: true}
  ...>   }
  ...> )
  {:ok, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"}
  ```
  """
  @spec install_score(Identity.t(), BinaryData.t()) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  @spec install_score(Identity.t(), BinaryData.t(), keyword()) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  def install_score(identity, content, options \\ [])

  def install_score(%Identity{} = identity, content, options) do
    with {:ok, request} <-
           Request.Goloop.install_score(identity, content, options) do
      send_transaction(request)
    end
  end

  @doc """
  Updates a SCORE.

  The `identity` should be created using a valid `private_key`, otherwise the
  message cannot be sent.

  Options:
  - `timeout` - Time in milliseconds to wait for the transfer result.
  - `params` - Extra transaction parameters for overriding the defaults.
  - `content_type` - MIME type of the SCORE contents. Defaults to
    `application/zip`.
  - `on_update_params` - Parameters for the function `on_update/0`.
  - `on_update_schema` - Schema for the parameters of the function
    `on_update/0`.

  While technically any parameter can be overriden with the `params` option, not
  all of them make sense to do so. The following are some of the most usuful
  parameters to modify via this option:

  - `nonce` - An arbitrary number used to prevent transaction hash collision.
  - `timestamp` - Transaction creation time. Timestamp is in microsecond.
  - `stepLimit` - Maximum step allowance that can be used by the transaction.

  ## Examples

  - Updates a contract:

  ```elixir
  iex> {:ok, content} = File.read("./my-contract.javac")
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
  iex> Icon.update_score(identity, score_address, content)
  {:ok, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"}
  ```

  - Updates a contract and waits 5 seconds for the result:

  ```elixir
  iex> {:ok, content} = File.read("./my-contract.javac")
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
  iex> Icon.update_score(identity, score_address, content, timeout: 5_000)
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
      to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
      txHash: "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
      txIndex: 1
    }
  }
  ```

  - Updates a contract and passes paremeters to the `on_update` function:

  ```elixir
  iex> {:ok, content} = File.read("./my-contract.javac")
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
  iex> Icon.update_score(identity, score_address, content,
  ...>   on_update_params: %{
  ...>     address: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57"
  ...>   },
  ...>   on_update_schema: %{
  ...>     address: {:address, required: true}
  ...>   }
  ...> )
  {:ok, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"}
  ```
  """
  @spec update_score(Identity.t(), SCORE.t(), BinaryData.t()) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  @spec update_score(Identity.t(), SCORE.t(), BinaryData.t(), keyword()) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  def update_score(identity, score_address, content, options \\ [])

  def update_score(%Identity{} = identity, to, content, options) do
    with {:ok, request} <-
           Request.Goloop.update_score(identity, to, content, options) do
      send_transaction(request)
    end
  end

  #########
  # Helpers

  @spec send_transaction(Request.t()) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  defp send_transaction(request)

  defp send_transaction(%Request{} = request) do
    with {:ok, request} <- Request.add_step_limit(request),
         {:ok, request} <- Request.sign(request),
         {:ok, response} <- Request.send(request) do
      load_transaction_response(response)
    end
  end

  @spec load_transaction_response(any()) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  defp load_transaction_response(data)

  defp load_transaction_response("0x" <> _ = data) do
    {:ok, data}
  end

  defp load_transaction_response(data) do
    load_transaction_result(data)
  end

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
