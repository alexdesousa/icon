defmodule Yggdrasil.Publisher.Adapter.Icon do
  @moduledoc """
  This modules defines a publisher ICON 2.0 adapter. However, it's not possible
  to publish messages in ICON 2.0 via `Yggdrasil`. Attempting to publish a
  message will always return an error.
  """
  use GenServer
  use Yggdrasil.Publisher.Adapter

  alias Icon.Schema.Error
  alias Yggdrasil.Channel

  @doc """
  Starts a ICON 2.0 publisher with a `namespace` for the configuration.
  Additionally, you can add `GenServer` `options`.
  """
  @spec start_link(term()) :: GenServer.on_start()
  @spec start_link(term(), GenServer.options()) :: GenServer.on_start()
  @impl Yggdrasil.Publisher.Adapter
  def start_link(namespace, options \\ []) do
    GenServer.start_link(__MODULE__, namespace, options)
  end

  @doc """
  Stops an ICON 2.0 `publisher`. Optionally, receives a stop `reason` (defaults
  to `:normal`) and a `timeout` in milliseconds (defaults to `:infinity`).
  """
  @spec stop(GenServer.name()) :: :ok
  @spec stop(GenServer.name(), term()) :: :ok
  @spec stop(GenServer.name(), term(), non_neg_integer() | :infinity) :: :ok
  defdelegate stop(publisher, reason \\ :normal, timeout \\ :infinity),
    to: GenServer

  @doc """
  It returns error when trying to publish a message in ICON 2.0.
  """
  @spec publish(GenServer.name(), Channel.t(), term()) ::
          :ok | {:error, Error.t()}
  @spec publish(GenServer.name(), Channel.t(), term(), Keyword.t()) ::
          :ok | {:error, Error.t()}
  @impl Yggdrasil.Publisher.Adapter
  def publish(publisher, _channel, _message, _options \\ []) do
    GenServer.call(publisher, :publish)
  end

  ####################
  # GenServer callback

  @impl GenServer
  def init(_namespace) do
    {:ok, nil}
  end

  @impl GenServer
  def handle_call(:publish, _from, nil) do
    reason =
      Error.new(
        code: -32_600,
        message: "Cannot publish messages in the ICON 2.0 blockchain"
      )

    {:reply, {:error, reason}, nil}
  end
end
