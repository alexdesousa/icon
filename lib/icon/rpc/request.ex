defmodule Icon.RPC.Request do
  @moduledoc """
  This module defines a basic JSON RPC request payload.
  """
  alias Icon.RPC.Identity

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
  @type option ::
          {:schema, module() | map()}
          | {:timeout, non_neg_integer()}
          | {:identity, Identity.t()}
          | {:url, binary()}

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
          options: options :: map()
        }

  @doc """
  Builds an RPC request given a `method`, `params` and `options`.

  Though it's not mandatory, the options can include `types` to automatically
  `dump/1` the `params` when encoding to JSON. The idea is to be able to
  convert any type to ICON 2.0's internal representation. The following are the
  recommended types:

  - `Icon.Schema.Types.Address` for both EOA and SCORE addresses.
  - `Icon.Schema.Types.BinaryData` for binary data.
  - `Icon.Schema.Types.Boolean` for Elixir's `boolean` type.
  - `Icon.Schema.Types.EOA` for Externally Owned Account (EOA) addresses.
  - `Icon.Schema.Types.Hash` for hashes e.g. block hash.
  - `Icon.Schema.Types.Integer` for Elixir's `non_neg_integer` type.
  - `Icon.Schema.Types.Loop` for loop (1 ICX = 10¹⁸ loop) which is a
    `non_neg_integer` type.
  - `Icon.Schema.Types.SCORE` for SCORE addresses.
  - `Icon.Schema.Types.Signature` for signatures.
  - `Icon.Schema.Types.String` for Elixir's `binary` type.
  - `Icon.Schema.Types.Timestamp` for Elixir's `DateTime`.

  ### Example

  ```elixir
  iex> method = "icx_getBlockByHeight"
  iex> params = %{height: 42}
  iex> schema = %{height: :integer}
  iex> Icon.RPC.Request.build(method, params, schema: schema)
  %Icon.RPC.Request{
    id: 1639382704065742380,
    method: "icx_getBlockByHeight",
    options: [
      schema: %{height: :integer},
      identity: #Identity<
        node: "https://ctz.solidwallet.io",
        network_id: "0x01 (Mainnet)",
        debug: false
      >,
      url: "https://ctz.solidwallet.io/api/v3"
    ],
    params: %{height: 42}
  }
  ```
  """
  @spec build(method(), params(), options()) :: t()
  def build(method, params, options)
      when is_binary(method) and is_map(params) and is_list(options) do
    options =
      options
      |> Keyword.put_new(:identity, Identity.new())
      |> put_url()
      |> Map.new()

    %__MODULE__{
      id: :erlang.system_time(),
      method: method,
      params: params,
      options: options
    }
  end

  @spec put_url(options()) :: options()
  defp put_url(options) do
    case options[:identity] do
      %Identity{debug: false, node: node} ->
        Keyword.put(options, :url, "#{node}/api/v3")

      %Identity{debug: true, node: node} ->
        Keyword.put(options, :url, "#{node}/api/v3d")
    end
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
      {:ok, params} when is_map(params) and params == %{} ->
        Map.delete(payload, :params)

      {:ok, params} when is_map(params) ->
        %{payload | params: params}

      {:error, %Error{message: message}} ->
        raise ArgumentError, message: message
    end
  end
end
