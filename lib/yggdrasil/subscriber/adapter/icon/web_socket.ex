defmodule Yggdrasil.Subscriber.Adapter.Icon.WebSocket do
  @moduledoc """
  This module defines a general ICON 2.0 WebSocket.
  """
  use WebSockex
  alias __MODULE__, as: State
  alias Yggdrasil.Subscriber.Adapter.Icon

  @doc false
  defstruct url: nil,
            subscriber: nil

  @typedoc false
  @type t :: %State{
          url: url :: binary(),
          subscriber: pid()
        }

  ############
  # Public API

  @doc """
  Starts a websocket connection with an `url` and some `options`.
  """
  @spec start_link(binary(), WebSockex.options()) ::
          {:ok, pid()}
          | {:error, term()}
  def start_link(url, options) do
    state = %__MODULE__{url: url, subscriber: self()}

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
  def handle_frame(frame, %State{subscriber: pid} = state) do
    Icon.send_frame(pid, frame)
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
