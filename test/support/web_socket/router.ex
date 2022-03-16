defmodule Icon.WebSocket.Router do
  @moduledoc false
  use Plug.Router

  import ExUnit.Assertions

  alias Plug.Adapters.Cowboy

  defstruct [:pid, :ref, :host, :url]
  @type t :: %__MODULE__{}

  plug(:match)
  plug(:dispatch)

  match _ do
    send_resp(conn, 200, "Hello from the websocket server")
  end

  @spec start() :: t() | no_return()
  @spec start(nil | pid()) :: t() | no_return()
  def start(pid \\ nil)

  def start(pid) do
    pid = if is_nil(pid), do: self(), else: pid

    ref = make_ref()
    port = get_port()
    host = "http://localhost:#{port}"
    path = "/api/v3/icon_dex/block"
    url = "#{host}#{path}"

    state = %{
      host: host,
      path: path,
      url: url,
      caller: pid
    }

    opts = [
      dispatch: [
        {:_,
         [
           {path, Icon.WebSocket.Server, [state]}
         ]}
      ],
      port: port,
      ref: ref
    ]

    case Cowboy.http(__MODULE__, [], opts) do
      {:ok, _} ->
        %__MODULE__{ref: ref, host: host, url: url}

      {:error, :eaddrinuse} ->
        start(pid)
    end
  end

  @spec stop(t()) :: :ok
  def stop(%__MODULE__{ref: ref}) do
    Cowboy.shutdown(ref)
  end

  @spec trigger_message(t(), map()) :: t()
  def trigger_message(router, message)

  def trigger_message(%__MODULE__{pid: nil} = router, %{"code" => _} = message) do
    assert_receive {:websocket, pid}, 500, "no websocket process found"
    trigger_message(%{router | pid: pid}, message)
  end

  def trigger_message(%__MODULE__{pid: nil} = router, message) do
    assert_receive {:websocket, pid}, 500, "no websocket process found"

    %{router | pid: pid}
    |> trigger_message(%{"code" => 0})
    |> trigger_message(message)
  end

  def trigger_message(%__MODULE__{pid: pid} = router, %{"code" => _} = message) do
    encoded = Jason.encode!(message)
    send(pid, {:send, {:text, encoded}})
    assert_receive :ok, 500, "cannot initialize the websocket connection"
    router
  end

  def trigger_message(%__MODULE__{pid: pid} = router, message) do
    encoded = Jason.encode!(message)
    send(pid, {:send, {:text, encoded}})
    assert_receive :ok, 500, "cannot send frame"
    router
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
