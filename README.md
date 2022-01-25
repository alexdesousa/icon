# Icon

![Build status](https://github.com/alexdesousa/icon/actions/workflows/checks.yml/badge.svg) [![Hex pm](http://img.shields.io/hexpm/v/icon.svg?style=flat)](https://hex.pm/packages/icon) [![hex.pm downloads](https://img.shields.io/hexpm/dt/icon.svg?style=flat)](https://hex.pm/packages/icon) [![Coverage Status](https://coveralls.io/repos/github/alexdesousa/icon/badge.svg?branch=master)](https://coveralls.io/github/alexdesousa/icon?branch=master)

> _"Knowledge is of no value unless you put it into practice."_ - Anton Chekhov

`Icon` is a library for interacting with the interoperable decentralized
aggregator network [ICON 2.0](https://icon.foundation).

The motivation for building a SDK in Elixir is to be able to use:

- The battle tested Erlang runtime and Erlang supervisors,
- The Elixir amazing libraries,
- Documentation as first class citizen,
- My favorite language (strong bias here)

while writing client applications for ICON 2.0.

This library is a work in progress, so if you want to use a production ready SDK
you're better off using one of the official ones:

- [Java SDK](https://github.com/icon-project/icon-sdk-java)
- [Javascript SDK](https://github.com/icon-project/icon-sdk-js)
- [Python SDK](https://github.com/icon-project/icon-sdk-python)
- [Swift (iOS development)](https://github.com/icon-project/ICONKit)

## Overview

Every single JSON API v3 method is implemented already (no BTP nor IISS
extensions yet).

For most applications, we'll need just two modules:

- `Icon` - where we'll find the JSON RPC API.
- `Icon.RPC.Identity` - where we'll find the wallet and network information.

The following example shows how to send 1 ICX from our wallet to another:

```elixir
iex> identity = Icon.RPC.Identity.new(private_key: "8ad9...")
iex> Icon.transfer(identity, "hx2e243ad926ac48d15156756fce28314357d49d83", 1_000_000_000_000_000_000)
{:ok, "0xd579ce6162019928d874da9bd1dbf7cced2359a5614e8aa0bf7cf75f3770504b"}
```

> *Note*: In this library, ICX is always expressed in _loop_ as units, where
> 1 ICX = 10¹⁸ loop.

And the following example calls a fuction in a SCORE in the Sejong testnet:

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

## Identities

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

## TODO

The following is a list of functionalities this SDK aims to support in the
future:

- [x] [Goloop API](https://www.icondev.io/icon-node/goloop/json-rpc/jsonrpc_v3)
- [ ] Automatic SCORE API generation from `Icon.get_score_api/2` function.
- [ ] [BTP Extension](https://www.icondev.io/icon-node/goloop/json-rpc/btp_extension)
- [ ] [Yggdrasil](https://github.com/gmtprime/yggdrasil) support for BTP websockets.
- [ ] [IISS Extension](https://www.icondev.io/icon-node/goloop/json-rpc/iiss_extension)

## Installation

The package is available in [Hex](https://hex.pm/packages/icon) and can be
installed by adding `icon` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:icon, "~> 0.1.0"}
  ]
end
```

Or if you just want to try it out, you can run this project inside a docker
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
