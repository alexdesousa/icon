defmodule Icon.URLBuilder do
  @moduledoc false
  use GenServer

  alias Icon.RPC.Request

  @spec start_link() :: GenServer.on_start()
  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @spec build_url() :: binary()
  def build_url do
    case GenServer.call(__MODULE__, :get) do
      {:ok, %Bypass{port: port}} ->
        "http://localhost:#{port}/api/v3"

      :miss ->
        Request.build_url()
    end
  end

  @spec put_bypass(Bypass.t()) :: :ok
  def put_bypass(%Bypass{} = bypass) do
    GenServer.call(__MODULE__, {:put, bypass})
  end

  ###########
  # Callbacks

  @impl GenServer
  def init(_) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call(message, from, state)

  def handle_call({:put, %Bypass{} = bypass}, {pid, _}, state) do
    {:reply, :ok, Map.put(state, pid, bypass)}
  end

  def handle_call(:get, {pid, _}, state) do
    case state[pid] do
      %Bypass{} = bypass ->
        {:reply, {:ok, bypass}, state}

      _ ->
        {:reply, :miss, state}
    end
  end
end
