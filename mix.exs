defmodule Icon.MixProject do
  use Mix.Project

  @version "0.1.2"
  @name "ICON 2.0 SDK"
  @description "Basic API for interacting with ICON 2.0 blockchain"
  @app :icon
  @root "https://github.com/alexdesousa/icon"

  def project do
    [
      name: @name,
      app: @app,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ],
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  #############
  # Application

  def application do
    [
      mod: {Icon.Application, []},
      extra_applications: [:logger]
    ]
  end

  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:finch, "~> 0.10"},
      {:jason, "~> 1.3"},
      {:curvy, "~> 0.3"},
      {:websockex, "~> 0.4"},
      {:yggdrasil, "~> 6.0"},
      {:bypass, "~> 2.1", only: :test},
      {:plug_cowboy, "~> 2.0", pnly: :test},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test, runtime: false}
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/#{@app}.plt"}
    ]
  end

  #########
  # Package

  defp package do
    [
      description: @description,
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md"],
      maintainers: ["Alexander de Sousa"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "#{@root}/blob/master/CHANGELOG.md",
        "Github" => @root
      }
    ]
  end

  ###############
  # Documentation

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md"
      ],
      source_url: @root,
      source_ref: "v#{@version}",
      groups_for_modules: groups_for_modules(),
      nest_modules_by_prefix: nest_modules_by_prefix()
    ]
  end

  defp groups_for_modules do
    [
      "ICON 2.0 SDK": [
        Icon
      ],
      "JSON RPC v3": [
        Icon.RPC.Identity,
        Icon.RPC.Request,
        Icon.RPC.Request.Goloop
      ],
      "Schema Behaviours": [
        Icon.Schema,
        Icon.Schema.Type,
        Icon.Schema.Error
      ],
      "Schema Primitive Types": [
        Icon.Schema.Types.Address,
        Icon.Schema.Types.Any,
        Icon.Schema.Types.BinaryData,
        Icon.Schema.Types.Boolean,
        Icon.Schema.Types.EOA,
        Icon.Schema.Types.EventLog,
        Icon.Schema.Types.Hash,
        Icon.Schema.Types.Integer,
        Icon.Schema.Types.Loop,
        Icon.Schema.Types.SCORE,
        Icon.Schema.Types.Signature,
        Icon.Schema.Types.String,
        Icon.Schema.Types.Timestamp
      ],
      "Schema Complex Types": [
        Icon.Schema.Types.Block,
        Icon.Schema.Types.Transaction,
        Icon.Schema.Types.Transaction.Result,
        Icon.Schema.Types.Transaction.Status
      ]
    ]
  end

  defp nest_modules_by_prefix do
    [
      Icon.Schema,
      Icon.RPC
    ]
  end
end
