defmodule Icon.RPC.Request do
  @moduledoc """
  This module defines a basic JSON RPC request payloads.

  ## Building a Request

  The requests built using `build/3` are prepared to be encoded as a JSON
  accepted by the ICON 2.0 JSON RPC v3. For building a request we need three
  things:

  - The name of the method we're calling.
  - The parameters we're sending along the method.
  - Some options to both validate the parameters, sign any transaction and
    build the actual request.

  e.g. let's say we want to query a block by its height, we would do the
  following:

  ```elixir
  iex> method = "icx_getBlockByHeight"
  iex> params = %{height: 42}
  iex> schema = %{height: :integer}
  iex> Icon.RPC.Request.build(method, params, schema: schema)
  %Icon.RPC.Request{
    id: 1_639_382_704_065_742_380,
    method: "icx_getBlockByHeight",
    options: %{
      schema: %{height: :integer},
      identity: #Identity<
        node: "https://ctz.solidwallet.io",
        network_id: "0x01 (Mainnet)",
        debug: false
      >,
      url: "https://ctz.solidwallet.io/api/v3"
    },
    params: %{height: 42}
  }
  ```

  > Note: The previous example is for documentation purpose. This functionality
  > is already present in `Icon.RPC.Request.Goloop`, so no need to build the
  > request ourselves.

  And, when using the function `Jason.encode!`, we'll get the following JSON:

  ```json
  {
    "id": 1639382704065742380,
    "jsonrpc": "2.0",
    "method": "icx_getBlockByHeight",
    "params": {
      "height": "0x2a"
    }
  }
  ```

  ## Signing a Transaction

  Transactions need to be signed before sending them to the node. With the
  signature is possible to verify it comes from the wallet requesting it e.g.
  let's say we want to sent 1 ICX from one wallet to another:

  ```elixir
  iex> request = Icon.RPC.Request.build("icx_sendTransaction", ...)
  %Icon.RPC.Request{
    id: 1_639_382_704_065_742_380,
    method: "icx_sendTransaction",
    options: ...,
    params: %{
      from: "hx2e243ad926ac48d15156756fce28314357d49d83",
      to: "hxdd3ead969f0dfb0b72265ca584092a3fb25d27e0",
      value: 1_000_000_000_000_000_000,
      ...
    }
  }
  ```

  then we can sign it as follows:

  ```elixir
  iex> {:ok, request} = Icon.RPC.Request.sign(request)
  {
    :ok,
    %Icon.RPC.Request{
      id: 1_639_382_704_065_742_380,
      method: "icx_sendTransaction",
      options: ...,
      params: %{
        from: "hx2e243ad926ac48d15156756fce28314357d49d83",
        to: "hxdd3ead969f0dfb0b72265ca584092a3fb25d27e0",
        value: 1_000_000_000_000_000_000,
        signature: "Kut8d4uXzy0UPIU13l3OW5Ba3WNuq6B6w7+0v4XR4qQNv1Cy3qOmn7ih4TZrXZGT3qhkaRM/WCL+qmWyh86/tgA="
        ...
      }
    }
  }
  ```

  and also verify it to check everything is correct after signing it:

  ```elixir
  iex> Icon.RPC.Request.verify(request)
  true
  ```

  > Note: In order to sign a transaction, the option `identity` is mandatory and
  > it needs to be built using a `private_key` e.g.
  > ```elixir
  > iex> Icon.RPC.Identity.new(private_key: "8ad9...")
  > #Identity<[
  >   node: "https://ctz.solidwallet.io",
  >   network_id: "0x1 (Mainnet)",
  >   debug: false,
  >   address: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
  >   private_key: "8ad9..."
  > ]>
  > ```

  ### Sending the Request

  Once we're satisfied with our request, we can send it to the ICON 2.0
  blockchain using the `send/1` function:

  ```elixir
  iex> Icon.RPC.Request.send(request)
  {:ok, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"}
  ```

  where the `response()` will depend on the actual method being called.
  """
  import Icon.RPC.Identity, only: [can_sign: 1]

  alias Icon.RPC.Identity
  alias Icon.RPC.Request.Goloop
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
          {:schema, module() | Schema.t()}
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
          options:
            options :: %{
              required(:identity) => Identity.t(),
              required(:url) => binary(),
              optional(:schema) => module() | Schema.t(),
              optional(:timeout) => non_neg_integer()
            }
        }

  @typedoc """
  A JSON RPC response.
  """
  @type response :: binary() | list() | map()

  @transactions ["icx_sendTransaction", "icx_sendTransactionAndWait"]

  @doc """
  Builds an RPC request given a `method`, some `parameters` and general
  `options`.

  The `method` and `parameters` depend on the JSON RPC method we're calling,
  while the `options` have extra instructions for the actual request.

  Options:
  - `timeout` - Whether we should have a timeout on the call or not. This
    timeout only applies to methods we can wait on the result e.g.
    `icx_waitTransactionResult` and `icx_sendTransactionAndWait`.
  - `schema` - `Icon.Schema` for verifying the call `parameters`.
  - `identity` - `Icon.RPC.Identity` of the wallet performing the action. A full
    identity is not required for most readonly calls. However, it is necessary
    to have a full wallet configure for sending transactions to the ICON 2.0
    blockchain.
  - `url` - This endpoint is set automatically by the request builder.

  ## Encoding

  Though having the `schema` option is not mandatory, it is necessary whenever
  we're calling a `method` with `parameters` in order to convert them to the
  ICON 2.0 type representation as well as serializing transactions. For more
  information, check `Icon.Schema` module.

  ### Example

  The following example shows how to build a request for querying a block by
  `height`:

  ```elixir
  iex> method = "icx_getBlockByHeight"
  iex> params = %{height: 42}
  iex> schema = %{height: :integer}
  iex> Icon.RPC.Request.build(method, params, schema: schema)
  %Icon.RPC.Request{
    id: 1_639_382_704_065_742_380,
    method: "icx_getBlockByHeight",
    options: %{
      schema: %{height: :integer},
      identity: #Identity<
        node: "https://ctz.solidwallet.io",
        network_id: "0x01 (Mainnet)",
        debug: false
      >,
      url: "https://ctz.solidwallet.io/api/v3"
    },
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
  Adds step limit to a transaction. If no value is provided, then it will
  request for a node estimation.
  """
  @spec add_step_limit(t()) :: {:ok, t()} | {:error, Error.t()}
  @spec add_step_limit(t(), nil | Schema.Types.Loop.t()) ::
          {:ok, t()}
          | {:error, Error.t()}
  @spec add_step_limit(t(), nil | Schema.Types.Loop.t(), keyword()) ::
          {:ok, t()}
          | {:error, Error.t()}
  def add_step_limit(request, step_limit \\ nil, options \\ [])

  def add_step_limit(%__MODULE__{method: method} = request, nil, options)
      when method in @transactions do
    with :miss <- maybe_get_cached_step_limit(request, options),
         {:ok, step_limit} <- estimate_step(request) do
      maybe_cache_step_limit(request, step_limit, options)

      request = %{
        request
        | params: Map.put(request.params, :stepLimit, step_limit)
      }

      {:ok, request}
    else
      {:error, %Error{}} = error ->
        error

      {:ok, step_limit} ->
        add_step_limit(request, step_limit)
    end
  end

  def add_step_limit(
        %__MODULE__{method: method} = request,
        step_limit,
        _options
      )
      when is_integer(step_limit) and step_limit > 0 and method in @transactions do
    request = %{
      request
      | params: Map.put(request.params, :stepLimit, step_limit)
    }

    {:ok, request}
  end

  def add_step_limit(%__MODULE__{} = _request, _step_limit, _options) do
    reason =
      Error.new(
        reason: :invalid_request,
        message: "only transactions have step limit"
      )

    {:error, reason}
  end

  @doc """
  Serializes a transaction `request`.

  When building a transaction signature, one of the steps of the process is
  serializing the transaction. In general, the serialization process goes as
  follows:
  1. Convert the JSON RPC method parameters to the ICON representation.
  2. Serialize them.

  E.g. a request like the following:

  ```elixir
  %Icon.RPC.Request{
    id: 1_641_400_211_292_452_380,
    method: "icx_sendTransaction",
    options: ...,
    params: %{
      from: "hx2e243ad926ac48d15156756fce28314357d49d83",
      to: "hxdd3ead969f0dfb0b72265ca584092a3fb25d27e0",
      nid: 1,
      version: 3,
      timestamp: ~U[2022-01-05 16:30:11.292452Z],
      stepLimit: 100_000,
      value: 1_000_000_000_000_000_000
    }
  }
  ```

  would be serialized as follows:

  ```text
  icx_sendTransaction.from.hx2e243ad926ac48d15156756fce28314357d49d83.nid.0x1.stepLimit.0x186a0.timestamp.0x5d4d844874124.to.hxdd3ead969f0dfb0b72265ca584092a3fb25d27e0.value.0xde0b6b3a7640000.version.0x3
  ```

  The serialization rules are simple:

  - Values should be encoded to the ICONs encoding e.g. the integer `1` would
    be converted to `"0x1"`.
  - `<key>`/`<value>` pairs in maps should be converted to `"<key>.<value>"`
    string e.g. `{:a, 1}` would be converted to `"a.0x1"`
  - All keys in a map should be in alphabetical order.
  - All maps except the top level one should be surrounded by braces e.g.
    `%{a: 1}` would be converted to `"{a.0x1}"`.
  - Lists should be surrounded by brackets and its elements should be separated
    by `.` e.g. `[1,2,3]` would be converted to `"[0x1.0x2.0x3]"`.
  - The top level map should be preceded by `"icx_sendTransaction."` prefix e.g.
    `%{from: "hx...", ...}` would be converted to
    `"icx_sendTransaction.from.hx..."`
  - Any of the characters `\\`, `{`, `}`, `[`, `]` and `.` should be escaped by
    adding a `\\` before them e.g. `%{message: "..."}` would be encoded as
    `{message.\\.\\.\\.}`.
  """
  @spec serialize(t()) :: {:ok, binary()} | {:error, Error.t()}
  def serialize(%__MODULE__{
        method: method,
        params: params,
        options: %{schema: schema}
      })
      when method in @transactions do
    state =
      schema
      |> Schema.generate()
      |> Schema.new(params)
      |> Schema.dump()

    with {:ok, params} <- Schema.apply(state) do
      serialized = "icx_sendTransaction.#{do_serialize(params)}"

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

  Signing a request does the following:

  1. Serializes the parameters see `serialize/1`,
  2. Hash the serialized parameters with `SHA3_256` digest algorithm **twice**.
  3. Generate a SECP256K1 signature with the hash.
  4. Encode the signature in Base 64.
  5. Add the encoded signature to the transaction parameters.

  > Note: `Curvy` is the library used by this API for the signature. It
  > generates compact signatures in the form of `VRS` while ICON expects `RSV`
  > signatures. This modules handles the conversion between these formats
  > transparently.
  """
  @spec sign(t()) :: {:ok, t()} | {:error, Error.t()}
  def sign(request)

  def sign(
        %__MODULE__{
          method: method,
          params: params,
          options: %{identity: %Identity{} = identity}
        } = request
      )
      when is_map(params) and params != %{} and can_sign(identity) and
             method in @transactions do
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
          method: method,
          params: %{signature: signature} = params,
          options: %{identity: %Identity{key: key} = identity}
        } = request
      )
      when is_map(params) and params != %{} and can_sign(identity) and
             method in @transactions do
    with {:ok, decoded_signature} <- Base.decode64(signature),
         curvy_signature = to_curvy(decoded_signature),
         {:ok, serialized} <- serialize(request),
         hashed = hash(serialized),
         verified when is_boolean(verified) <-
           Curvy.verify(curvy_signature, hashed, key, hash: :sha3_256) do
      verified
    else
      _ ->
        false
    end
  end

  def verify(%__MODULE__{} = _request) do
    false
  end

  @doc """
  Sends a remote procedure call to an ICON 2.0 node.
  """
  @spec send(t()) :: {:ok, response()} | {:error, Error.t()}
  def send(request)

  def send(%__MODULE__{options: %{url: url}} = request) do
    payload = Jason.encode!(request)

    :post
    |> Finch.build(url, headers(request), payload)
    |> do_send()
  end

  ###############
  # Build helpers

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

  ####################
  # Estimation helpers

  @spec estimate_step(t()) ::
          {:ok, pos_integer()}
          | {:error, Error.t()}
  defp estimate_step(request)

  defp estimate_step(%__MODULE__{
         params: params,
         options: %{schema: schema, identity: identity}
       }) do
    with {:ok, request} <-
           Goloop.estimate_step(identity, params, schema),
         {:ok, "0x" <> _ = value} <- send(request),
         {:ok, step_limit} <- Icon.Schema.Types.Integer.load(value) do
      {:ok, step_limit}
    else
      {:error, %Error{}} = error ->
        error

      _ ->
        reason =
          Error.new(
            reason: :system_error,
            message: "cannot estimate stepLimit"
          )

        {:error, reason}
    end
  end

  @spec maybe_get_cached_step_limit(t(), keyword()) ::
          {:ok, pos_integer()} | :miss
  defp maybe_get_cached_step_limit(request, options)

  defp maybe_get_cached_step_limit(
         %__MODULE__{params: %{dataType: type}},
         _options
       )
       when type in [:deploy, :message] do
    :miss
  end

  defp maybe_get_cached_step_limit(%__MODULE__{} = request, options) do
    with true <- Keyword.get(options, :cache, true),
         key = {__MODULE__, :step_limit, request_hash(request)},
         value when is_integer(value) <- :persistent_term.get(key, :miss) do
      {:ok, value}
    else
      _ ->
        :miss
    end
  end

  @spec maybe_cache_step_limit(t(), pos_integer(), keyword()) :: :ok
  defp maybe_cache_step_limit(request, step_limit, options)

  defp maybe_cache_step_limit(
         %__MODULE__{params: %{dataType: type}},
         _step_limit,
         _options
       )
       when type in [:deploy, :message] do
    :ok
  end

  defp maybe_cache_step_limit(%__MODULE__{} = request, step_limit, options) do
    if Keyword.get(options, :cache, true) do
      key = {__MODULE__, :step_limit, request_hash(request)}
      :persistent_term.put(key, step_limit)
      :ok
    else
      :ok
    end
  end

  @spec request_hash(t()) :: non_neg_integer()
  defp request_hash(request)

  defp request_hash(%__MODULE__{
         method: method,
         params: %{dataType: :call} = params,
         options: %{schema: schema}
       }) do
    :erlang.phash2(%{
      schema: schema,
      method: method,
      params: %{
        from: params[:from],
        to: params[:to],
        dataType: :call,
        data: %{
          method: params[:data][:method],
          params: Map.keys(params[:data][:params])
        }
      }
    })
  end

  defp request_hash(%__MODULE__{
         method: method,
         params: %{dataType: :deposit} = params,
         options: %{schema: schema}
       }) do
    :erlang.phash2(%{
      schema: schema,
      method: method,
      params: %{
        from: params[:from],
        dataType: :deposit,
        data: %{
          action: params[:data][:action],
          id: Map.has_key?(params[:data], :id),
          amount: Map.has_key?(params[:data], :amount)
        }
      }
    })
  end

  defp request_hash(%__MODULE__{
         method: method,
         params: params,
         options: %{schema: schema}
       }) do
    :erlang.phash2(%{
      schema: schema,
      method: method,
      params: %{
        from: params[:from]
      }
    })
  end

  #######################
  # Serialization helpers

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

  ###################
  # Signature helpers

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
      |> Curvy.sign(key, compact: true, hash: :sha3_256)
      |> from_curvy()
      |> Base.encode64()

    %{request | params: Map.put(params, :signature, signature)}
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

  ##############
  # HTTP helpers

  @spec headers(t()) :: [{binary(), binary()}]
  defp headers(%__MODULE__{options: options}) do
    case options[:timeout] || 0 do
      timeout when timeout > 0 ->
        [
          {"Content-type", "application/json"},
          {"Icon-Options", "#{timeout}"}
        ]

      _ ->
        [{"Content-type", "application/json"}]
    end
  end

  @spec do_send(Finch.Request.t()) ::
          {:ok, response()}
          | {:error, Error.t()}
  defp do_send(%Finch.Request{} = request) do
    case Finch.request(request, Icon.Finch) do
      {:ok, %Finch.Response{body: data}} ->
        decode_response(data)

      {:error, _} ->
        {:error, Error.new(reason: :system_error)}
    end
  end

  @spec decode_response(binary()) :: {:ok, response()} | {:error, Error.t()}
  defp decode_response(data) do
    case Jason.decode(data) do
      {:ok, %{"result" => result}} ->
        {:ok, result}

      {:ok, %{"error" => error}} ->
        reason =
          Error.new(
            code: error["code"],
            message: error["message"],
            data: error["data"]
          )

        {:error, reason}

      {:error, _} ->
        {:error, Error.new(reason: :system_error)}
    end
  end
end

defimpl Jason.Encoder, for: Icon.RPC.Request do
  @moduledoc """
  JSON encoder for an RPC request payload. This encoder, uses `dump/1` callback
  from an `Icon.Schema.Type` to convert the RPC call parameters.
  The recomended types for converting values to ICON 2.0 representation are the
  following:

  - `Icon.Schema.Types.Address` for both EOA and SCORE addresses.
  - `Icon.Schema.Types.BinaryData` for binary data.
  - `Icon.Schema.Types.Boolean` for Elixir's `boolean` type.
  - `Icon.Schema.Types.EOA` for Externally Owned Account (EOA) addresses.
  - `Icon.Schema.Types.Hash` for hashes e.g. block hash.
  - `Icon.Schema.Types.Integer` for Elixir's `non_neg_integer` type.
  - `Icon.Schema.Types.Loop` for loop where 10¹⁸ loop = 1 ICX. It delegates to
    `Icon.Schema.Types.Integer`.
  - `Icon.Schema.Types.SCORE` for SCORE addresses.
  - `Icon.Schema.Types.Signature` for signatures.
  - `Icon.Schema.Types.String` for Elixir's `binary` type.
  - `Icon.Schema.Types.Timestamp` for Elixir's `DateTime.t()` type.
  """
  alias Icon.Schema
  alias Icon.Schema.Error

  @doc """
  Converts a `request` to JSON.
  """
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
