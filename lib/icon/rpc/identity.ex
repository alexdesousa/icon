defmodule Icon.RPC.Identity do
  @moduledoc """
  This module defines a struct with the basic identity information to query and
  transact with the ICON 2.0 JSON API.

  There are two types of identities:

  - With wallet.
  - Without wallet.

  For most methods, we'll only need an identity without a wallet. However, for
  transactions is necessary we add a wallet to our identity.

  Identities have the following fields:
  - `network_id` - Which is either the name (`network_name/0`) or the network ID
    number. Defaults to `:mainnet` (it's the same as `1`).
  - `node` - The URL to the node we want to use. It has default node URL per
    `network_id` for convinience, but they can be overriden.
  - `debug` - Whether the debug endpoint should be used or not. Defaults to
    `false`.
  - `key` - It's a `Curvy.Signature.t()`, though it's not visible when
    inspecting the struct. Instead the field shown would be an incomplete
    `private_key`.
  - `address` - EOA address derived from the `private_key`.

  e.g. the following creates an identity for interacting with Sejong testnet:

  ```elixir
  iex> Icon.RPC.Identity.new(network_id: :sejong, private_key: "8ad9...")
  #Identity<[
    node: "https://sejong.net.solidwallet.io",
    network_id: "0x53 (Sejong)",
    debug: false,
    address: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
    private_key: "8ad9..."
  ]>
  ```

  ## Networks

  Though in theory any ICON network can be used, this API only supports ICON 2.0
  networks by name.

  ### Mainnet

  This is ICON 2.0 network and the default option when creating an identity.

  ```elixir
  iex> Icon.RPC.Identity.new()
  #Identity<[
    node: "https://ctz.solidwallet.io",
    network_id: "0x1 (Mainnet)",
    debug: false
  ]>
  ```

  ### Sejong

  This test network is for testing applications without going through an audit
  and therefore may be unstable. It is equivalent to Yeouido network in ICON
  1.0.

  ```elixir
  iex> Icon.RPC.Identity.new(network_id: :sejong)
  #Identity<[
    node: "https://sejong.net.solidwallet.io",
    network_id: "0x53 (Sejong)",
    debug: false
  ]>
  ```

  ### Berlin

  This test network offers the latest features and may be unstable. Resets will
  happen frequently without notice.

  ```elixir
  iex> Icon.RPC.Identity.new(network_id: :berlin)
  #Identity<[
    node: "https://berlin.net.solidwallet.io",
    network_id: "0x7 (Berlin)",
    debug: false
  ]>
  ```

  ### Lisbon

  This is the long term support test network. It should be use to test
  applications in an environment close to mainnet. This is where you'll often
  see applications beta versions. Though resets can happen, they'll be avoided
  as much as possible. It is equivalent to Euljiro network in ICON 1.0.

  ```elixir
  iex> Icon.RPC.Identity.new(network_id: :lisbon)
  #Identity<[
    node: "https://lisbon.net.solidwallet.io",
    network_id: "0x2 (Lisbon)",
    debug: false
  ]>
  ```
  """
  alias Icon.Config

  @doc """
  Connection struct.
  """
  defstruct node: "https://ctz.solidwallet.io",
            network_id: 1,
            debug: false,
            key: nil,
            address: nil

  @typedoc """
  Identity.
  """
  @type t :: %__MODULE__{
          node: binary(),
          network_id: pos_integer(),
          debug: boolean(),
          key: nil | Curvy.Key.t(),
          address: nil | Icon.Schema.Types.EOA.t()
        }

  @typedoc """
  Network name.
  """
  @type network_name :: :mainnet | :sejong | :berlin | :lisbon

  @typedoc """
  Initialization option.
  """
  @type option ::
          {:node, binary()}
          | {:network_id, pos_integer()}
          | {:network_id, Icon.Schema.Types.BinaryData.t()}
          | {:network_id, network_name()}
          | {:private_key, :generate | binary()}

  @typedoc """
  Initialization options.
  """
  @type options :: [option()]

  @doc """
  Creates a new connection given some `options`.

  Options:
  - `node` - ICON 2.0 JSON API URL.
  - `network_id` - Either the name of the network or, its ID in hex string or
    integer.
  - `debug` - Whether the requests should be done in the debug endpoint or not.
  - `private_key` - Wallet private key as hex string.
  """
  @spec new() :: t()
  @spec new(options()) :: t()
  def new(options \\ []) do
    %__MODULE__{}
    |> add_network_id(options[:network_id])
    |> add_node(options[:node])
    |> maybe_add_debug(options[:debug])
    |> maybe_add_key(options[:private_key])
    |> maybe_add_address()
  end

  @doc """
  Whether the `identity` has an EOA address or not.
  """
  @spec has_address(t()) :: Macro.t()
  defguard has_address(identity)
           when is_struct(identity, __MODULE__) and
                  is_binary(identity.address) and
                  is_struct(identity.key, Curvy.Key)

  @doc """
  Whether the `identity` can sign or not.
  """
  @spec can_sign(t()) :: Macro.t()
  defguard can_sign(identity)
           when has_address(identity) and
                  is_binary(identity.node) and
                  is_integer(identity.network_id) and
                  identity.network_id >= 1

  #########
  # Helpers

  # Adds the network ID to the structure. It defaults to mainnet.
  @spec add_network_id(
          t(),
          nil
          | network_name()
          | Icon.Schema.Types.BinaryData.t()
          | pos_integer()
        ) :: t()
  defp add_network_id(identity, network_id)

  defp add_network_id(%__MODULE__{} = identity, nil) do
    add_network_id(identity, :mainnet)
  end

  defp add_network_id(%__MODULE__{} = identity, :mainnet) do
    add_network_id(identity, 1)
  end

  defp add_network_id(%__MODULE__{} = identity, :sejong) do
    add_network_id(identity, 83)
  end

  defp add_network_id(%__MODULE__{} = identity, :berlin) do
    add_network_id(identity, 7)
  end

  defp add_network_id(%__MODULE__{} = identity, :lisbon) do
    add_network_id(identity, 2)
  end

  defp add_network_id(%__MODULE__{} = identity, "0x" <> _ = network_id) do
    network_id =
      network_id
      |> Icon.Schema.Types.Integer.load()
      |> elem(1)

    add_network_id(identity, network_id)
  end

  defp add_network_id(%__MODULE__{} = identity, network_id)
       when is_integer(network_id) and network_id >= 1 do
    %{identity | network_id: network_id}
  end

  # Adds ICON 2.0 node. It defaults to Mainet node.
  @spec add_node(t(), nil | binary()) :: t()
  defp add_node(identity, node)

  defp add_node(%__MODULE__{network_id: 1} = identity, nil) do
    add_node(identity, Config.mainnet_node!())
  end

  defp add_node(%__MODULE__{network_id: 83} = identity, nil) do
    add_node(identity, Config.sejong_node!())
  end

  defp add_node(%__MODULE__{network_id: 7} = identity, nil) do
    add_node(identity, Config.berlin_node!())
  end

  defp add_node(%__MODULE__{network_id: 2} = identity, nil) do
    add_node(identity, Config.lisbon_node!())
  end

  defp add_node(%__MODULE__{} = identity, node) when is_binary(node) do
    %{identity | node: node}
  end

  # Adds debug mode.
  @spec maybe_add_debug(t(), nil | boolean()) :: t()
  defp maybe_add_debug(identity, debug)

  defp maybe_add_debug(%__MODULE__{} = identity, nil) do
    maybe_add_debug(identity, false)
  end

  defp maybe_add_debug(%__MODULE__{} = identity, debug)
       when is_boolean(debug) do
    %{identity | debug: debug}
  end

  # When private_key is provided, adds the full key to the structure.
  @spec maybe_add_key(t(), nil | binary()) :: t()
  defp maybe_add_key(identity, private_key)

  defp maybe_add_key(%__MODULE__{} = identity, nil) do
    identity
  end

  defp maybe_add_key(%__MODULE__{} = identity, :generate) do
    %{identity | key: Curvy.Key.generate()}
  end

  defp maybe_add_key(%__MODULE__{} = identity, private_key)
       when is_binary(private_key) do
    key =
      private_key
      |> String.downcase()
      |> Base.decode16!(case: :lower)
      |> Curvy.Key.from_privkey()

    %{identity | key: key}
  end

  # When the key is set, generates its EOA address.
  @spec maybe_add_address(t()) :: t()
  defp maybe_add_address(identity)

  defp maybe_add_address(%__MODULE__{key: %Curvy.Key{} = key} = identity) do
    <<_::bytes-size(1), rest::binary>> =
      Curvy.Key.to_pubkey(key, compressed: false)

    address =
      :sha3_256
      |> :crypto.hash(rest)
      |> binary_part(12, 20)
      |> Base.encode16(case: :lower)

    %{identity | address: "hx#{address}"}
  end

  defp maybe_add_address(%__MODULE__{} = identity) do
    identity
  end
end

defimpl Inspect, for: Icon.RPC.Identity do
  import Inspect.Algebra
  alias Icon.RPC.Identity

  def inspect(%Identity{} = identity, options) do
    values =
      [
        node: identity.node,
        network_id: network_name(identity),
        debug: identity.debug,
        address: identity.address,
        private_key: private_key(identity)
      ]
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)

    concat(["#Identity<", to_doc(values, options), ">"])
  end

  @spec network_name(Identity.t()) :: binary()
  defp network_name(identity)

  defp network_name(%Identity{network_id: 1}), do: "0x1 (Mainnet)"
  defp network_name(%Identity{network_id: 83}), do: "0x53 (Sejong)"
  defp network_name(%Identity{network_id: 7}), do: "0x7 (Berlin)"
  defp network_name(%Identity{network_id: 2}), do: "0x2 (Lisbon)"

  defp network_name(%Identity{network_id: network_id}) do
    network_id
    |> Icon.Schema.Types.Integer.dump()
    |> elem(1)
  end

  @spec private_key(Identity.t()) :: nil | binary()
  defp private_key(identity)

  defp private_key(%Identity{key: %Curvy.Key{} = key}) do
    redacted =
      key.privkey
      |> Base.encode16(case: :lower)
      |> binary_part(0, 4)

    "#{redacted}..."
  end

  defp private_key(%Identity{} = _identity) do
    nil
  end
end
