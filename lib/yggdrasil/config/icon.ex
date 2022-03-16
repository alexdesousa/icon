defmodule Yggdrasil.Config.Icon do
  @moduledoc """
  This module defines configuration variables for ICON 2.0 WebSocket connection.
  """
  use Skogsra

  @envdoc """
  WebSocket max retries for the backoff algorithm. Defaults to `3`.

  The backoff algorithm is exponential:

  ```
  backoff_time = retries² * random(1, slot) * 1_000ms
  ```
  where:

  - `retries` is less or equal to `max_retries!/0`,
  - and `slot` is given by `slot_size!/0`.

  ```elixir
  iex> Yggdrasil.Config.Icon.max_retries!()
  3
  ```
  """
  app_env :max_retries, :yggdrasil_icon, :max_retries,
    required: true,
    default: 3

  @envdoc """
  WebSocket slot size for the backoff algorithm. Defaults to `10`.

  The backoff algorithm is exponential:

  ```
  backoff_time = retries² * random(1, slot) * 1_000ms
  ```
  where:

  - `retries` is less or equal to `max_retries!/0`,
  - and `slot` is given by `slot_size!/0`.

  ```elixir
  iex> Yggdrasil.Config.Icon.slot_size!()
  10
  ```
  """
  app_env :slot_size, :yggdrasil_icon, :slot_size,
    required: true,
    default: 10

  # For testing purposes.
  @envdoc false
  app_env :websocket_module, :yggdrasil_icon, :websocket_module,
    binding_order: [:config],
    type: :module,
    default: Yggdrasil.Subscriber.Adapter.Icon.WebSocket
end
