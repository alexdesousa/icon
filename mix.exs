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
      start_permanent: Mix.env() == :prod,
      dialyzer: dialyzer(),
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  #############
  # Application

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:ex_doc, "~> 0.26", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false}
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
        Icon
      ],
      "Schema Behaviours": [
        Icon.Types.Schema,
        Icon.Types.Schema.Type,
        Icon.Types.Error
      ],
      "Schema Primitive Types": [
        Icon.Types.Address,
        Icon.Types.BinaryData,
        Icon.Types.Boolean,
        Icon.Types.EOA,
        Icon.Types.Hash,
        Icon.Types.Integer,
        Icon.Types.SCORE,
        Icon.Types.Signature,
        Icon.Types.String
      ],
      "JSON RPC v3": [
        Icon.RPC,
        Icon.RPC.Goloop
      ]
    ]
  end

  defp nest_modules_by_prefix do
    [
      Icon.Types,
      Icon.RPC
    ]
  end
end
