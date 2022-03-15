defmodule Icon.Application do
  @moduledoc false
  use Application

  alias Icon.Config

  @spec start(Application.start_type(), any()) ::
          {:ok, pid()}
          | {:ok, pid(), any()}
          | {:error, any()}
  @impl Application
  def start(_type, _args) do
    Config.validate!()

    children = [
      {Finch, name: Icon.Finch},
      {Yggdrasil.Adapter.Icon, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Icon.App)
  end
end
