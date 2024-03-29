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
    Types.Block,
    Types.Hash,
    Types.Loop,
    Types.SCORE,
    Types.Transaction
  }

  @doc """
  Gets block by `hash_or_height`. If hash or height are not provided, it will
  retrieve the latest block.

  ## Example

  - Get latest block:

  ```elixir
  iex> identity = Icon.RPC.Identity.new()
  iex> Icon.get_block(identity)
  {
    :ok,
    %Icon.Schema.Types.Block{
      block_hash: "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
      confirmed_transaction_list: [
        %Icon.Schema.Types.Transaction{
          data: %{
            result: %{
              coveredByFee: 0,
              coveredByOverIssuedICX: 12_000,
              issue: 0
            }
          },
          dataType: :base,
          timestamp: ~U[2022-01-22 11:06:21.258886Z],
          txHash: "0x75e553dcd57853e6c96428c4fede49209a3055fc905db757baa470c1e94f736d",
          version: 3
        }
      ],
      height: 3_153_751,
      merkle_tree_root_hash: "0xce5aa42a762ee88a32fc2a792dfb5975858a71a8abf4ec51fb1218e3b827aa01",
      peer_id: "hxb97c82a5577a0a436f51a41421ad2d3b28da3f25",
      prev_block_hash: "0xfe8138afd24512cc0e9f4da8df350300a759a480f15c8a00b04b2d753ea62ac3",
      signature: nil,
      time_stamp: ~U[2022-01-22 11:06:21.258886Z],
      version: "2.0"
    }
  }
  ```

  - Get block by height:

  ```elixir
  iex> identity = Icon.RPC.Identity.new()
  iex> Icon.get_block(identity, 3_153_751)
  {
    :ok,
    %Icon.Schema.Types.Block{
      block_hash: "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
      confirmed_transaction_list: [
        %Icon.Schema.Types.Transaction{
          data: %{
            result: %{
              coveredByFee: 0,
              coveredByOverIssuedICX: 12_000,
              issue: 0
            }
          },
          dataType: :base,
          timestamp: ~U[2022-01-22 11:06:21.258886Z],
          txHash: "0x75e553dcd57853e6c96428c4fede49209a3055fc905db757baa470c1e94f736d",
          version: 3
        }
      ],
      height: 3_153_751,
      merkle_tree_root_hash: "0xce5aa42a762ee88a32fc2a792dfb5975858a71a8abf4ec51fb1218e3b827aa01",
      peer_id: "hxb97c82a5577a0a436f51a41421ad2d3b28da3f25",
      prev_block_hash: "0xfe8138afd24512cc0e9f4da8df350300a759a480f15c8a00b04b2d753ea62ac3",
      signature: nil,
      time_stamp: ~U[2022-01-22 11:06:21.258886Z],
      version: "2.0"
    }
  }
  ```

  - Get block by hash:

  ```elixir
  iex> identity = Icon.RPC.Identity.new()
  iex> Icon.get_block(identity, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b")
  {
    :ok,
    %Icon.Schema.Types.Block{
      block_hash: "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b",
      confirmed_transaction_list: [
        %Icon.Schema.Types.Transaction{
          data: %{
            result: %{
              coveredByFee: 0,
              coveredByOverIssuedICX: 12_000,
              issue: 0
            }
          },
          dataType: :base,
          timestamp: ~U[2022-01-22 11:06:21.258886Z],
          txHash: "0x75e553dcd57853e6c96428c4fede49209a3055fc905db757baa470c1e94f736d",
          version: 3
        }
      ],
      height: 3_153_751,
      merkle_tree_root_hash: "0xce5aa42a762ee88a32fc2a792dfb5975858a71a8abf4ec51fb1218e3b827aa01",
      peer_id: "hxb97c82a5577a0a436f51a41421ad2d3b28da3f25",
      prev_block_hash: "0xfe8138afd24512cc0e9f4da8df350300a759a480f15c8a00b04b2d753ea62ac3",
      signature: nil,
      time_stamp: ~U[2022-01-22 11:06:21.258886Z],
      version: "2.0"
    }
  }
  ```
  """
  @spec get_block(Identity.t()) ::
          {:ok, Block.t()}
          | {:error, Error.t()}
  @spec get_block(Identity.t(), nil | pos_integer() | Hash.t()) ::
          {:ok, Block.t()}
          | {:error, Error.t()}
  def get_block(identity, height_or_hash \\ nil)

  def get_block(identity, nil) do
    with {:ok, request} <- Request.Goloop.get_last_block(identity),
         {:ok, response} <- Request.send(request) do
      load_block(response)
    end
  end

  def get_block(identity, height) when is_integer(height) and height > 0 do
    with {:ok, request} <- Request.Goloop.get_block_by_height(identity, height),
         {:ok, response} <- Request.send(request) do
      load_block(response)
    end
  end

  def get_block(identity, hash) do
    with {:ok, request} <- Request.Goloop.get_block_by_hash(identity, hash),
         {:ok, response} <- Request.send(request) do
      load_block(response)
    end
  end

  @doc """
  Calls a readonly SCORE `method` (no transaction).

  The `identity` should be created using a valid `private_key`, otherwise the
  call cannot be executed.

  Options:
  - `call_schema` - Schema to validate the `params`. When no schema is provided,
    the default schema `:any` will be used instead.
  - `response_schema` - Schema for transforming the incoming values. When no
    schema is provided, the default schema `:any` will be used instead.

  ## Example

  - Calling the method `getBalance` without parameters:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.call(
  ...>   identity,
  ...>   "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
  ...>   "getBalance",
  ...> )
  {:ok, "0x2a"}
  ```

  - Calling the method `getBalance` with an address as parameter without type
    conversion:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.call(
  ...>   identity,
  ...>   "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
  ...>   "getBalance",
  ...>   %{address: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57"},
  ...> )
  {:ok, "0x2a"}
  ```

  - Calling the method `getBalance` with an address as parameter with type
    conversion using a `call_schema` (recommended):

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.call(
  ...>   identity,
  ...>   "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
  ...>   "getBalance",
  ...>   %{address: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57"},
  ...>   call_schema: %{address: {:address, required: true}},
  ...>   response_schema: :loop
  ...> )
  {:ok, 42}
  ```
  """
  @spec call(Identity.t(), SCORE.t(), binary()) ::
          {:ok, any()}
          | {:error, Error.t()}
  @spec call(Identity.t(), SCORE.t(), binary(), nil | map() | keyword()) ::
          {:ok, any()}
          | {:error, Error.t()}
  @spec call(
          Identity.t(),
          SCORE.t(),
          binary(),
          nil | map() | keyword(),
          keyword()
        ) ::
          {:ok, any()}
          | {:error, Error.t()}
  def call(identity, score_address, method, params \\ nil, options \\ [])

  def call(%Identity{} = identity, to, method, params, options) do
    options =
      case options[:call_schema] do
        nil ->
          options

        value ->
          options
          |> Keyword.delete(:call_schema)
          |> Keyword.put(:schema, value)
      end

    with {:ok, request} <-
           Request.Goloop.call(identity, to, method, params, options),
         {:ok, response} <- Request.send(request) do
      load_call_response(response, options)
    end
  end

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
  Gets SCORE API.

  ## Example

  - Gets the API of a SCORE:

  ```elixir
  iex> identity = Icon.RPC.Identity.new()
  iex> Icon.get_score_api(identity, "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32")
  {
    :ok,
    [
      %{
        "type" => "function",
        "name" => "balanceOf",
        "inputs" => [
          %{
            "name" => "_owner",
            "type" => "Address"
          }
        ],
        "outputs" => [
          %{
            "type" => "int"
          }
        ],
        "readonly" => "0x1"
      },
      ...
    ]
  }
  ```

  ## API Entries

  Each member of the list will have the following keys:

  Key        | Description
  :--------- | :----------
  `type`     | Either `function`, `fallback` or `eventlog`.
  `name`     | Name of the function or the event log.
  `inputs`   | A list of parameters the function or the event receives.
  `outputs`  | A list of values a function returns.
  `readonly` | Whether the function call can be done without a transaction or not.
  `payable`  | Whether the function can be paid or not.

  > Note: Both `readonly` and `payable` will be returned in the ICON 2.0
  > representation or a boolean value e.g. `0x1` for `true`.

  Each input will have the following keys:

  Key       | Description
  :-------- | :----------
  `name`    | Parameter name.
  `type`    | Parameter type. Either `int`, `str`, `bytes`, `bool` or `Address`.
  `indexed` | (Only for event logs) if the parameter is indexed or not.

  > Note: `indexed` will be returned in the ICON 2.0 representation of a boolean
  > e.g. `0x1` for `true`.

  Each output will have the following keys:

  Key    | Description
  :----- | :----------
  `type` | Result type. Either `int`, `str`, `bytes`, `bool`, `Address`, `dict` or `list`.
  """
  @spec get_score_api(Identity.t(), SCORE.t()) ::
          {:ok, list()}
          | {:error, Error.t()}
  def get_score_api(identity, score_address)

  def get_score_api(%Identity{} = identity, score_address) do
    with {:ok, request} <- Request.Goloop.get_score_api(identity, score_address) do
      Request.send(request)
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
      cumulativeStepUsed: 0,
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
  Gets a transaction by `hash`.

  ## Example

  - Requesting a successful transaction by `hash`:

  ```elixir
  iex> identity = Icon.RPC.Identity.new()
  iex> Icon.get_transaction_by_hash(identity, "0x917def9734385cbb0c1f3e9d6fc0e46706f51348ab9cea1d7e1bf44e1ed51b25")
  {
    :ok,
    %Icon.Schema.Types.Transaction{
      blockHash: "0xd6e8ed8035b38a5c09de59df101c7e6258e6d7e0690d3c6c6093045a5550bb83",
      blockHeight: 45162694,
      data: %{
        method: "transfer",
        params: %{
          "_data" => "0x7b226d6574686f64223a20225f73776170222c2022706172616d73223a207b22746f546f6b656e223a2022637838386664376466376464666638326637636337333563383731646335313938333863623233356262222c20226d696e696d756d52656365697665223a202231303030303230303030303030303030303030303030222c202270617468223a205b22637832363039623932346533336566303062363438613430393234356337656133393463343637383234222c2022637866363163643561343564633966393163313561613635383331613330613930643539613039363139222c2022637838386664376466376464666638326637636337333563383731646335313938333863623233356262225d7d7d",
          "_to" => "cx21e94c08c03daee80c25d8ee3ea22a20786ec231",
          "_value" => "0x363610bbaabe220000"
        }
      },
      dataType: :call,
      from: "hx948b9727f426ae7789741da8c796807f78ba137f",
      nid: 1,
      nonce: 223,
      signature: "TTfXvXZ3NG53R2tx9D69fMvmHW8mIIWWEDZnNfOgGG1BOeGYSYzV37PWCi7ryXKKAc7e80ue937yrull8hoZxgE=",
      stepLimit: 50000000,
      timestamp: ~U[2022-01-22 06:48:51.250054Z],
      to: "cx88fd7df7ddff82f7cc735c871dc519838cb235bb",
      txHash: "0x917def9734385cbb0c1f3e9d6fc0e46706f51348ab9cea1d7e1bf44e1ed51b25",
      txIndex: 2,
      value: 0,
      version: 3
    }
  }
  ```

  The `params` key cannot be decoded beforehand, so we need to use a schema to
  retrieve the Elixir values. Using the previous example, we would do something
  like this:

  ```elixir
  iex> identity = Icon.RPC.Identity.new()
  iex> {:ok, tx} = Icon.get_transaction_by_hash(identity, "0x917def9734385cbb0c1f3e9d6fc0e46706f51348ab9cea1d7e1bf44e1ed51b25")
  iex> schema = %{
  ...>   _data: :binary_data,
  ...>   _to: :address,
  ...>   _value: :loop
  ...> }
  iex> {:ok, decoded_params} = (
  ...>   schema
  ...>   |> Icon.Schema.generate()
  ...>   |> Icon.Schema.new(tx.data.params)
  ...>   |> Icon.Schema.load()
  ...>   |> Icon.Schema.apply()
  ...> )
  iex> put_in(tx, [:data, :params], decoded_params)
  %Icon.Schema.Types.Transaction{
    blockHash: "0xd6e8ed8035b38a5c09de59df101c7e6258e6d7e0690d3c6c6093045a5550bb83",
    blockHeight: 45162694,
    data: %{
      method: "transfer",
      params: %{
        _data: "{\\"method\\": \\"_swap\\", \\"params\\": {\\"toToken\\": \\"cx88fd7df7ddff82f7cc735c871dc519838cb235bb\\", \\"minimumReceive\\": \\"1000020000000000000000\\", \\"path\\": [\\"cx2609b924e33ef00b648a409245c7ea394c467824\\", \\"cxf61cd5a45dc9f91c15aa65831a30a90d59a09619\\", \\"cx88fd7df7ddff82f7cc735c871dc519838cb235bb\\"]}}",
        _to: "cx21e94c08c03daee80c25d8ee3ea22a20786ec231",
        _value: 1000020000000000000000
      }
    },
    dataType: :call,
    from: "hx948b9727f426ae7789741da8c796807f78ba137f",
    nid: 1,
    nonce: 223,
    signature: "TTfXvXZ3NG53R2tx9D69fMvmHW8mIIWWEDZnNfOgGG1BOeGYSYzV37PWCi7ryXKKAc7e80ue937yrull8hoZxgE=",
    stepLimit: 50000000,
    timestamp: ~U[2022-01-22 06:48:51.250054Z],
    to: "cx88fd7df7ddff82f7cc735c871dc519838cb235bb",
    txHash: "0x917def9734385cbb0c1f3e9d6fc0e46706f51348ab9cea1d7e1bf44e1ed51b25",
    txIndex: 2,
    value: 0,
    version: 3
  }
  ```

  For more information about schemas see `Icon.Schema` module.
  """
  @spec get_transaction_by_hash(Identity.t(), Hash.t()) ::
          {:ok, Transaction.t()}
          | {:error, Error.t()}
  def get_transaction_by_hash(identity, hash)

  def get_transaction_by_hash(%Identity{} = identity, hash) do
    with {:ok, request} <-
           Request.Goloop.get_transaction_by_hash(identity, hash),
         {:ok, response} <- Request.send(request) do
      load_transaction(response)
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
      cumulativeStepUsed: 0,
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
      cumulativeStepUsed: 0,
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
  - `call_schema` - Method parameters schema.
  - `timeout` - Time in milliseconds to wait for the transaction result.
  - `params` - Extra transaction parameters for overriding the defaults.

  While technically any parameter can be overriden with the `params` option, not
  all of them make sense to do so. The following are some of the most usuful
  parameters to modify via this option:

  - `nonce` - An arbitrary number used to prevent transaction hash collision.
  - `timestamp` - Transaction creation time. Timestamp is in microsecond.
  - `stepLimit` - Maximum step allowance that can be used by the transaction.

  ## Call Schema

  The `call_schema` option gives defines the types of the `call_params`. This is
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
  ...>   call_schema: %{
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
  ...>   call_schema: %{
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
      cumulativeStepUsed: 0,
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
    options =
      case options[:call_schema] do
        nil ->
          options

        value ->
          options
          |> Keyword.delete(:call_schema)
          |> Keyword.put(:schema, value)
      end

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
      cumulativeStepUsed: 0,
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
      cumulativeStepUsed: 0,
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
      cumulativeStepUsed: 0,
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
      cumulativeStepUsed: 0,
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

  @spec load_call_response(any(), keyword()) ::
          {:ok, any()} | {:error, Error.t()}
  defp load_call_response(response, options)

  defp load_call_response(response, options) do
    response_schema = options[:response_schema] || :any

    response_schema
    |> Schema.generate()
    |> Schema.new(response)
    |> Schema.load()
    |> apply_call_response(response_schema)
    |> case do
      {:ok, _} = ok ->
        ok

      {:error, _} ->
        reason =
          Error.new(
            reason: :server_error,
            message: "cannot cast call response"
          )

        {:error, reason}
    end
  end

  @spec apply_call_response(Schema.state(), Schema.t()) ::
          {:ok, any()}
          | {:error, Error.t()}
  defp apply_call_response(state, schema) do
    if is_atom(schema) and function_exported?(schema, :__schema__, 0) do
      Schema.apply(state, into: schema)
    else
      Schema.apply(state)
    end
  end

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

  @spec load_block(any()) ::
          {:ok, Block.t()}
          | {:error, Error.t()}
  defp load_block(data)

  defp load_block(data) when is_map(data) do
    Block
    |> Schema.generate()
    |> Schema.new(data)
    |> Schema.load()
    |> Schema.apply(into: Block)
  end

  defp load_block(_) do
    reason =
      Error.new(
        reason: :server_error,
        message: "cannot cast block"
      )

    {:error, reason}
  end

  @spec load_transaction(any()) ::
          {:ok, Transaction.t()}
          | {:error, Error.t()}
  defp load_transaction(data)

  defp load_transaction(data) when is_map(data) do
    Transaction
    |> Schema.generate()
    |> Schema.new(data)
    |> Schema.load()
    |> Schema.apply(into: Transaction)
  end

  defp load_transaction(_) do
    reason =
      Error.new(
        reason: :server_error,
        message: "cannot cast transaction"
      )

    {:error, reason}
  end
end
