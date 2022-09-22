defmodule Icon.Stream.Consumer.Publisher do
  @moduledoc """
  This module implements a consumer that publishes the messages it receives into
  a `Phoenix.PubSub` channel.
  """
  use GenStage

  @doc """
  Starts a new consumer for a specific stream. The messages are broadcasted
  using `Phoenix.PubSub`.
  """
  @spec start_link(Icon.Stream.t()) :: GenServer.on_start()
  @spec start_link(Icon.Stream.t(), GenServer.options()) :: GenServer.on_start()
  def start_link(stream, options \\ [])

  def start_link(stream, options) do
    channel = generate_channel(stream)

    GenStage.start_link(__MODULE__, channel, options)
  end

  @doc false
  @spec generate_channel(Icon.Stream.t()) :: binary()
  def generate_channel(stream) do
    "#{__MODULE__}:#{Icon.Stream.to_hash(stream)}"
  end

  ####################
  # Callback functions

  @impl GenStage
  def init(channel) do
    {:consumer, channel}
  end

  @impl GenStage
  def handle_events(events, _from, channel) do
    for event <- events do
      message = {:"$ICON", event}
      Phoenix.PubSub.broadcast(Icon.Stream.PubSub, channel, message)
    end

    {:noreply, [], channel}
  end
end
