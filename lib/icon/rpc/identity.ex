defmodule Icon.RPC.Identity do
  @moduledoc """
  This module defines a struct with the basic identity information to query and
  transact with the ICON 2.0 JSON API.
  """

  @doc """
  Connection struct.
  """
  defstruct node: "https://ctz.solidwallet.io",
            network_id: 1,
            debug: false,
            key: nil,
            address: nil

  @typedoc """
  Connection.
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
  @type network_name :: :mainnet | :sejong | :berlin | :lisbon | :btp

  @typedoc """
  Initialization option.
  """
  @type option ::
          {:node, binary()}
          | {:network_id, pos_integer()}
          | {:network_id, Icon.Schema.Types.BinaryData.t()}
          | {:network_id, network_name()}
          | {:private_key, binary()}

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

  defp add_network_id(%__MODULE__{} = identity, :btp) do
    add_network_id(identity, 66)
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
    add_node(identity, "https://ctz.solidwallet.io")
  end

  defp add_node(%__MODULE__{network_id: 83} = identity, nil) do
    add_node(identity, "https://sejong.net.solidwallet.io")
  end

  defp add_node(%__MODULE__{network_id: 7} = identity, nil) do
    add_node(identity, "https://berlin.net.solidwallet.io")
  end

  defp add_node(%__MODULE__{network_id: 2} = identity, nil) do
    add_node(identity, "https://lisbon.net.solidwallet.io")
  end

  defp add_node(%__MODULE__{network_id: 66} = identity, nil) do
    add_node(identity, "https://btp.net.solidwallet.io")
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
  defp network_name(%Identity{network_id: 66}), do: "0x42 (BTP)"

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
