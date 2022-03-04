defmodule Icon.WebSocket.Router do
  @moduledoc false
  use Plug.Router

  import ExUnit.Assertions

  alias Plug.Adapters.Cowboy

  defstruct [:pid, :ref, :host]
  @type t :: %__MODULE__{}

  plug(:match)
  plug(:dispatch)

  match _ do
    send_resp(conn, 200, "Hello from the websocket server")
  end

  defmodule Handler do
    @behaviour :cowboy_handler

    @impl :cowboy_handler
    def init(req, [%{bypass: bypass} = state]) do
      {:ok, req_body, req} = :cowboy_req.read_body(req)

      req_headers =
        req
        |> :cowboy_req.headers()
        |> Enum.to_list()

      request =
        Finch.build(
          :post,
          "http://localhost:#{bypass.port}/api/v3",
          req_headers,
          "#{req_body}"
        )

      {:ok,
       %Finch.Response{
         status: status,
         body: resp_body,
         headers: resp_headers
       }} = Finch.request(request, Icon.Finch)

      req =
        :cowboy_req.reply(
          _status = status,
          _headers = Map.new(resp_headers),
          _body = resp_body,
          _req = req
        )

      {:ok, req, state}
    end
  end

  @spec start(keyword()) :: t() | no_return()
  @spec start(nil | pid(), keyword()) :: t() | no_return()
  def start(pid \\ nil, options)

  def start(nil, options) do
    start(self(), options)
  end

  def start(pid, options) do
    ref = make_ref()
    port = get_port()
    host = "http://localhost:#{port}"
    path = "/api/v3/icon_dex/#{options[:channel]}"

    state = %{
      host: host,
      path: path,
      bypass: options[:bypass],
      caller: pid
    }

    opts = [
      dispatch: [
        {:_,
         [
           {path, Icon.WebSocket.Server, [state]},
           {:_, Handler, [state]}
         ]}
      ],
      port: port,
      ref: ref
    ]

    case Cowboy.http(__MODULE__, [], opts) do
      {:ok, _} ->
        %__MODULE__{ref: ref, host: host}

      {:error, :eaddrinuse} ->
        start(pid, options)
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
    send(pid, {:send, {:text, encoded}, self()})
    assert_receive :ok, 500, "cannot initialize the websocket connection"
    router
  end

  def trigger_message(%__MODULE__{pid: pid} = router, message) do
    encoded = Jason.encode!(message)
    send(pid, {:send, {:text, encoded}, self()})
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
