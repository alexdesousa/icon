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
  app_env :url, :icon, :url, default: "https://ctz.solidwallet.io"
end
