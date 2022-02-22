defmodule Icon.WebSocket.Router do
  @moduledoc false
  use Plug.Router

  alias Plug.Adapters.Cowboy

  defstruct [:pid, :ref, :host]
  @type t :: %__MODULE__{}

  plug(:match)
  plug(:dispatch)

  match _ do
    send_resp(conn, 200, "Hello from the websocket server")
  end

  @spec start(binary()) :: t() | no_return()
  @spec start(nil | pid(), binary()) :: t() | no_return()
  def start(pid \\ nil, path)

  def start(nil, path) do
    start(self(), path)
  end

  def start(pid, path) do
    ref = make_ref()
    port = get_port()
    host = "http://localhost:#{port}"

    state = %{
      host: host,
      path: path,
      caller: pid
    }

    opts = [
      dispatch: [{:_, [{path, Icon.WebSocket.Server, [state]}]}],
      port: port,
      ref: ref
    ]

    case Cowboy.http(__MODULE__, [], opts) do
      {:ok, _} ->
        %__MODULE__{ref: ref, host: host}

      {:error, :eaddrinuse} ->
        start(pid, path)
    end
  end

  @spec stop(t()) :: :ok
  def stop(%__MODULE__{ref: ref}) do
    Cowboy.shutdown(ref)
  end

  @spec trigger_frame(t(), :cowboy_ws.frame()) :: t()
  def trigger_frame(%__MODULE__{pid: nil} = websocket, frame) do
    receive do
      {:websocket, pid} ->
        trigger_frame(%{websocket | pid: pid}, frame)
    after
      500 ->
        raise "No WebSocket process found"
    end
  end

  def trigger_frame(%__MODULE__{pid: pid} = websocket, frame) do
    send(pid, {:send, frame})
    websocket
  end

  #########
  # Helpers

  @spec get_port() :: :inet.port()
  defp get_port do
    unless Process.whereis(__MODULE__) do
      Agent.start(fn -> Enum.random(50_000..63_000) end, name: __MODULE__)
    end

    Agent.get_and_update(__MODULE__, fn port -> {port, port + 1} end)
  end
end
