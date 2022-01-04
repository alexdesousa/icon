defmodule Icon.RPC.Request do
  @moduledoc """
  This module defines a basic JSON RPC request payload.
  """
  import Icon.RPC.Identity, only: [can_sign: 1]

  alias Icon.RPC.Identity
  alias Icon.Schema
  alias Icon.Schema.Error

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

  @transaction "icx_sendTransaction"

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

  @doc """
  Serializes a transaction `request`.
  """
  @spec serialize(t()) :: {:ok, binary()} | {:error, Error.t()}
  def serialize(%__MODULE__{
        method: @transaction,
        params: params,
        options: %{schema: schema}
      }) do
    state =
      schema
      |> Schema.generate()
      |> Schema.new(params)
      |> Schema.dump()

    with {:ok, params} <- Schema.apply(state) do
      serialized = "#{@transaction}.#{do_serialize(params)}"

      {:ok, serialized}
    end
  end

  def serialize(%__MODULE__{method: method}) do
    reason =
      Error.new(
        reason: :invalid_params,
        message: "cannot serialize method #{method}"
      )

    {:error, reason}
  end

  @doc """
  Signs `request`.
  """
  @spec sign(t()) :: {:ok, t()} | {:error, Error.t()}
  def sign(request)

  def sign(
        %__MODULE__{
          method: @transaction,
          params: params,
          options: %{identity: %Identity{} = identity}
        } = request
      )
      when is_map(params) and params != %{} and can_sign(identity) do
    with {:ok, serialized} <- serialize(request) do
      {:ok, do_sign(request, serialized)}
    end
  end

  def sign(%__MODULE__{}) do
    reason =
      Error.new(
        reason: :invalid_request,
        message: "cannot sign request"
      )

    {:error, reason}
  end

  @doc """
  Whether a `request` is signed correctly or not.
  """
  @spec verify(t()) :: boolean()
  def verify(request)

  def verify(
        %__MODULE__{
          method: @transaction,
          params: %{signature: signature} = params,
          options: %{identity: %Identity{key: key} = identity}
        } = request
      )
      when is_map(params) and params != %{} and can_sign(identity) do
    with {:ok, decoded_signature} <- Base.decode64(signature),
         curvy_signature = to_curvy(decoded_signature),
         encoded_signature = Base.encode64(curvy_signature),
         {:ok, serialized} <- serialize(request),
         message = hash(serialized),
         verified when is_boolean(verified) <-
           Curvy.verify(encoded_signature, message, key, encoding: :base64) do
      verified
    else
      _ ->
        false
    end
  end

  def verify(%__MODULE__{} = _request) do
    false
  end

  #########
  # Helpers

  # Puts either the debug or the normal endpoint.
  @spec put_url(options()) :: options()
  defp put_url(options) do
    case options[:identity] do
      %Identity{debug: false, node: node} ->
        Keyword.put(options, :url, "#{node}/api/v3")

      %Identity{debug: true, node: node} ->
        Keyword.put(options, :url, "#{node}/api/v3d")
    end
  end

  @spec do_sign(t(), binary()) :: t()
  defp do_sign(request, serialized_request)

  defp do_sign(
         %__MODULE__{
           params: params,
           options: %{identity: %Identity{key: key}}
         } = request,
         serialized_request
       ) do
    signature =
      serialized_request
      |> hash()
      |> Curvy.sign(key, compact: true, hash: :sha256)
      |> from_curvy()
      |> Base.encode64()

    %{request | params: Map.put(params, :signature, signature)}
  end

  @spec do_serialize(any()) :: binary()
  defp do_serialize(params)

  defp do_serialize(data) when is_map(data) do
    data
    |> Enum.sort_by(fn {key, _} -> key end, :asc)
    |> Stream.map(fn
      {:signature, _} ->
        ""

      {key, value} when is_map(value) ->
        "#{key}.{#{do_serialize(value)}}"

      {key, value} when is_list(value) ->
        "#{key}.[#{do_serialize(value)}]"

      {key, value} ->
        "#{key}.#{do_serialize(value)}"
    end)
    |> Stream.reject(&(&1 == ""))
    |> Enum.join(".")
  end

  defp do_serialize(data) when is_list(data) do
    data
    |> Stream.map(fn value -> do_serialize(value) end)
    |> Enum.join(".")
  end

  defp do_serialize(nil) do
    "\\0"
  end

  defp do_serialize(data) when is_binary(data) do
    data
    |> to_charlist()
    |> Enum.map(fn
      ?\\ -> [?\\, ?\\]
      ?{ -> [?\\, ?{]
      ?} -> [?\\, ?}]
      ?[ -> [?\\, ?[]
      ?] -> [?\\, ?]]
      ?. -> [?\\, ?.]
      char -> char
    end)
    |> IO.iodata_to_binary()
  end

  @spec hash(binary()) :: binary()
  defp hash(message) do
    :crypto.hash(:sha3_256, message)
  end

  @spec from_curvy(binary()) :: binary()
  defp from_curvy(compacted_signature)

  defp from_curvy(<<
         v::8-unsigned-integer,
         r::bytes-size(32),
         s::bytes-size(32)
       >>) do
    recovery_id = v - (27 + 4)

    <<r::bytes-size(32), s::bytes-size(32), recovery_id::8-unsigned-integer>>
  end

  @spec to_curvy(binary()) :: binary()
  defp to_curvy(compacted_signature)

  defp to_curvy(<<
         r::bytes-size(32),
         s::bytes-size(32),
         recovery_id::8-unsigned-integer
       >>) do
    v = recovery_id + (27 + 4)

    <<v::8-unsigned-integer, r::bytes-size(32), s::bytes-size(32)>>
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
