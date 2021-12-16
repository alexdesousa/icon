defmodule Icon.RPC.Request do
  @moduledoc """
  This module defines a basic JSON RPC request payload.
  """
  @enforce_keys [:id, :method, :params, :options]

  @doc false
  defstruct [:id, :method, :params, :options]

  @typedoc """
  RPC ID.
  """
  @type id :: pos_integer()

  @typedoc """
  RPC Method.
  """
  @type method :: binary()

  @typedoc """
  RPC call parameters.
  """
  @type params :: map()

  @typedoc """
  RPC option.
  """
  @type option :: {:types, map()} | {atom(), any()}

  @typedoc """
  RPC options.
  """
  @type options :: [option()]

  @typedoc """
  A JSON RPC request.
  """
  @type t :: %__MODULE__{
          id: id :: pos_integer(),
          method: method :: method(),
          params: params :: params(),
          options: options :: options()
        }

  @doc """
  Builds an RPC call given a `method`.
  """
  @spec build(method()) :: t()
  def build(method) when is_binary(method) do
    build(method, %{}, [])
  end

  @doc """
  Builds an RPC request given a `method`, `params` and `options`.

  Though it's not mandatory, the options can include `types` to automatically
  `dump/1` the `params` when encoding to JSON. The idea is to be able to
  convert any type to ICON 2.0's internal representation. The following are the
  recommended types:

  - `Icon.Schema.Types.Integer` for Elixir's `non_neg_integer` type.
  - `Icon.Schema.Types.String` for Elixir's `binary` type.
  - `Icon.Schema.Types.Boolean` for Elixir's `boolean` type.
  - `Icon.Schema.Types.EOA` for Externally Owned Account (EOA) addresses.
  - `Icon.Schema.Types.SCORE` for SCORE addresses.
  - `Icon.Schema.Types.Address` for both EOA and SCORE addresses.
  - `Icon.Schema.Types.Hash` for hashes e.g. block hash.
  - `Icon.Schema.Types.Signature` for signatures.
  - `Icon.Schema.Types.BinaryData` for binary data.

  ### Example

  ```elixir
  iex> method = "icx_getBlockByHeight"
  iex> params = %{height: 42}
  iex> schema = %{height: :integer}
  iex> Icon.RPC.Request.build(method, params, schema: schema)
  %Icon.RPC.Request{
    id: 1639382704065742380,
    method: "icx_getBlockByHeight",
    options: [schema: %{height: :integer}],
    params: %{height: 42}
  }
  ```
  """
  @spec build(method(), params(), options()) :: t()
  def build(method, params, options)
      when is_binary(method) and is_map(params) and is_list(options) do
    %__MODULE__{
      id: :erlang.system_time(),
      method: method,
      params: params,
      options: options
    }
  end
end

defimpl Jason.Encoder, for: Icon.RPC.Request do
  @moduledoc """
  JSON encoder for an RPC request payload. This encoder, uses `dump/1` callback
  from an `Icon.Schema.Type` to convert the RPC call parameters.
  The recomended types for converting values to ICON 2.0 representation are the
  following:

  - `Icon.Schema.Types.Integer` for Elixir's `non_neg_integer` type.
  - `Icon.Schema.Types.String` for Elixir's `binary` type.
  - `Icon.Schema.Types.Boolean` for Elixir's `boolean` type.
  - `Icon.Schema.Types.EOA` for Externally Owned Account (EOA) addresses.
  - `Icon.Schema.Types.SCORE` for SCORE addresses.
  - `Icon.Schema.Types.Address` for both EOA and SCORE addresses.
  - `Icon.Schema.Types.Hash` for hashes e.g. block hash.
  - `Icon.Schema.Types.Signature` for signatures.
  - `Icon.Schema.Types.BinaryData` for binary data.
  """
  alias Icon.Schema
  alias Icon.Schema.Error

  @spec encode(Icon.RPC.Request.t(), Jason.Encode.opts()) :: binary()
  def encode(%Icon.RPC.Request{} = request, options) do
    schema = request.options[:schema]

    request
    |> Map.take([:id, :method, :params])
    |> Map.put(:jsonrpc, "2.0")
    |> Stream.reject(fn {_key, value} -> is_nil(value) end)
    |> Stream.reject(fn {_key, value} -> value == %{} end)
    |> Map.new()
    |> dump_params(schema)
    |> Jason.Encode.map(options)
  end

  #########
  # Helpers

  @spec dump_params(map(), nil | map()) :: map()
  defp dump_params(payload, types)

  defp dump_params(payload, nil), do: payload

  defp dump_params(%{params: params} = payload, schema) when is_map(params) do
    schema
    |> Schema.generate()
    |> Schema.new(params)
    |> Schema.dump()
    |> Schema.apply()
    |> case do
      {:ok, params} ->
        %{payload | params: params}

      {:error, %Error{message: message}} ->
        raise ArgumentError, message: message
    end
  end
end
