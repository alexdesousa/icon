defmodule Icon.RPC.IdentityTest do
  use ExUnit.Case, async: true

  require Icon.RPC.Identity
  alias Icon.RPC.Identity

  describe "new/0" do
    test "sets node to mainnet" do
      assert %Identity{
               node: "https://ctz.solidwallet.io"
             } = Identity.new()
    end

    test "sets network id to mainnet" do
      assert %Identity{network_id: 1} = Identity.new()
    end

    test "sets debug mode off" do
      assert %Identity{debug: false} = Identity.new()
    end
  end

  describe "new/1" do
    test "sets Mainet network id" do
      assert %Identity{network_id: 1} = Identity.new(network_id: :mainnet)
      assert %Identity{network_id: 1} = Identity.new(network_id: "0x01")
      assert %Identity{network_id: 1} = Identity.new(network_id: 1)
    end

    test "sets default Mainnet node when none provided" do
      assert %Identity{
               node: "https://ctz.solidwallet.io"
             } = Identity.new(network_id: :mainnet)
    end

    test "sets Sejong network id" do
      assert %Identity{network_id: 83} = Identity.new(network_id: :sejong)
      assert %Identity{network_id: 83} = Identity.new(network_id: "0x53")
      assert %Identity{network_id: 83} = Identity.new(network_id: 83)
    end

    test "sets default Sejong node when none provided" do
      assert %Identity{
               node: "https://sejong.net.solidwallet.io"
             } = Identity.new(network_id: :sejong)
    end

    test "sets Berlin network id" do
      assert %Identity{network_id: 7} = Identity.new(network_id: :berlin)
      assert %Identity{network_id: 7} = Identity.new(network_id: "0x07")
      assert %Identity{network_id: 7} = Identity.new(network_id: 7)
    end

    test "sets default Berlin node when none provided" do
      assert %Identity{
               node: "https://berlin.net.solidwallet.io"
             } = Identity.new(network_id: :berlin)
    end

    test "sets Lisbon network id" do
      assert %Identity{network_id: 2} = Identity.new(network_id: :lisbon)
      assert %Identity{network_id: 2} = Identity.new(network_id: "0x02")
      assert %Identity{network_id: 2} = Identity.new(network_id: 2)
    end

    test "sets default Lisbon node when none provided" do
      assert %Identity{
               node: "https://lisbon.net.solidwallet.io"
             } = Identity.new(network_id: :lisbon)
    end

    test "sets BTP network id" do
      assert %Identity{network_id: 66} = Identity.new(network_id: :btp)
      assert %Identity{network_id: 66} = Identity.new(network_id: "0x42")
      assert %Identity{network_id: 66} = Identity.new(network_id: 66)
    end

    test "sets default BTP node when none provided" do
      assert %Identity{
               node: "https://btp.net.solidwallet.io"
             } = Identity.new(network_id: :btp)
    end

    test "sets custom node even when network id is provided" do
      node = "https://custom.solidwallet.io"

      assert %Identity{
               node: ^node,
               network_id: 2
             } = Identity.new(node: node, network_id: :lisbon)
    end

    test "sets private key when valid" do
      %Curvy.Key{privkey: private_key} = key = Curvy.Key.generate()
      encoded = Base.encode16(private_key, case: :lower)

      assert %Identity{key: ^key} = Identity.new(private_key: encoded)
    end

    test "generates the right EOA address from a private key" do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      expected = "hxfd7e4560ba363f5aabd32caac7317feeee70ea57"

      assert %Identity{
               address: ^expected
             } = Identity.new(private_key: private_key)
    end
  end

  describe "has_address/1" do
    test "when the identity has an address, returns true" do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      expected = "hxfd7e4560ba363f5aabd32caac7317feeee70ea57"

      assert %Identity{
               address: ^expected
             } = identity = Identity.new(private_key: private_key)

      assert Identity.has_address(identity)
    end

    test "when the identity doesn't have an address, returns false" do
      assert %Identity{} = identity = Identity.new()
      refute Identity.has_address(identity)
    end
  end

  describe "can_sign/1" do
    test "when the identity can sign, returns true" do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      assert %Identity{} = identity = Identity.new(private_key: private_key)

      assert Identity.can_sign(identity)
    end

    test "when the identity cannot sign, returns false" do
      assert %Identity{} = identity = Identity.new()
      refute Identity.can_sign(identity)
    end
  end

  describe "inspect/1" do
    test "sets network id for Mainnet" do
      identity = Identity.new(network_id: :mainnet)

      assert inspect(identity) =~ ~s/network_id: "0x1 (Mainnet)"/
    end

    test "sets network id for Sejong" do
      identity = Identity.new(network_id: :sejong)

      assert inspect(identity) =~ ~s/network_id: "0x53 (Sejong)"/
    end

    test "sets network id for Berlin" do
      identity = Identity.new(network_id: :berlin)

      assert inspect(identity) =~ ~s/network_id: "0x7 (Berlin)"/
    end

    test "sets network id for Lisbon" do
      identity = Identity.new(network_id: :lisbon)

      assert inspect(identity) =~ ~s/network_id: "0x2 (Lisbon)"/
    end

    test "sets network id for BTP" do
      identity = Identity.new(network_id: :btp)

      assert inspect(identity) =~ ~s/network_id: "0x42 (BTP)"/
    end

    test "sets other network id" do
      identity =
        Identity.new(
          network_id: "0x1337",
          node: "https://custom.solidwallet.io"
        )

      assert inspect(identity) =~ ~s/network_id: "0x1337"/
    end

    test "redacts private key" do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      assert inspect(identity) =~ ~s/private_key: "8ad9..."/
    end

    test "inspects node" do
      identity = Identity.new()

      assert inspect(identity) =~ ~s(node: "https://ctz.solidwallet.io")
    end

    test "inspects debug" do
      identity = Identity.new()

      assert inspect(identity) =~ ~s/debug: false/
    end

    test "inspects address" do
      # Taken from Python ICON SDK tests.
      private_key =
        "8ad9889bcee734a2605a6c4c50dd8acd28f54e62b828b2c8991aa46bd32976bf"

      identity = Identity.new(private_key: private_key)

      assert inspect(identity) =~
               ~s/address: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57"/
    end
  end
end
