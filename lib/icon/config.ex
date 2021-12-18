defmodule Icon.Config do
  @moduledoc """
  This module defines the ICON 2.0 SDK config.
  """
  use Skogsra

  @envdoc """
  API URL.

  ```elixir
  iex> Icon.Config.url()
  {:ok, "https://ctz.solidwallet.io"}
  iex> Icon.Config.url!()
  "https://ctz.solidwallet.io"
  ```
  """
  app_env :url, :icon, :url,
    default: "https://ctz.solidwallet.io",
    required: true

  # This application variable allows to inject a module to override the default
  # URL given by `Icon.Config.url!()`. This is only used in the tests.
  @envdoc false
  app_env :url_builder, :icon, :url_builder,
    binding_order: [:config],
    type: :module,
    default: Icon.RPC.Request,
    required: true
end
