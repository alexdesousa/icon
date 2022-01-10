defmodule Icon.RPC.Request.Goloop do
  @moduledoc """
  This module defines the Goloop API request payloads.
  """
  import Icon.RPC.Identity, only: [has_address: 1]
  import Icon.Schema, only: [enum: 1]

  alias Icon.RPC.{Identity, Request}
  alias Icon.Schema
  alias Icon.Schema.Error

  @typedoc """
  Supported methods.
  """
  @type method ::
          :get_last_block
          | :get_block_by_height
          | :get_block_by_hash
          | :get_balance
          | :call
          | :get_score_api
          | :get_total_supply
          | :get_transaction_result
          | :get_transaction_by_hash
          | :send_transaction
          | :send_transaction_and_wait
          | :wait_transaction_result
          | :estimate_step

  @doc """
  Builds request for getting the lastest block.

  ## Example

  The following builds a request to get the latest block:

  ```elixir
  iex> identity = Icon.RPC.Identity.new()
  iex> Icon.RPC.Request.get_last_block(identity)
  {
    :ok,
    %Icon.RPC.Request{
      method: "icx_getLastBlock",
      options: ...,
      params: %{}
    }
  }
  ```
  """
  @spec get_last_block(Identity.t()) :: {:ok, Request.t()}
  def get_last_block(identity)

  def get_last_block(%Identity{} = identity) do
    request =
      :get_last_block
      |> method()
      |> Request.build(%{}, identity: identity)

    {:ok, request}
  end

  @doc """
  Builds a request for getting a block by `height`.

  ## Example

  The following builds a request to get a block by height:

  ```elixir
  iex> identity = Icon.RPC.Identity.new()
  iex> Icon.RPC.Request.get_block_by_height(identity, 42)
  {
    :ok,
    %Icon.RPC.Request{
      method: "icx_getBlockByHeight",
      options: ...,
      params: %{
        height: 42
      }
    }
  }
  ```
  """
  @spec get_block_by_height(Identity.t(), Schema.Types.Integer.t()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def get_block_by_height(identity, height)

  def get_block_by_height(%Identity{} = identity, height) do
    schema = %{height: {:integer, required: true}}

    with {:ok, params} <- validate(schema, height: height) do
      request =
        :get_block_by_height
        |> method()
        |> Request.build(params, schema: schema, identity: identity)

      {:ok, request}
    end
  end

  @doc """
  Builds a request for getting a block by `hash`.

  ## Example

  The following builds a request to get a block by hash:

  ```elixir
  iex> identity = Icon.RPC.Identity.new()
  iex> Icon.RPC.Request.get_block_by_hash(identity, "0x8e25acc5b5c74375079d51828760821fc6f54283656620b1d5a715edcc0770c6")
  {
    :ok,
    %Icon.RPC.Request{
      method: "icx_getBlockByHash",
      options: ...,
      params: %{
        hash: "0x8e25acc5b5c74375079d51828760821fc6f54283656620b1d5a715edcc0770c6"
      }
    }
  }
  ```
  """
  @spec get_block_by_hash(Identity.t(), Schema.Types.Hash.t()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def get_block_by_hash(identity, hash)

  def get_block_by_hash(%Identity{} = identity, hash) do
    schema = %{hash: {:hash, required: true}}

    with {:ok, params} <- validate(schema, hash: hash) do
      request =
        :get_block_by_hash
        |> method()
        |> Request.build(params, schema: schema, identity: identity)

      {:ok, request}
    end
  end

  @doc """
  Builds a request for calling a readonly SCORE `method` with some optional
  `params` and `options` using a valid `identity` with a wallet.

  Options:
  - `schema` - `method`'s schema to validate `params`.

  ## Example

  The following shows how build a call to the method `getBalance` in a SCORE:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.RPC.Request.Goloop.call(
  ...>   identity,
  ...>   "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
  ...>   "getBalance",
  ...>   %{address: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"},
  ...>   %{address: {:address, required: true}}
  ...> )
  {
    :ok,
    %Icon.RPC.Request{
      method: "icx_call",
      options: ...,
      params: %{
        from: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
        to: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
        dataType: "call",
        data: %{
          method: "getBalance",
          params: %{
            address: "hx2e243ad926ac48d15156756fce28314357d49d83"
          }
        }
      }
    }
  }
  ```
  """
  @spec call(Identity.t(), Schema.Types.SCORE.t(), binary()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  @spec call(
          Identity.t(),
          Schema.Types.SCORE.t(),
          binary(),
          nil | map() | keyword()
        ) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  @spec call(
          Identity.t(),
          Schema.Types.SCORE.t(),
          binary(),
          nil | map() | keyword(),
          keyword()
        ) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def call(identity, to, method, params \\ nil, options \\ [])

  def call(
        %Identity{address: from} = identity,
        to,
        method,
        params,
        options
      )
      when has_address(identity) do
    call_schema = options[:schema]

    schema = %{
      from: {:eoa_address, required: true},
      to: {:score_address, required: true},
      dataType: {enum([:call]), default: :call},
      data:
        if call_schema do
          %{
            method: {:string, required: true},
            params: {call_schema, required: true}
          }
        else
          %{method: {:string, required: true}}
        end
    }

    params = %{
      from: from,
      to: to,
      data: %{
        method: method,
        params: params
      }
    }

    with {:ok, params} <- validate(schema, params) do
      request =
        :call
        |> method()
        |> Request.build(params, schema: schema, identity: identity)

      {:ok, request}
    end
  end

  def call(%Identity{} = _identity, _to, _method, _params, _options) do
    identity_must_have_a_wallet()
  end

  @doc """
  Builds a request for getting the balance of an EOA or SCORE `address`. If the
  address is not provided, it uses the one in the `identity`.

  ## Example

  The following builds a request for getting the balance of the wallet doing the
  request:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.RPC.Request.get_balance(identity)
  {
    :ok,
    %Icon.RPC.Request{
      method: "icx_getBalance",
      options: ...,
      params: %{
        address: "hxbe258ceb872e08851f1f59694dac2558708ece11"
      }
    }
  }
  ```
  """
  @spec get_balance(Identity.t()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  @spec get_balance(Identity.t(), nil | Schema.Types.Address.t()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def get_balance(identity, address \\ nil)

  def get_balance(%Identity{} = identity, address) do
    address = address || identity.address
    schema = %{address: {:address, required: true}}

    with {:ok, params} <- validate(schema, address: address) do
      request =
        :get_balance
        |> method()
        |> Request.build(params, schema: schema, identity: identity)

      {:ok, request}
    end
  end

  @doc """
  Builds a request for getting the API of a SCORE given its `address`.

  ## Example

  The following builds a request for getting the API of a SCORE:

  ```elixir
  iex> identity = Icon.RPC.Identity.new()
  iex> Icon.RPC.Request.get_score_api(identity, "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32")
  {
    :ok,
    %Icon.RPC.Request{
      method: "icx_getScoreApi",
      options: ...,
      params: %{
        address: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32"
      }
    }
  }
  ```
  """
  @spec get_score_api(Identity.t(), Schema.Types.SCORE.t()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def get_score_api(identity, address)

  def get_score_api(%Identity{} = identity, address) do
    schema = %{address: {:score_address, required: true}}

    with {:ok, params} <- validate(schema, address: address) do
      request =
        :get_score_api
        |> method()
        |> Request.build(params, schema: schema, identity: identity)

      {:ok, request}
    end
  end

  @doc """
  Builds a request for geting the total ICX supply.

  ## Example

  The following builds a request for getting the ICX total supply:

  ```elixir
  iex> identity = Icon.RPC.Identity.new()
  iex> Icon.RPC.Request.get_total_supply(identity)
  {
    :ok,
    %Icon.RPC.Request{
      method: "icx_getTotalSupply",
      options: ...,
      params: %{}
    }
  }
  ```
  """
  @spec get_total_supply(Identity.t()) :: {:ok, Request.t()}
  def get_total_supply(identity)

  def get_total_supply(%Identity{} = identity) do
    request =
      :get_total_supply
      |> method()
      |> Request.build(%{}, identity: identity)

    {:ok, request}
  end

  @doc """
  Builds a request for getting the transaction result given its `tx_hash` and
  some optional `options`.

  Options:
  - `timeout` - Timeout in milliseconds for waiting for the result of the
    transaction.

  ## Example

  The following builds a request for getting a transaction result:

  ```elixir
  iex> identity = Icon.RPC.Identity.new()
  iex> Icon.RPC.Request.get_transaction_result(identity, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b")
  {
    :ok,
    %Icon.RPC.Request{
      method: "icx_getTransactionResult",
      options: ...,
      params: %{
        txHash: "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"
      }
    }
  }
  ```
  """
  @spec get_transaction_result(Identity.t(), Schema.Types.Hash.t()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  @spec get_transaction_result(Identity.t(), Schema.Types.Hash.t(), keyword()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def get_transaction_result(identity, tx_hash, options \\ [])

  def get_transaction_result(%Identity{} = identity, tx_hash, options) do
    schema = %{txHash: {:hash, required: true}}

    with {:ok, params} <- validate(schema, txHash: tx_hash) do
      timeout = options[:timeout] || 0

      method =
        if timeout > 0,
          do: :wait_transaction_result,
          else: :get_transaction_result

      options =
        if timeout > 0,
          do: [schema: schema, identity: identity, timeout: timeout],
          else: [schema: schema, identity: identity]

      request =
        method
        |> method()
        |> Request.build(params, options)

      {:ok, request}
    end
  end

  @doc """
  Builds a request for getting a transaction by `tx_hash`.

  ## Example

  The following builds a request for getting a transaction:

  ```elixir
  iex> identity = Icon.RPC.Identity.new()
  iex> Icon.RPC.Request.get_transaction_by_hash(identity, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b")
  {
    :ok,
    %Icon.RPC.Request{
      method: "icx_getTransactionByHash",
      options: ...,
      params: %{
        txHash: "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"
      }
    }
  }
  ```
  """
  @spec get_transaction_by_hash(Identity.t(), Schema.Types.Hash.t()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def get_transaction_by_hash(identity, tx_hash)

  def get_transaction_by_hash(%Identity{} = identity, tx_hash) do
    schema = %{txHash: {:hash, required: true}}

    with {:ok, params} <- validate(schema, txHash: tx_hash) do
      request =
        :get_transaction_by_hash
        |> method()
        |> Request.build(params, schema: schema, identity: identity)

      {:ok, request}
    end
  end

  @doc """
  Builds an ICX transfer transaction given a `recipient` address and the
  `amount` of ICX in loop (1 ICX = 10¹⁸ loop).

  Options:
  - `timeout` - Time in milliseconds to wait for the transaction result.
  - `params` - Extra transaction parameters for overriding the defaults.

  ### Example

  The following builds a request for sending 1 ICX to another wallet:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.RPC.Request.transfer(
  ...>   identity,
  ...>   "hx2e243ad926ac48d15156756fce28314357d49d83",
  ...>   1_000_000_000_000_000_000
  ...> )
  {
    :ok,
    %Icon.RPC.Request{
      method: "icx_sendTransaction",
      options: ...,
      params: %{
        from: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
        to: "hx2e243ad926ac48d15156756fce28314357d49d83",
        value: 1_000_000_000_000_000_000,
        nid: 1,
        nonce: 1641487595040282,
        timestamp: ~U[2022-01-06 16:46:35.042078Z],
        version: 3
      }
    }
  }
  ```
  """
  @spec transfer(
          Identity.t(),
          Schema.Types.Address.t(),
          Schema.Types.Loop.t()
        ) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  @spec transfer(
          Identity.t(),
          Schema.Types.Address.t(),
          Schema.Types.Loop.t(),
          keyword()
        ) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def transfer(identity, recipient, amount, options \\ [])

  def transfer(%Identity{} = identity, to, value, options)
      when has_address(identity) do
    params =
      options
      |> Keyword.get(:params, %{})
      |> Map.put(:to, to)
      |> Map.put(:value, value)

    schema =
      base_transaction_schema()
      |> Map.merge(%{
        to: {:address, required: true},
        value: {:loop, required: true}
      })

    with {:ok, params} <- add_identity(identity, params),
         {:ok, params} <- validate(schema, params) do
      timeout = options[:timeout] || 0

      method =
        if timeout > 0,
          do: :send_transaction_and_wait,
          else: :send_transaction

      request =
        method
        |> method()
        |> Request.build(params,
          schema: schema,
          identity: identity,
          timeout: timeout
        )

      {:ok, request}
    end
  end

  def transfer(%Identity{} = _identity, _recipient, _amount, _options) do
    identity_must_have_a_wallet()
  end

  @doc """
  Builds an `message` transfer to a given `recipient`.

  Options:
  - `timeout` - Time in milliseconds to wait for the transaction result.
  - `params` - Extra transaction parameters for overriding the defaults.

  ### Example

  The following builds a request for sending a message to another address:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.RPC.Request.send_message(
  ...>   identity,
  ...>   "hx2e243ad926ac48d15156756fce28314357d49d83",
  ...>   "Hello world!"
  ...> )
  {
    :ok,
    %Icon.RPC.Request{
      method: "icx_sendTransaction",
      options: ...,
      params: %{
        from: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
        to: "hx2e243ad926ac48d15156756fce28314357d49d83",
        nid: 1,
        nonce: 1641487595040282,
        timestamp: ~U[2022-01-06 16:46:35.042078Z],
        version: 3,
        dataType: :message,
        data: "Hello world!"
      }
    }
  }
  ```
  """
  @spec send_message(Identity.t(), Schema.Types.Address.t(), binary()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  @spec send_message(
          Identity.t(),
          Schema.Types.Address.t(),
          binary(),
          keyword()
        ) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def send_message(identity, recipient, message, options \\ [])

  def send_message(%Identity{} = identity, to, message, options)
      when has_address(identity) do
    params =
      options
      |> Keyword.get(:params, %{})
      |> Map.put(:to, to)
      |> Map.put(:data, message)

    schema =
      base_transaction_schema()
      |> Map.merge(%{
        to: {:address, required: true},
        dataType: {enum([:message]), default: :message},
        data: {:binary_data, required: true}
      })

    with {:ok, params} <- add_identity(identity, params),
         {:ok, params} <- validate(schema, params) do
      timeout = options[:timeout] || 0

      method =
        if timeout > 0,
          do: :send_transaction_and_wait,
          else: :send_transaction

      request =
        method
        |> method()
        |> Request.build(params,
          schema: schema,
          identity: identity,
          timeout: timeout
        )

      {:ok, request}
    end
  end

  def send_message(%Identity{} = _identity, _recipient, _message, _options) do
    identity_must_have_a_wallet()
  end

  @doc """
  Builds a transaction for calling a SCORE `method`.

  Options:
  - `timeout` - Time in milliseconds to wait for the transaction result.
  - `params` - Extra transaction parameters for overriding the defaults.
  - `schema` - Method parameters schema.

  ### Example

  The following builds a request for calling the method `transfer` in a SCORE:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.RPC.Request.transaction_call(
  ...>   identity,
  ...>   "cx2e243ad926ac48d15156756fce28314357d49d83",
  ...>   "transfer",
  ...>   %{
  ...>     address: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
  ...>     value: 1_000_000_000_000_000_000
  ...>   },
  ...>   %{
  ...>     address: {:address, required: true},
  ...>     value: {:loop, required: true}
  ...>   }
  ...> )
  {
    :ok,
    %Icon.RPC.Request{
      method: "icx_sendTransaction",
      options: ...,
      params: %{
        from: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
        to: "cx2e243ad926ac48d15156756fce28314357d49d83",
        nid: 1,
        nonce: 1641487595040282,
        timestamp: ~U[2022-01-06 16:46:35.042078Z],
        version: 3,
        dataType: :call,
        data: %{
          method: "transfer",
          params: %{
            address: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
            value: 1_000_000_000_000_000_000
          }
        }
      }
    }
  }
  ```
  """
  @spec transaction_call(Identity.t(), Schema.Types.SCORE.t(), binary()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  @spec transaction_call(
          Identity.t(),
          Schema.Types.SCORE.t(),
          binary(),
          nil | map() | keyword()
        ) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  @spec transaction_call(
          Identity.t(),
          Schema.Types.SCORE.t(),
          binary(),
          nil | map() | keyword(),
          keyword()
        ) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def transaction_call(identity, score, method, params \\ nil, options \\ [])

  def transaction_call(%Identity{} = identity, to, method, call_params, options)
      when has_address(identity) do
    params =
      options
      |> Keyword.get(:params, %{})
      |> Map.put(:to, to)
      |> Map.put(:data, %{
        method: method,
        params: call_params
      })

    call_schema = options[:schema]

    schema =
      base_transaction_schema()
      |> Map.merge(%{
        to: {:score_address, required: true},
        dataType: {enum([:call]), default: :call},
        data:
          if call_schema do
            {%{
               method: {:string, required: true},
               params: {call_schema, required: true}
             }, required: true}
          else
            {%{method: {:string, required: true}}, required: true}
          end
      })

    with {:ok, params} <- add_identity(identity, params),
         {:ok, params} <- validate(schema, params) do
      timeout = options[:timeout] || 0

      method =
        if timeout > 0,
          do: :send_transaction_and_wait,
          else: :send_transaction

      request =
        method
        |> method()
        |> Request.build(params,
          schema: schema,
          identity: identity,
          timeout: timeout
        )

      {:ok, request}
    end
  end

  def transaction_call(%Identity{} = _identity, _to, _method, _params, _options) do
    identity_must_have_a_wallet()
  end

  @doc """
  Builds a request for deploying a new SCORE given its `content`.

  Options:
  - `timeout` - Time in milliseconds to wait for the transaction result.
  - `params` - Extra transaction parameters for overriding the defaults.
  - `content_type` - MIME type of the SCORE contents. Defaults to
    `application/zip`.
  - `on_install_params` - Parameters for the function `on_install/0`.
  - `on_install_schema` - Schema for the parameters of the function
    `on_install/0`.

  ### Example

  The following builds a request for deploying a SCORE:

  ```elixir
  iex> {:ok, content} = File.read("./my-contract.javac")
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.RPC.Request.install_score(
  ...>   identity,
  ...>   content,
  ...>   on_install_params: %{
  ...>     address: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57"
  ...>   },
  ...>   on_install_schema: %{
  ...>     address: {:address, required: true}
  ...>   }
  ...> )
  {
    :ok,
    %Icon.RPC.Request{
      method: "icx_sendTransaction",
      options: ...,
      params: %{
        from: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
        to: "cx0000000000000000000000000000000000000000",
        nid: 1,
        nonce: 1641487595040282,
        timestamp: ~U[2022-01-06 16:46:35.042078Z],
        version: 3,
        dataType: :deploy,
        data: %{
          content_type: "application/zip",
          content: <<70, 79, 82, 49, 0, ...>>,
          params: %{
            address: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57"
          }
        }
      }
    }
  }
  ```
  """
  @spec install_score(Identity.t(), Schema.Types.BinaryData.t()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  @spec install_score(Identity.t(), Schema.Types.BinaryData.t(), keyword()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def install_score(identity, content, options \\ [])

  def install_score(%Identity{} = identity, content, options)
      when has_address(identity) do
    params =
      options
      |> Keyword.get(:params, %{})
      |> Map.put(:to, "cx0000000000000000000000000000000000000000")
      |> Map.put(:data, %{
        contentType: options[:content_type] || "application/zip",
        content: content,
        params: options[:on_install_params]
      })

    on_install_schema = options[:on_install_schema]

    schema =
      base_transaction_schema()
      |> Map.merge(%{
        to: {:score_address, required: true},
        dataType: {enum([:deploy]), default: :deploy},
        data:
          if on_install_schema do
            {%{
               contentType: {:string, required: true},
               content: {:binary_data, required: true},
               params: {on_install_schema, required: true}
             }, required: true}
          else
            {%{
               contentType: {:string, required: true},
               content: {:binary_data, required: true}
             }, required: true}
          end
      })

    with {:ok, params} <- add_identity(identity, params),
         {:ok, params} <- validate(schema, params) do
      timeout = options[:timeout] || 0

      method =
        if timeout > 0,
          do: :send_transaction_and_wait,
          else: :send_transaction

      request =
        method
        |> method()
        |> Request.build(params,
          schema: schema,
          identity: identity,
          timeout: timeout
        )

      {:ok, request}
    end
  end

  def install_score(%Identity{} = _identity, _contents, _options) do
    identity_must_have_a_wallet()
  end

  @doc """
  Builds a request for updating an existent SCORE given its `address` and
  `content`.

  Options:
  - `timeout` - Time in milliseconds to wait for the transaction result.
  - `params` - Extra transaction parameters for overriding the defaults.
  - `content_type` - MIME type of the SCORE contents. Defaults to
    `application/zip`.
  - `on_update_params` - Parameters for the function `on_update/0`.
  - `on_update_schema` - Schema for the parameters of the function
    `on_update/0`.

  ### Example

  The following builds a request for updating a SCORE:

  ```elixir
  iex> {:ok, content} = File.read("./my-updated-contract.javac")
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.RPC.Request.update_score(
  ...>   identity,
  ...>   "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
  ...>   content,
  ...>   on_update_params: %{
  ...>     address: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57"
  ...>   },
  ...>   on_update_schema: %{
  ...>     address: {:address, required: true}
  ...>   }
  ...> )
  {
    :ok,
    %Icon.RPC.Request{
      method: "icx_sendTransaction",
      options: ...,
      params: %{
        from: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        nid: 1,
        nonce: 1641487595040282,
        timestamp: ~U[2022-01-06 16:46:35.042078Z],
        version: 3,
        dataType: :deploy,
        data: %{
          content_type: "application/zip",
          content: <<70, 79, 82, 49, 0, ...>>,
          params: %{
            address: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57"
          }
        }
      }
    }
  }
  ```
  """
  @spec update_score(
          Identity.t(),
          Schema.Types.SCORE.t(),
          Schema.Types.BinaryData.t()
        ) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  @spec update_score(
          Identity.t(),
          Schema.Types.SCORE.t(),
          Schema.Types.BinaryData.t(),
          keyword()
        ) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def update_score(identity, score_address, content, options \\ [])

  def update_score(%Identity{} = identity, to, content, options)
      when has_address(identity) do
    params =
      options
      |> Keyword.get(:params, %{})
      |> Map.put(:to, to)
      |> Map.put(:data, %{
        contentType: options[:content_type] || "application/zip",
        content: content,
        params: options[:on_update_params]
      })

    on_update_schema = options[:on_update_schema]

    schema =
      base_transaction_schema()
      |> Map.merge(%{
        to: {:score_address, required: true},
        dataType: {enum([:deploy]), default: :deploy},
        data:
          if on_update_schema do
            {%{
               contentType: {:string, required: true},
               content: {:binary_data, required: true},
               params: {on_update_schema, required: true}
             }, required: true}
          else
            {%{
               contentType: {:string, required: true},
               content: {:binary_data, required: true}
             }, required: true}
          end
      })

    with {:ok, params} <- add_identity(identity, params),
         {:ok, params} <- validate(schema, params) do
      timeout = options[:timeout] || 0

      method =
        if timeout > 0,
          do: :send_transaction_and_wait,
          else: :send_transaction

      request =
        method
        |> method()
        |> Request.build(params,
          schema: schema,
          identity: identity,
          timeout: timeout
        )

      {:ok, request}
    end
  end

  def update_score(%Identity{} = _identity, _to, _contents, _options) do
    identity_must_have_a_wallet()
  end

  @doc """
  Builds a request for depositing ICX in loop (10¹⁸ loop = 1 ICX) into a SCORE
  for paying other user's fees when transacting with it (fee sharing).

  Options:
  - `timeout` - Time in milliseconds to wait for the transaction result.
  - `params` - Extra transaction parameters for overriding the defaults.

  ### Example

  The following builds a request for depositing ICX into a SCORE for fee
  sharing:

  ```elixir
  iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
  iex> Icon.RPC.Request.shared_fee_deposit(
  ...>   identity,
  ...>   "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
  ...>   1_000_000_000_000_000_000
  ...> )
  {
    :ok,
    %Icon.RPC.Request{
      method: "icx_sendTransaction",
      options: ...,
      params: %{
        from: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
        to: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
        value: 1_000_000_000_000_000_000,
        nid: 1,
        nonce: 1641487595040282,
        timestamp: ~U[2022-01-06 16:46:35.042078Z],
        version: 3,
        dataType: :deposit,
        data: %{
          action: :add
        }
      }
    }
  }
  ```
  """
  @spec shared_fee_deposit(
          Identity.t(),
          Schema.Types.SCORE.t(),
          Schema.Types.Loop.t()
        ) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  @spec shared_fee_deposit(
          Identity.t(),
          Schema.Types.SCORE.t(),
          Schema.Types.Loop.t(),
          keyword()
        ) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def shared_fee_deposit(identity, score_address, amount, options \\ [])

  def shared_fee_deposit(%Identity{} = identity, to, amount, options)
      when has_address(identity) do
    params =
      options
      |> Keyword.get(:params, %{})
      |> Map.put(:to, to)
      |> Map.put(:value, amount)

    schema =
      base_transaction_schema()
      |> Map.merge(%{
        to: {:score_address, required: true},
        value: {:loop, required: true},
        dataType: {enum([:deposit]), default: :deposit},
        data:
          {%{
             action: {enum([:add]), default: :add}
           }, default: %{action: "add"}}
      })

    with {:ok, params} <- add_identity(identity, params),
         {:ok, params} <- validate(schema, params) do
      timeout = options[:timeout] || 0

      method =
        if timeout > 0,
          do: :send_transaction_and_wait,
          else: :send_transaction

      request =
        method
        |> method()
        |> Request.build(params,
          schema: schema,
          identity: identity,
          timeout: timeout
        )

      {:ok, request}
    end
  end

  def shared_fee_deposit(%Identity{} = _identity, _to, _amount, _options) do
    identity_must_have_a_wallet()
  end

  @doc """
  Sends a transaction given some `options`.

  Options:
  - `params` - The transaction params. Depends on the `dataType` which is either
    `:call`, `:deploy`, `:deposit`, `:message` or `nil` (for ICX transfers).
  - `schema` - Params schema for `:call` or `:deploy` transactions if they have
    them.
  - `timeout` - Timeout in milliseconds for waiting for the transaction. It does
    not wait by default.
  """
  @spec send_transaction(Identity.t(), keyword()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def send_transaction(identity, options)

  def send_transaction(%Identity{} = identity, options) do
    with {:ok, schema} <- transaction_schema(options),
         {:ok, params} <- add_identity(identity, options[:params] || %{}),
         {:ok, params} <- validate(schema, params) do
      timeout = options[:timeout] || 0

      method =
        if timeout > 0,
          do: :send_transaction_and_wait,
          else: :send_transaction

      options =
        if timeout > 0,
          do: [schema: schema, identity: identity, timeout: timeout],
          else: [schema: schema, identity: identity]

      request =
        method
        |> method()
        |> Request.build(params, options)

      {:ok, request}
    end
  end

  @doc """
  Builds a request for requesting the step limit estimation of a transaction.
  """
  @spec estimate_step(Identity.t(), map(), Schema.t()) :: {:ok, Request.t()}
  def estimate_step(identity, params, schema)

  def estimate_step(%Identity{} = identity, params, schema) do
    identity = %{identity | debug: true}

    request =
      :estimate_step
      |> method()
      |> Request.build(params, schema: schema, identity: identity)

    {:ok, request}
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
  defp method(:call), do: "icx_call"
  defp method(:get_balance), do: "icx_getBalance"
  defp method(:get_score_api), do: "icx_getScoreApi"
  defp method(:get_total_supply), do: "icx_getTotalSupply"
  defp method(:get_transaction_result), do: "icx_getTransactionResult"
  defp method(:get_transaction_by_hash), do: "icx_getTransactionByHash"
  defp method(:send_transaction), do: "icx_sendTransaction"
  defp method(:send_transaction_and_wait), do: "icx_sendTransactionAndWait"
  defp method(:wait_transaction_result), do: "icx_waitTransactionResult"
  defp method(:estimate_step), do: "debug_estimateStep"

  @spec add_identity(Identity.t(), keyword() | map()) ::
          {:ok, map()}
          | {:error, Error.t()}
  defp add_identity(identity, params)

  defp add_identity(%Identity{} = identity, params) when is_list(params) do
    add_identity(identity, Map.new(params))
  end

  defp add_identity(%Identity{address: "hx" <> _} = identity, params)
       when is_map(params) do
    params =
      params
      |> Map.put(:nid, identity.network_id)
      |> Map.put(:from, identity.address)

    {:ok, params}
  end

  defp add_identity(%Identity{}, params) when is_map(params) do
    {:error, Error.new(reason: :invalid_request, message: "Invalid identity")}
  end

  ############################
  # Transaction schema helpers

  @spec transaction_schema(keyword()) ::
          {:ok, Schema.t()}
          | {:error, Error.t()}
  defp transaction_schema(options) do
    schema = %{
      dataType: {:enum, [:call, :deploy, :deposit, :message]}
    }

    case validate(schema, options[:params] || %{}) do
      {:ok, %{dataType: :call}} ->
        call_transaction_schema(options)

      {:ok, %{dataType: :deploy}} ->
        deploy_transaction_schema(options)

      {:ok, %{dataType: :deposit}} ->
        deposit_transaction_schema(options)

      {:ok, %{dataType: :message}} ->
        message_transaction_schema()

      {:ok, _} ->
        transfer_transaction_schema()

      {:error, %Error{}} = error ->
        error
    end
  end

  # Base transaction schema
  @spec base_transaction_schema() :: Schema.t()
  defp base_transaction_schema do
    %{
      version: {:integer, required: true, default: 3},
      from: {:eoa_address, required: true},
      stepLimit: :integer,
      nonce: {:integer, default: &default_nonce/1},
      timestamp: {:timestamp, required: true, default: &default_timestamp/1},
      nid: {:integer, required: true},
      signature: :signature
    }
  end

  @spec default_nonce(Schema.state()) :: non_neg_integer()
  defp default_nonce(%Schema{} = _state) do
    :erlang.system_time(:microsecond)
  end

  @spec default_timestamp(Schema.state()) :: DateTime.t()
  defp default_timestamp(%Schema{} = _state) do
    DateTime.utc_now()
  end

  # Coin transfer transaction schema.
  @spec transfer_transaction_schema() :: {:ok, Schema.t()}
  defp transfer_transaction_schema do
    schema =
      base_transaction_schema()
      |> Map.merge(%{
        to: {:address, required: true},
        value: {:loop, required: true}
      })

    {:ok, schema}
  end

  # Call transaction schema.
  @spec call_transaction_schema(keyword()) :: {:ok, Schema.t()}
  defp call_transaction_schema(options) do
    call_schema = options[:schema]

    call_schema =
      if call_schema do
        %{
          method: {:string, required: true},
          params: {call_schema, required: true}
        }
      else
        %{method: {:string, required: true}}
      end

    schema =
      base_transaction_schema()
      |> Map.merge(%{
        to: {:score_address, required: true},
        value: :loop,
        dataType: {{:enum, [:call]}, default: :call, required: true},
        data: {call_schema, required: true}
      })

    {:ok, schema}
  end

  # Deploy transaction schema.
  @spec deploy_transaction_schema(keyword()) :: {:ok, Schema.t()}
  defp deploy_transaction_schema(options) do
    deploy_schema = options[:schema]

    deploy_schema =
      if deploy_schema do
        %{
          contentType: {:string, required: true},
          content: {:binary_data, required: true},
          params: {deploy_schema, required: true}
        }
      else
        %{
          contentType: {:string, required: true},
          content: {:binary_data, required: true}
        }
      end

    schema =
      base_transaction_schema()
      |> Map.merge(%{
        to: {:score_address, required: true},
        value: :loop,
        dataType: {{:enum, [:deploy]}, default: :deploy, required: true},
        data: {deploy_schema, required: true}
      })

    {:ok, schema}
  end

  # Deposit transaction schema.
  @spec deposit_transaction_schema(keyword()) ::
          {:ok, Schema.t()}
          | {:error, Error.t()}
  defp deposit_transaction_schema(options) do
    deposit_type = %{
      data: %{
        action: {{:enum, [:add, :withdraw]}, required: true}
      }
    }

    case validate(deposit_type, options[:params] || %{}) do
      {:ok, %{data: %{action: :add}}} ->
        deposit_add_transaction_schema()

      {:ok, %{data: %{action: :withdraw}}} ->
        deposit_withdraw_transaction_schema()

      {:error, %Error{}} = error ->
        error
    end
  end

  @spec deposit_add_transaction_schema() :: {:ok, Schema.t()}
  defp deposit_add_transaction_schema do
    schema =
      base_transaction_schema()
      |> Map.merge(%{
        to: {:address, required: true},
        value: {:loop, required: true},
        dataType: {{:enum, [:deposit]}, default: :deposit, required: true},
        data: {
          %{
            action: {{:enum, [:add]}, default: :add, required: true}
          },
          required: true
        }
      })

    {:ok, schema}
  end

  @spec deposit_withdraw_transaction_schema() :: {:ok, Schema.t()}
  defp deposit_withdraw_transaction_schema do
    schema =
      base_transaction_schema()
      |> Map.merge(%{
        to: {:address, required: true},
        value: :loop,
        dataType: {{:enum, [:deposit]}, default: :deposit, required: true},
        data: {
          %{
            action: {{:enum, [:withdraw]}, default: :withdraw, required: true},
            id: :hash,
            amount: :loop
          },
          required: true
        }
      })

    {:ok, schema}
  end

  # Message transaction validation.
  @spec message_transaction_schema() :: {:ok, Schema.t()}
  defp message_transaction_schema do
    schema =
      base_transaction_schema()
      |> Map.merge(%{
        to: {:address, required: true},
        value: :loop,
        dataType: {{:enum, [:message]}, default: :message, required: true},
        data: {:binary_data, required: true}
      })

    {:ok, schema}
  end

  ###############
  # Error helpers

  @spec identity_must_have_a_wallet() :: {:error, Error.t()}
  defp identity_must_have_a_wallet do
    reason =
      Error.new(
        reason: :invalid_request,
        message: "identity must have a wallet"
      )

    {:error, reason}
  end
end
