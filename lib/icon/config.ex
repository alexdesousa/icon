defmodule Icon.Config do
  @moduledoc """
  This module defines different configuration variables for the ICON 2.0 SDK.
  """
  use Skogsra

  @envdoc """
  Mainnet node: this is a node connected to the ICON 2.0 network and it'll be
  used as the default options when creating an `Icon.RPC.Identity`.

  ```elixir
  iex> Icon.Config.mainnet_node!()
  "https://ctz.solidwallet.io"
  ```
  """
  app_env :mainnet_node, :icon, :mainnet_node,
    required: true,
    os_env: "MAINNET_NODE",
    default: "https://ctz.solidwallet.io"

  @envdoc """
  Sejong node: this is a test network node for applications without audit.

  ```elixir
  iex> Icon.Config.sejong_node!()
  "https://sejong.net.solidwallet.io"
  ```
  """
  app_env :sejong_node, :icon, :sejong_node,
    required: true,
    os_env: "SEJONG_NODE",
    default: "https://sejong.net.solidwallet.io"

  @envdoc """
  Berlin node: this is a test network node that offers the latest features and
  may be unstable. Resets happen frequently without notice.

  ```elixir
  iex> Icon.Config.berlin_node!()
  "https://berlin.net.solidwallet.io"
  ```
  """
  app_env :berlin_node, :icon, :berlin_node,
    required: true,
    os_env: "BERLIN_NODE",
    default: "https://berlin.net.solidwallet.io"

  @envdoc """
  Lisbon node: this is a test network node with long term support which
  environment is the closest to mainnet.

  ```elixir
  iex> Icon.Config.lisbon_node!()
  "https://lisbon.net.solidwallet.io"
  ```
  """
  app_env :lisbon_node, :icon, :lisbon_node,
    required: true,
    os_env: "LISBON_NODE",
    default: "https://lisbon.net.solidwallet.io"
end
