defmodule Yggdrasil.Adapter.Icon do
  @moduledoc """
  This module defines an `Yggdrasil` adapter for ICON 2.0.

  ## Overview

  With this adapter we can subscribe to the ICON 2.0 websocket to get either or
  both block and event log updates in real time. It leverages `Yggdrasil` (built
  over `Phoenix.PubSub`) for handling incoming messages.

  The channel has two main fields:

  - `adapter` - Which for this specific adapter, it should be set to `:icon`.
  - `name` - Where we'll find information of the websocket connection. For this
    adapter, it is a map with the following keys:
    + `source` - Whether `:block` or `:event` (required).
    + `identity` - `Icon.RPC.Identity` instance pointed to the right network. It
      defaults to Mainnet if no identity is provided.
    + `from_height` - Block height from which we should start receiving messages.
      It defaults to `:latest`.
    + `data` - It varies depending on the `source` chosen (see next sections for
      more information).

  > **Important**: We need to be careful when using `from_height` in the channel
  > because `Yggdrasil` will restart the synchronization process from the
  > chosen height if the process crashes.

  In general, we can subscribe any process using the function
  `Yggdrasil.subscribe/1` and unsubscribe using `Yggdrasil.unsubscribe/1` e.g.
  for subscribing to every block tick we would do the following:

  ```elixir
  iex> channel = [name: %{source: :block}, adapter: :icon]
  iex> Yggdrasil.subscribe(channel)
  :ok
  ```

  and we'll find our messages in the mailbox of our process:

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

  ## Subscribing to Blocks

  When subscribing to blocks, we can subscribe to:
  - Only block ticks.
  - Or block ticks and event logs.

  The previous section showed how to subscribe to block ticks. However, if we
  want to subscribe to specific events as well, we can list them the `data` e.g.
  let's say we want to subscribe to the event:

  - `Transfer(Address,Address,int)`
  - For the contract `cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32`
  - When the first address is `hxbe258ceb872e08851f1f59694dac2558708ece11`

  then we would do the following:

  ```elixir
  iex> channel = [
  ...>   adapter: :icon,
  ...>   name: %{
  ...>     source: :block,
  ...>     data: [
  ...>       %{
  ...>         event: "Transfer(Address,Address,int)",
  ...>         addr: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
  ...>         indexed: [
  ...>           "hxbe258ceb872e08851f1f59694dac2558708ece11",
  ...>           nil
  ...>         ],
  ...>         data: [
  ...>           nil
  ...>         ]
  ...>       }
  ...>     ]
  ...>   }
  ...> ]
  iex> Yggdrasil.subscribe(channel)
  :ok
  ```

  then we will start receiving both block ticks and event logs related to that
  event when they occur:

  ```elixir
  iex> flush()
  {:Y_CONNECTED, %Yggdrasil.Channel{...}}
  {:Y_EVENT, %Yggdrasil.Channel{...}, %Icon.Schema.Types.Block.Tick{height: 42, ...}}
  {:Y_EVENT, %Yggdrasil.Channel{...}, %Icon.Schema.Types.Block.Tick{height: 43, ...}}
  {:Y_EVENT, %Yggdrasil.Channel{...}, %Icon.Schema.Types.Block.Tick{height: 44, ...}}
  {:Y_EVENT, %Yggdrasil.Channel{...}, %Icon.Schema.Types.EventLog{header: "Transfer(Address,Address,int)", ...}}
  ...
  ```

  ## Subscribing to Events

  We can also subscribe directly to events if we don't care much about the
  current block. In this case the `data` would not be a list of events, but a
  single event e.g. if we apply the same example we've seen in the previous
  section, this is how it would look like:

  ```elixir
  iex> channel = [
  ...>   adapter: :icon,
  ...>   name: %{
  ...>     source: :event,
  ...>     data: %{
  ...>       event: "Transfer(Address,Address,int)",
  ...>       addr: "cxb0776ee37f5b45bfaea8cff1d8232fbb6122ec32",
  ...>       indexed: [
  ...>         "hxbe258ceb872e08851f1f59694dac2558708ece11",
  ...>         nil
  ...>       ],
  ...>       data: [
  ...>         nil
  ...>       ]
  ...>     }
  ...>   }
  ...> ]
  iex> Yggdrasil.subscribe(channel)
  :ok
  ```

  then we will start receiving the event logs related to that event when they
  occur:

  ```elixir
  iex> flush()
  {:Y_CONNECTED, %Yggdrasil.Channel{...}}
  {:Y_EVENT, %Yggdrasil.Channel{...}, %Icon.Schema.Types.EventLog{header: "Transfer(Address,Address,int)", ...}}
  ...
  ```

  ## Further Reading

  For more informacion, check out the following modules:

  - Publisher adapter: `Yggdrasil.Publisher.Adapter.Icon`
  - Subscriber adapter: `Yggdrasil.Subscriber.Adapter.Icon`
  """
  use Yggdrasil.Adapter, name: :icon
end
