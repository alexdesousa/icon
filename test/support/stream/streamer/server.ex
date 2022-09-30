defmodule Icon.Stream.Streamer.Server do
  @moduledoc false
  @behaviour :cowboy_websocket

  @doc false
  defstruct [:ref, :caller, :type, :req]

  @impl :cowboy_websocket
  def init(req, [%{ref: ref, caller: caller, type: type}]) do
    state = %__MODULE__{
      ref: ref,
      caller: caller,
      type: type,
      req: req
    }

    {:cowboy_websocket, req, [state]}
  end

  @impl :cowboy_websocket
  def terminate(_reason, _req, _state), do: :ok

  @impl :cowboy_websocket
  def websocket_init([%{caller: caller} = state]) do
    send(caller, {:"$websocket", self()})
    {:ok, state}
  end

  @impl :cowboy_websocket
  def websocket_info({:send, frame}, %{caller: caller} = state) do
    send(caller, {:"$websocket", :sent, frame})
    {:reply, frame, state}
  end

  @impl :cowboy_websocket
  def websocket_handle(_frame, state) do
    {:ok, state}
  end
end
