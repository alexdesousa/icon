defmodule Icon.Stream.Supervisor do
  @moduledoc """
  This module defines a supervisor for supervising the websocket stream stages.
  """
  use Supervisor, restart: :transient

  @doc """
  Starts a mew stream supervisor.
  """
  @spec start_link(Icon.Stream.t()) :: Supervisor.on_start()
  @spec start_link(Icon.Stream.t(), [Supervisor.option()]) ::
          Supervisor.on_start()
  def start_link(stream, options \\ [])

  def start_link(stream, options) when is_pid(stream) do
    if Process.alive?(stream) do
      Supervisor.start_link(__MODULE__, stream, options)
    else
      {:error, {:shutdown, "Stream is dead"}}
    end
  end

  ###################
  # Callback function

  @impl Supervisor
  def init(stream) do
    true = Process.link(stream)

    children = [
      {Icon.Stream.WebSocket, stream},
      {Icon.Stream.Consumer.Publisher, stream}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
