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
      {:ecto, "~> 3.7"},
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
      source_ref: "v#{@version}"
    ]
  end
end
