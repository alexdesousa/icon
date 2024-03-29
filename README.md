# Icon

![Build status](https://github.com/alexdesousa/icon/actions/workflows/checks.yml/badge.svg) [![Hex pm](http://img.shields.io/hexpm/v/icon.svg?style=flat)](https://hex.pm/packages/icon) [![hex.pm downloads](https://img.shields.io/hexpm/dt/icon.svg?style=flat)](https://hex.pm/packages/icon) [![Coverage Status](https://coveralls.io/repos/github/alexdesousa/icon/badge.svg?branch=master)](https://coveralls.io/github/alexdesousa/icon?branch=master)

> _"Knowledge is of no value unless you put it into practice."_ - Anton Chekhov

`Icon` is a library for interacting with the interoperable decentralized
aggregator network [ICON 2.0](https://icon.foundation).

This document gives a general overview of the current state of the project and
its future:

- [Motivation](#motivation)
- [Overview](#overview)
  + [Example: Transferring ICX](#example-transferring-icx)
  + [Example: SCORE Transaction Call](#example-score-transaction-call)
- [Wallets and Node Connections](#wallets-and-node-connections)
- [Realtime Updates](#realtime-updates)
  + [Example: Subscribing to Blocks](#example-subscribing-to-blocks)
  + [Example: Subscribing to Events](#example-subscribing-to-events)
- [TODO](#todo)
- [Installation](#installation)
  + [Containerized Testing](#containerized-testing)
  + [Installing Elixir](#installing-elixir)

## Motivation

The motivation for building a SDK in Elixir is to be able to use:

- The battle-tested Erlang runtime and Erlang supervisors,
- The amazing Elixir real-time libraries,
- Documentation as first class citizen,
- And my favorite language (strong bias here)

while writing client applications for ICON 2.0.

This library is a work in progress, so if you want to use a production ready SDK
you're better off using one of the official ones:

- [Java SDK](https://github.com/icon-project/icon-sdk-java)
- [Javascript SDK](https://github.com/icon-project/icon-sdk-js)
- [Python SDK](https://github.com/icon-project/icon-sdk-python)
- [Swift (iOS development)](https://github.com/icon-project/ICONKit)

## Overview

Every single JSON API v3 method is already implemented (no BTP nor IISS
extensions yet).

For most applications, we'll need just two modules:

- `Icon` - where we'll find the JSON RPC API.
- `Icon.RPC.Identity` - where we'll find the wallet and node connection
  initialization.

Though this SDK was heavily inspired by the
[ICON Python SDK](https://github.com/icon-project/icon-sdk-python), it difers
slightly from it:

- (Mostly) automatic type translation from ICON 2.0 representation to Elixir's
  for both inputs and outputs.
- Automatic `stepLimit` estimation via `debug_estimateStep` method (it can be
  overriden).
- `icx_sendTransaction` method become several function calls depending of the
  objective of the transaction:
  + `Icon.transfer/4` for transferring ICX from an EOA address to another
    address (EOA or SCORE).
  + `Icon.send_message/4` for sending messages from an EOA address to another.
  + `Icon.transaction_call/5` for calling SCORE functions.
  + `Icon.install_score/3` for installing SCOREs in the ICON blockchain.
  + `Icon.update_score/4` for updating SCOREs in the ICON blockchain.
  + `Icon.deposit_shared_fee/4` for withdrawing shared fees from SCOREs.
  + `Icon.withdraw_shared_fee/4` for depositing shared fees into SCOREs.
- Any of the previous function calls can use `icx_sendTransactionAndWait` just
  by setting a `timeout` in the options.

### Example: Transferring ICX

The following example shows how to send 1 ICX from our wallet to another:

```elixir
iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
iex> Icon.transfer(identity, "hx2e243ad926ac48d15156756fce28314357d49d83", 1_000_000_000_000_000_000)
{:ok, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"}
```

> *Note*: In this library, ICX is always expressed in _loop_ as units, where
> 1 ICX = 10¹⁸ loop.

### Example: SCORE Transaction Call

The following example calls a fuction in a SCORE in the Sejong testnet:

```elixir
iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...", network_id: :sejong)
iex> params = %{
...>   _strategy: "cx31f04b8d24628463db5ac9f04a7d33ba32e44680",
...>   _start: 1,
...>   _end: 51
...> }
iex> schema = %{
...>   _strategy: {:score_address, required: true},
...>   _start: :integer,
...>   _end: :integer
...> }
iex> Icon.transaction_call(
...>   identity,
...>   "cx9cd4af2976c8ffabf3146d1d166e83a6dd689d50",
...>   "claim",
...>   params,
...>   call_schema: schema
...> )
{:ok, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"}
```

> *Note*: The previous example was taken from
> [Optimus Finance](https://optimus.finance) SCORE for claiming rewards from
> strategies.

### Wallets and Node Connections

Every request to the API requires an `Icon.RPC.Identity.t()` instance. There
are two types of identities:

- Without wallet (for most readonly remote calls):

  ```elixir
  iex> Icon.RPC.Identity.new()
  #Identity<[
    node: "https://ctz.solidwallet.io",
    network_id: "0x1 (Mainnet)",
    debug: false
  ]>
  ```

- With wallet (for transactions and SCORE readonly calls):

  ```elixir
  iex> Icon.RPC.Identity.new(private_key: "8ad9...")
    #Identity<[
    node: "https://ctz.solidwallet.io",
    network_id: "0x1 (Mainnet)",
    debug: false,
    address: "hxfd7e4560ba363f5aabd32caac7317feeee70ea57",
    private_key: "8ad9..."
  ]>
  ```

> **Note**: the private key is always redacted when inspecting the
> `Icon.RPC.Identity.t()` struct. The idea is to be able to safely log an
> identity without compromising the security of the underlying wallet by
> revealing sensitive data.

For more customization options, checkout the module `Icon.RPC.Identity`
documentation.

## Realtime Updates

It is possible to subscribe to the ICON 2.0 websocket to get either or both
block and event log updates in realtime. It leverages
[Yggdrasil](https://github.com/gmtprime/yggdrasil) (built with `Phoenix.PubSub`)
for handling incoming messages.

The channel has two main fields:

- `adapter` - Which for this specific adapter, it should be set to `:icon`.
- `name` - Where we'll find information of the websocket connection. For this
  adapter, it is a map with the following keys:
  + `source` - Whether `:block` or `:event` (required).
  + `identity` - `Icon.RPC.Identity` instance pointed to the right network. It
    defaults to Mainnet if no identity is provided.
  + `from_height` - Block height from which we should start receiving messages.
    It defaults to `:latest`.
  + `data` - It varies depending on the `source` chosen (see
    `Yggdrasil.Adapter.Icon` for more information).

> **Important**: We need to be careful when using `from_height` in the channel
> because `Yggdrasil` will restart the synchronization process from the
> chosen height if the process crashes.

### Example: Subscribing to Blocks

We can subscribe to blocks using `Yggdrasil.subscribe/1`:

```elixir
iex> channel = [name: %{source: :block}, adapter: :icon]
iex> Yggdrasil.subscribe(channel)
:ok
```

and our subscriber process will get notifications in its mailbox every time a
block is produced. If we use `flush/0` to flush the messages from the IEX
mailbox, we'll get something like the following:

```elixir
iex> flush()
{:Y_CONNECTED, %Yggdrasil.Channel{adapter: :icon, ...}}
{:Y_EVENT, %Yggdrasil.Channel{adapter: :icon, ...}, %Icon.Schema.Types.Block.Tick{height: 42, hash: "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"}}
...
```

When we're done, we can unsubscribe using the following:

```elixir
iex> Yggdrasil.unsubscribe(channel)
:ok
```

> **Note**: Also we can subscribe to one or more events using the block
> subscription. We'll get both `Icon.Schema.Types.Block.Tick.t()` and
> `Icon.Schema.Types.EventLog.t()`. For this, we need to provide a list of
> events we want to subscribe to in the `data` field:
>
> ```elixir
> iex> channel = [
> ...>   adapter: :icon,
> ...>   name: %{
> ...>     source: :block,
> ...>     data: [
> ...>       %{
> ...>         event: "Transfer(Address,Address,int)"
> ...>       }
> ...>     ]
> ...>   }
> ...> ]
> iex> Yggdrasil.subscribe(channel)
> :ok
> ```
>
> For more info about the notifications, check the next section.

### Example: Subscribing to Events

Following the previous example, if we're only interested in a single event, we
can just subscribe to it e.g. the following shows a subscription to the event
`Transfer(Address,Address,int)` for the SCORE address
`cx31f04b8d24628463db5ac9f04a7d33ba32e44680`:

```elixir
iex> channel = [
...>   adapter: :icon,
...>   name: %{
...>     source: :event,
...>     data: %{
...>       addr: "cx31f04b8d24628463db5ac9f04a7d33ba32e44680",
...>       event: "Transfer(Address,Address,int)"
...>     }
...>   }
...> ]
iex> Yggdrasil.subscribe(channel)
:ok
```

Our subscriber process will get notifications in its mailbox every time an
event matches our query. If we use `flush/0` to flush the messages from the IEX
mailbox, we'll get something like the following:

```elixir
iex> flush()
{:Y_CONNECTED, %Yggdrasil.Channel{adapter: :icon, ...}}
{:Y_EVENT, %Yggdrasil.Channel{adapter: :icon, ...}, %Icon.Schema.Types.Block.Tick{height: 42, hash: "0xc71303ef8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"}}
{:Y_EVENT, %Yggdrasil.Channel{adapter: :icon, ...}, %Icon.Schema.Types.EventLog{header: "Transfer(Address,Address,int)", indexed: ["hxfd7e4560ba363f5aabd32caac7317feeee70ea57", "hxbe7e4560ba363f5aabd32caac7317feeee70ea57"], ...}}
...
```

Also, when we're done, we can unsubscribe using the following:

```elixir
iex> Yggdrasil.unsubscribe(channel)
:ok
```

## TODO

The following is a list of functionalities this SDK aims to support in the
future:

- [x] [Goloop API](https://www.icondev.io/icon-node/goloop/json-rpc/jsonrpc_v3)
- [ ] [BTP Extension](https://www.icondev.io/icon-node/goloop/json-rpc/btp_extension)
- [x] [Yggdrasil](https://github.com/gmtprime/yggdrasil) support for BTP websockets.
- [ ] [IISS Extension](https://www.icondev.io/icon-node/goloop/json-rpc/iiss_extension)

## Installation

The package is available in [Hex](https://hex.pm/packages/icon) and can be
installed by adding `icon` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:icon, "~> 0.2"}
  ]
end
```

### Containerized Testing

If you just want to try it out, you can run this project inside a docker
container with Elixir:

```bash
$ git clone https://github.com/alexdesousa/icon.git
$ cd icon/
$ docker run -it --rm -v $PWD:/data -w /data elixir:latest iex -S mix
```

> **Note**: For certain `docker` setups, you'll need to add `sudo` at the beginning
> of the command.

While in the IEx shell, you can check the documentation for any module and
function just by typing `h` in front of it e.g:

```elixir
iex> h Icon.transfer
# ... shows documentation for `Icon.transfer/3` and `Icon.transfer/4` ...
```

### Installing Elixir

If you want to install Elixir, I recommend using
[asdf](http://asdf-vm.com/guide/getting-started.html#_1-install-dependencies)
to get it (you'll need both Erlang and Elixir to be able to run this library).

In Ubuntu/Linux Mint, you'll need the following dependencies to be able to
build Erlang:

```bash
$ sudo apt install \
    build-essential \
    autoconf \
    m4 \
    libncurses5-dev \
    libwxgtk3.0-gtk3-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libpng-dev \
    libssh-dev \
    unixodbc-dev \
    xsltproc \
    fop
```

Once they're installed you can add Erlang and build it:

```bash
$ asdf plugin-add erlang
$ asdf install erlang 24.2 # This step takes some time.
$ asdf global erlang 24.2
```

Finally, you can install Elixir running the following:

```bash
$ asdf plugin-add elixir
$ asdf install elixir 1.13.2-otp-24
$ asdf global elixir 1.13.2-otp-24
```

## Author

Alex de Sousa (a.k.a. Etadelius).

## License

`Icon` is released under the MIT License. See the LICENSE file for further
details.
