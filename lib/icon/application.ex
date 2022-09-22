defmodule Icon.Application do
  @moduledoc false
  use Application

  alias Icon.Config
  alias Yggdrasil.Config.Icon, as: YggdrasilConfig

  @spec start(Application.start_type(), any()) ::
          {:ok, pid()}
          | {:ok, pid(), any()}
          | {:error, any()}
  @impl Application
  def start(_type, _args) do
    Config.validate!()
    YggdrasilConfig.validate!()

    children = [
      {Finch, name: Icon.Finch},
      {Phoenix.PubSub, name: Icon.Stream.PubSub},
      {Yggdrasil.Adapter.Icon, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Icon.App)
  end
end
