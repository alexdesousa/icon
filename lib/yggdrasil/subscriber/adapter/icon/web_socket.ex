defmodule Yggdrasil.Subscriber.Adapter.Icon.WebSocket do
  @moduledoc """
  This module defines a general ICON 2.0 WebSocket.
  """
  use WebSockex
  alias __MODULE__, as: State
  alias Yggdrasil.Subscriber.Adapter.Icon

  @doc false
  defstruct url: nil,
            subscriber: nil,
            decoder: nil

  @typedoc false
  @type t :: %State{
          url: url :: binary(),
          subscriber: pid(),
          decoder: (binary() -> :ok)
        }

  ############
  # Public API

  @doc """
  Starts a websocket connection with an `url` and some `options`.

  Non `WebSockex` options:

  - `decoder`: a frame decoder function.
  """
  @spec start_link(binary(), keyword()) ::
          {:ok, pid()}
          | {:error, term()}
  def start_link(url, options) do
    caller = self()

    {decoder, options} =
      Keyword.pop(options, :decoder, fn frame ->
        Icon.send_frame(caller, frame)
      end)

    state = %__MODULE__{
      url: url,
      subscriber: caller,
      decoder: decoder
    }

    WebSockex.start_link(url, __MODULE__, state, options)
  end

  @doc """
  Stops `websocket`.
  """
  @spec stop(WebSockex.client()) :: :ok
  def stop(websocket) do
    if Process.alive?(websocket),
      do: WebSockex.cast(websocket, :stop),
      else: :ok
  end

  @doc """
  Initializes `websocket` connection with a `message`.
  """
  @spec initialize(WebSockex.client(), term()) :: :ok
  def initialize(websocket, message) do
    WebSockex.cast(websocket, {:init, message})
  end

  #####################
  # WebSockex callbacks

  @impl WebSockex
  def handle_connect(%WebSockex.Conn{}, %State{subscriber: pid} = state) do
    Icon.send_connected(pid)
    {:ok, state}
  end

  @impl WebSockex
  def handle_cast({:init, message}, %State{} = state) do
    {:reply, message, state}
  end

  def handle_cast(:stop, %State{} = state) do
    {:close, state}
  end

  @impl WebSockex
  def handle_frame(
        {:text, frame},
        %State{decoder: decoder} = state
      ) do
    spawn(fn -> decoder.(frame) end)

    {:ok, state}
  end

  @impl WebSockex
  def handle_disconnect(_status, %State{} = state) do
    {:ok, state}
  end

  @impl WebSockex
  def terminate(reason, %State{subscriber: pid} = _state) do
    Icon.send_disconnected(pid, reason)
    :ok
  end
end
