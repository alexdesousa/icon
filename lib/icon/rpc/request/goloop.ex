defmodule Icon.RPC.Request.Goloop do
  @moduledoc """
  This module defines the Goloop API request payloads.
  """
  alias Icon.RPC.Request
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

  @doc """
  Gets last block.
  """
  @spec get_last_block() :: {:ok, Request.t()}
  def get_last_block do
    request =
      :get_last_block
      |> method()
      |> Request.build()

    {:ok, request}
  end

  @doc """
  Gets block by `height`.
  """
  @spec get_block_by_height(Schema.Types.Integer.t()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def get_block_by_height(height) do
    schema = %{height: {:integer, required: true}}

    with {:ok, params} <- validate(schema, height: height) do
      request =
        :get_block_by_height
        |> method()
        |> Request.build(params, schema: schema)

      {:ok, request}
    end
  end

  @doc """
  Gets block by `hash`.
  """
  @spec get_block_by_hash(Schema.Types.Hash.t()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def get_block_by_hash(hash) do
    schema = %{hash: {:hash, required: true}}

    with {:ok, params} <- validate(schema, hash: hash) do
      request =
        :get_block_by_hash
        |> method()
        |> Request.build(params, schema: schema)

      {:ok, request}
    end
  end

  @doc """
  Calls a SCORE `method`. The call is always sent `from` an EOA address `to` a
  SCORE address.
  """
  @spec call(Schema.Types.EOA.t(), Schema.Types.SCORE.t(), keyword()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def call(from, to, options) do
    call_schema = options[:schema]
    call_method = options[:method]
    call_params = options[:params]

    schema = %{
      from: {:eoa_address, required: true},
      to: {:score_address, required: true},
      dataType: {:string, default: "call"},
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
        method: call_method,
        params: call_params
      }
    }

    with {:ok, params} <- validate(schema, params) do
      request =
        :call
        |> method()
        |> Request.build(params, schema: schema)

      {:ok, request}
    end
  end

  @doc """
  Gets the balance of an EOA or SCORE `address`.
  """
  @spec get_balance(Schema.Types.Address.t()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def get_balance(address) do
    schema = %{address: {:address, required: true}}

    with {:ok, params} <- validate(schema, address: address) do
      request =
        :get_balance
        |> method()
        |> Request.build(params, schema: schema)

      {:ok, request}
    end
  end

  @doc """
  Gets the API of a SCORE given its `address`.
  """
  @spec get_score_api(Schema.Types.SCORE.t()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def get_score_api(address) do
    schema = %{address: {:score_address, required: true}}

    with {:ok, params} <- validate(schema, address: address) do
      request =
        :get_score_api
        |> method()
        |> Request.build(params, schema: schema)

      {:ok, request}
    end
  end

  @doc """
  Gets the total ICX supply.
  """
  @spec get_total_supply() :: {:ok, Request.t()}
  def get_total_supply do
    request =
      :get_total_supply
      |> method()
      |> Request.build()

    {:ok, request}
  end

  @doc """
  Gets the transaction result given its `tx_hash`.
  """
  @spec get_transaction_result(Schema.Types.Hash.t()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def get_transaction_result(tx_hash) do
    schema = %{txHash: {:hash, required: true}}

    with {:ok, params} <- validate(schema, txHash: tx_hash) do
      request =
        :get_transaction_result
        |> method()
        |> Request.build(params, schema: schema)

      {:ok, request}
    end
  end

  @doc """
  Gets transaction by `tx_hash`.
  """
  @spec get_transaction_by_hash(Schema.Types.Hash.t()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def get_transaction_by_hash(tx_hash) do
    schema = %{txHash: {:hash, required: true}}

    with {:ok, params} <- validate(schema, txHash: tx_hash) do
      request =
        :get_transaction_by_hash
        |> method()
        |> Request.build(params, schema: schema)

      {:ok, request}
    end
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
  @spec send_transaction(keyword()) :: {:ok, Request.t()} | {:error, Error.t()}
  def send_transaction(options)

  def send_transaction(options) do
    with {:ok, schema} <- transaction_schema(options),
         {:ok, params} <- validate(schema, options[:params] || %{}) do
      timeout = options[:timeout] || 0

      method =
        if timeout > 0,
          do: :send_transaction_and_wait,
          else: :send_transaction

      options =
        if timeout > 0,
          do: [schema: schema, timeout: timeout],
          else: [schema: schema]

      request =
        method
        |> method()
        |> Request.build(params, options)

      {:ok, request}
    end
  end

  @doc """
  Gets transaction result given it `tx_hash` waiting for it for `timeout`
  milliseconds.
  """
  @spec wait_transaction_result(Schema.Types.Hash.t(), pos_integer()) ::
          {:ok, Request.t()}
          | {:error, Error.t()}
  def wait_transaction_result(tx_hash, timeout) when timeout > 0 do
    schema = %{txHash: {:hash, required: true}}

    with {:ok, params} <- validate(schema, txHash: tx_hash) do
      request =
        :wait_transaction_result
        |> method()
        |> Request.build(params, schema: schema, timeout: timeout)

      {:ok, request}
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
  defp method(:call), do: "icx_call"
  defp method(:get_balance), do: "icx_getBalance"
  defp method(:get_score_api), do: "icx_getScoreApi"
  defp method(:get_total_supply), do: "icx_getTotalSupply"
  defp method(:get_transaction_result), do: "icx_getTransactionResult"
  defp method(:get_transaction_by_hash), do: "icx_getTransactionByHash"
  defp method(:send_transaction), do: "icx_sendTransaction"
  defp method(:send_transaction_and_wait), do: "icx_sendTransactionAndWait"
  defp method(:wait_transaction_result), do: "icx_waitTransactionResult"

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

  # Coin transfer transaction schema.
  @spec transfer_transaction_schema() :: {:ok, Schema.t()}
  defp transfer_transaction_schema do
    schema = %{
      version: {:integer, required: true},
      from: {:eoa_address, required: true},
      to: {:address, required: true},
      value: {:loop, required: true},
      stepLimit: {:integer, required: true},
      timestamp: {:timestamp, required: true},
      nid: {:integer, required: true},
      signature: {:signature, required: true},
      nonce: {:integer, default: 1}
    }

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

    schema = %{
      version: {:integer, required: true},
      from: {:eoa_address, required: true},
      to: {:score_address, required: true},
      value: :loop,
      stepLimit: {:integer, required: true},
      timestamp: {:timestamp, required: true},
      nid: {:integer, required: true},
      signature: {:signature, required: true},
      nonce: {:integer, default: 1},
      dataType: {{:enum, [:call]}, default: :call, required: true},
      data: {call_schema, required: true}
    }

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

    schema = %{
      version: {:integer, required: true},
      from: {:eoa_address, required: true},
      to: {:score_address, required: true},
      value: :loop,
      stepLimit: {:integer, required: true},
      timestamp: {:timestamp, required: true},
      nid: {:integer, required: true},
      signature: {:signature, required: true},
      nonce: {:integer, default: 1},
      dataType: {{:enum, [:deploy]}, default: :deploy, required: true},
      data: {deploy_schema, required: true}
    }

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
    schema = %{
      version: {:integer, required: true},
      from: {:eoa_address, required: true},
      to: {:address, required: true},
      value: {:loop, required: true},
      stepLimit: {:integer, required: true},
      timestamp: {:timestamp, required: true},
      nid: {:integer, required: true},
      signature: {:signature, required: true},
      nonce: {:integer, default: 1},
      dataType: {{:enum, [:deposit]}, default: :deposit, required: true},
      data: {
        %{
          action: {{:enum, [:add]}, default: :add, required: true}
        },
        required: true
      }
    }

    {:ok, schema}
  end

  @spec deposit_withdraw_transaction_schema() :: {:ok, Schema.t()}
  defp deposit_withdraw_transaction_schema do
    schema = %{
      version: {:integer, required: true},
      from: {:eoa_address, required: true},
      to: {:address, required: true},
      value: :loop,
      stepLimit: {:integer, required: true},
      timestamp: {:timestamp, required: true},
      nid: {:integer, required: true},
      signature: {:signature, required: true},
      nonce: {:integer, default: 1},
      dataType: {{:enum, [:deposit]}, default: :deposit, required: true},
      data: {
        %{
          action: {{:enum, [:withdraw]}, default: :withdraw, required: true},
          id: :hash,
          amount: :loop
        },
        required: true
      }
    }

    {:ok, schema}
  end

  # Message transaction validation.
  @spec message_transaction_schema() :: {:ok, Schema.t()}
  defp message_transaction_schema do
    schema = %{
      version: {:integer, required: true},
      from: {:eoa_address, required: true},
      to: {:address, required: true},
      value: :loop,
      stepLimit: {:integer, required: true},
      timestamp: {:timestamp, required: true},
      nid: {:integer, required: true},
      signature: {:signature, required: true},
      nonce: {:integer, default: 1},
      dataType: {{:enum, [:message]}, default: :message, required: true},
      data: {:binary_data, required: true}
    }

    {:ok, schema}
  end
end
