defmodule Icon.WebSocket.Server do
  @moduledoc false
  @behaviour :cowboy_websocket

  defstruct [:host, :caller, :path, :req]

  @impl :cowboy_websocket
  def init(req, [params]) do
    state = %{struct(__MODULE__, params) | req: req}
    {:cowboy_websocket, req, [state]}
  end

  @impl :cowboy_websocket
  def terminate(_reason, _req, _state), do: :ok

  @impl :cowboy_websocket
  def websocket_init([state]) do
    send(state.caller, {:websocket, self()})
    {:ok, state}
  end

  @impl :cowboy_websocket
  def websocket_info({:send, frame}, state) do
    send(state.caller, :ok)
    {:reply, frame, state}
  end

  @impl :cowboy_websocket
  def websocket_handle(_frame, state) do
    {:ok, state}
  end
end
