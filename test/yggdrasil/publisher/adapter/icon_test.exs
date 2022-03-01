defmodule Yggdrasil.Publisher.Adapter.IconTest do
  use ExUnit.Case, async: true

  alias Icon.Schema.Error
  alias Yggdrasil.Publisher.Adapter.Icon, as: Publisher

  test "cannot publish messages in ICON 2.0 websocket" do
    channel = [
      name: %{source: :block},
      adapter: :icon
    ]

    assert {:error,
            %Error{
              code: -32_600,
              message: "cannot publish messages in the ICON 2.0 blockchain",
              reason: :invalid_request
            }} = Yggdrasil.publish(channel, "{}")
  end

  test "start and stop the publisher process" do
    assert {:ok, pid} = Publisher.start_link(nil)
    assert :ok = Publisher.stop(pid)
  end
end
