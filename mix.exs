defmodule Icon.MixProject do
  use Mix.Project

  @version "0.1.0"
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

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      mod: {Icon.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:finch, "~> 0.10"},
      {:jason, "~> 1.2"},
      {:skogsra, "~> 2.3"},
      {:bypass, "~> 2.1", only: :test},
      {:ex_doc, "~> 0.26", only: :dev, runtime: false},
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
      files: ["lib", "mix.ex", "README.md", "CHANGELOG.md"],
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
        Icon,
        Icon.Config
      ],
      "JSON RPC v3": [
        Icon.RPC.HTTP,
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
        Icon.Schema.Types.BinaryData,
        Icon.Schema.Types.Boolean,
        Icon.Schema.Types.EOA,
        Icon.Schema.Types.Hash,
        Icon.Schema.Types.Integer,
        Icon.Schema.Types.Loop,
        Icon.Schema.Types.SCORE,
        Icon.Schema.Types.Signature,
        Icon.Schema.Types.String,
        Icon.Schema.Types.Timestamp
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
