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
  iex> Icon.total_supply(identity)
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
  iex> Icon.get_transaction_result(identity, ""0x917def9734385cbb0c1f3e9d6fc0e46706f51348ab9cea1d7e1bf44e1ed51b25"")
  {
    :ok,
    %Icon.Schema.Types.Transaction.Result{
      blockHash: "0xd6e8ed8035b38a5c09de59df101c7e6258e6d7e0690d3c6c6093045a5550bb83",
      blockHeight: 45162694,
      cummulativeStepUsed: nil,
      eventLogs: [
        %Icon.Schema.Types.EventLog{
          data: ["{\\"method\\": \\"_swap\\", \\"params\\": {\\"toToken\\": \\"cx88fd7df7ddff82f7cc735c871dc519838cb235bb\\", \\"minimumReceive\\": \\"1000020000000000000000\\", \\"path\\": [\\"cx2609b924e33ef00b648a409245c7ea394c467824\\", \\"cxf61cd5a45dc9f91c15aa65831a30a90d59a09619\\", \\"cx88fd7df7ddff82f7cc735c871dc519838cb235bb\\"]}}"],
          header: "Transfer(Address,Address,int,bytes)",
          indexed: [
            "hx948b9727f426ae7789741da8c796807f78ba137f",
            "cx21e94c08c03daee80c25d8ee3ea22a20786ec231",
            1000020000000000000000
          ],
          name: "Transfer",
          score_address: "cx88fd7df7ddff82f7cc735c871dc519838cb235bb"
        },
        ...
      ]
      failure: nil,
      logsBloom: <<0, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 16, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 1, 0, 1, 0, 0, 16, 0, 128,
        ...>>,
      scoreAddress: nil,
      status: :success,
      stepPrice: 12500000000,
      stepUsed: 13816635,
      to: "cx88fd7df7ddff82f7cc735c871dc519838cb235bb",
      txHash: "0x917def9734385cbb0c1f3e9d6fc0e46706f51348ab9cea1d7e1bf44e1ed51b25",
      txIndex: 2
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
  Calls a `method` in a `score` in a signed transaction.

  Options:
  - `schema` - Method parameters schema.
  - `timeout` - Time in milliseconds to wait for the transaction result.
  - `params` - Extra transaction parameters for overriding the defaults.

  While technically any parameter can be overriden with the `params` option, not
  all of them make sense to do so. The following are some of the most usuful
  parameters to modify via this option:

  - `nonce` - An arbitrary number used to prevent transaction hash collision.
  - `timestamp` - Transaction creation time. Timestamp is in microsecond.
  - `stepLimit` - Maximum step allowance that can be used by the transaction.

  ## Call Schema

  The `schema` option gives defines the types of the `call_params`. This is
  required for `method` calls with parameters, because ICON has a different
  type representation than Elixir e.g. let's say we want to call the method
  `transfer(from: Address, to: Address, amount: int)` for transferring an
  `amount` of tokens `from` one EOA address `to` another. Then the schema would
  look like this:

  ```elixir
  %{
    from: {:eoa_address, required: true},
    to: {:eoa_address, required: true},
    amount: {:loop, required: true}
  }
  ```

  Then, while doing the actual transaction call, the schema will help with the
  conversion of the `call_params`. So, something like the following:

  ```elixir
  %{
    from: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
    to: "hx2e243ad926ac48d15156756fce28314357d49d83",
    amount: 1_000_000_000_000_000_000
  }
  ```

  will be converted to the following when communicating with the node:

  ```json
  {
    "from": "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
    "to": "hx2e243ad926ac48d15156756fce28314357d49d83",
    "amount": "0xde0b6b3a7640000"
  }
  ```

  ## Examples

  Given the example method used in the previous section, we can call it as
  follows:

  - Transfer tokens from one wallet to another:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.transaction_call(
  ...>   identity,
  ...>   "cx2e243ad926ac48d15156756fce28314357d49d83",
  ...>   "transfer",
  ...>   %{
  ...>     from: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
  ...>     to: "hx2e243ad926ac48d15156756fce28314357d49d83",
  ...>     amount: 1_000_000_000_000_000_000
  ...>   },
  ...>   schema: %{
  ...>     from: {:eoa_address, required: true},
  ...>     to: {:eoa_address, required: true},
  ...>     amount: {:loop, required: true}
  ...>   }
  ...> )
  {:ok, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"}
  ```

  - Transfer token from one wallet to another and wait 5 second for the result:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.transaction_call(
  ...>   identity,
  ...>   "cx2e243ad926ac48d15156756fce28314357d49d83",
  ...>   "transfer",
  ...>   %{
  ...>     from: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
  ...>     to: "hx2e243ad926ac48d15156756fce28314357d49d83",
  ...>     amount: 1_000_000_000_000_000_000
  ...>   },
  ...>   schema: %{
  ...>     from: {:eoa_address, required: true},
  ...>     to: {:eoa_address, required: true},
  ...>     amount: {:loop, required: true}
  ...>   },
  ...>   timeout: 5_000
  ...> )
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
  @spec transaction_call(Identity.t(), SCORE.t(), binary()) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  @spec transaction_call(
          Identity.t(),
          SCORE.t(),
          binary(),
          nil | map() | keyword()
        ) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  @spec transaction_call(
          Identity.t(),
          SCORE.t(),
          binary(),
          nil | map() | keyword(),
          keyword()
        ) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  def transaction_call(identity, score, method, params \\ nil, options \\ [])

  def transaction_call(%Identity{} = identity, to, method, call_params, options) do
    with {:ok, request} <-
           Request.Goloop.transaction_call(
             identity,
             to,
             method,
             call_params,
             options
           ) do
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

  @doc """
  Deposits ICX in loop (1 ICX = 10¹⁸ loop) into a SCORE for paying user's fees
  when they transact with the contract (fee sharing).

  Options:
  - `timeout` - Time in milliseconds to wait for the transaction result.
  - `params` - Extra transaction parameters for overriding the defaults.

  While technically any parameter can be overriden with the `params` option, not
  all of them make sense to do so. The following are some of the most usuful
  parameters to modify via this option:

  - `nonce` - An arbitrary number used to prevent transaction hash collision.
  - `timestamp` - Transaction creation time. Timestamp is in microsecond.
  - `stepLimit` - Maximum step allowance that can be used by the transaction.

  ## Examples

  - Deposits `1.00` ICX in a SCORE:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
  iex> Icon.deposit_shared_fee(identity, score_address, 1_000_000_000_000_000_000)
  {:ok, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"}
  ```

  - Deposit `1.00` ICX in a SCORE and wait 5 seconds for the result:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
  iex> Icon.deposit_shared_fee(identity, score_address, 1_000_000_000_000_000_000,
  ...>   timeout: 5_000
  ...> )
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
  """
  @spec deposit_shared_fee(Identity.t(), SCORE.t(), Loop.t()) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  @spec deposit_shared_fee(Identity.t(), SCORE.t(), Loop.t(), keyword()) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  def deposit_shared_fee(identity, score_address, amount, options \\ [])

  def deposit_shared_fee(%Identity{} = identity, to, amount, options) do
    with {:ok, request} <-
           Request.Goloop.deposit_shared_fee(identity, to, amount, options) do
      send_transaction(request)
    end
  end

  @doc """
  Withdraws ICX from a SCORE that was destined for paying user's fees when they
  transact with the contract (fee sharing).

  Options:
  - `timeout` - Time in milliseconds to wait for the transaction result.
  - `params` - Extra transaction parameters for overriding the defaults.

  While technically any parameter can be overriden with the `params` option, not
  all of them make sense to do so. The following are some of the most usuful
  parameters to modify via this option:

  - `nonce` - An arbitrary number used to prevent transaction hash collision.
  - `timestamp` - Transaction creation time. Timestamp is in microsecond.
  - `stepLimit` - Maximum step allowance that can be used by the transaction.

  ## Examples

  - Withdraws `1.00` ICX from a SCORE:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
  iex> Icon.withdraw_shared_fee(identity, score_address, 1_000_000_000_000_000_000)
  {:ok, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"}
  ```

  - Withdraws ICX using the deposit hash:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
  iex> hash = "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"
  iex> Icon.withdraw_shared_fee(identity, score_address, hash)
  {:ok, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"}
  ```

  - Withdraw the whole deposit from a SCORE and wait 5 seconds for the result:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> score_address = "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
  iex> Icon.withdraw_shared_fee(identity, score_address, timeout: 5_000)
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
  """
  @spec withdraw_shared_fee(Identity.t(), SCORE.t()) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  @spec withdraw_shared_fee(Identity.t(), SCORE.t(), nil | Loop.t() | Hash.t()) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  @spec withdraw_shared_fee(
          Identity.t(),
          SCORE.t(),
          nil | Loop.t() | Hash.t(),
          keyword()
        ) ::
          {:ok, Hash.t()}
          | {:ok, Transaction.Result.t()}
          | {:error, Error.t()}
  def withdraw_shared_fee(
        identity,
        score_address,
        hash_or_amount \\ nil,
        options \\ []
      )

  def withdraw_shared_fee(%Identity{} = identity, to, hash_or_amount, options) do
    with {:ok, request} <-
           Request.Goloop.withdraw_shared_fee(
             identity,
             to,
             hash_or_amount,
             options
           ) do
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
