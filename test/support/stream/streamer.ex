defmodule Icon.Stream.Streamer do
  @moduledoc false
  use Plug.Router

  alias Icon.RPC.Identity
  alias Plug.Adapters.Cowboy

  @doc """
  A streamer.
  """
  defstruct [:ref, :identity]

  @typedoc false
  @type t :: %__MODULE__{
    ref: server_reference :: reference(),
    identity: identity :: Identity.t()
  }

  plug(:match)
  plug(:dispatch)

  match _ do
    send_resp(conn, 200, "This is a mock server for streaming websocket messages")
  end

  @doc """
  Starts a test websocket server.
  """
  @spec start() :: t()
  @spec start(nil | pid()) :: t()
  def start(pid \\ nil)

  def start(nil) do
    start(self())
  end

  def start(caller) do
    ref = make_ref()
    port = get_port()
    identity = Identity.new(node: "http://localhost:#{port}")

    state = %{
      ref: ref,
      caller: caller,
      type: nil
    }

    options = [
      dispatch: [
        {:_,
          [
            {"/api/v3/icon_dex/block", Icon.Stream.Streamer.Server, [%{state | type: :block}]},
            {"/api/v3/icon_dex/event", Icon.Stream.Streamer.Server, [%{state | type: :event}]}
          ]
        }
      ],
      port: port,
      ref: ref
    ]

    case Cowboy.http(__MODULE__, [],  options) do
      {:ok, _} ->
        %__MODULE__{ref: ref, identity: identity}

      {:error, :eaddrinuse} ->
        start(caller)
    end
  end

  @doc """
  Stops websocket server.
  """
  @spec stop(t()) :: :ok
  def stop(%__MODULE__{ref: ref}) do
    Cowboy.shutdown(ref)
  end

  @doc """
  Sends a map to the mock server.
  """
  @spec send_message(pid(), map()) :: :ok
  def send_message(server, message) do
    frame = Jason.encode!(message)
    send(server, {:send, {:text, frame}})
    :ok
  end

  ##################
  # Helper functions

  @spec get_port() :: :inet.port()
  defp get_port do
    unless Process.whereis(__MODULE__) do
      Agent.start(fn -> Enum.random(50_000..63_000) end, name: __MODULE__)
    end

    Agent.get_and_update(__MODULE__, fn port -> {port, port + 1} end)
  end
end
