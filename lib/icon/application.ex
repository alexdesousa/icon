defmodule Icon.Application do
  @moduledoc false
  use Application

  @spec start(Application.start_type(), any()) ::
          {:ok, pid()}
          | {:ok, pid(), any()}
          | {:error, any()}
  @impl Application
  def start(_type, _args) do
    children = [
      {Finch, name: Icon.Finch}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Icon.App)
  end
end
