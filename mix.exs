defmodule Icon.MixProject do
  use Mix.Project

  @version "0.2.5"
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
      {:exreg, "~> 1.0"},
      {:finch, "~> 0.13"},
      {:jason, "~> 1.4"},
      {:curvy, "~> 0.3"},
      {:gen_stage, "~> 1.0"},
      {:mint, "~> 1.4"},
      {:mint_web_socket, "~> 1.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:websockex, "~> 0.4"},
      {:yggdrasil, "~> 6.0"},
      {:skogsra, "~> 2.4"},
      {:bypass, "~> 2.1", only: :test},
      {:plug_cowboy, "~> 2.5", only: :test},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
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
        "Github" => @root,
        "Sponsor" => "https://github.com/sponsors/alexdesousa"
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
      nest_modules_by_prefix: nest_modules_by_prefix(),
      before_closing_body_tag: &before_closing_body_tag/1
    ]
  end

  defp before_closing_body_tag(:html) do
    """
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.13.19/dist/katex.min.css" integrity="sha384-beuqjL2bw+6DBM2eOpr5+Xlw+jiH44vMdVQwKxV28xxpoInPHTVmSvvvoPq9RdSh" crossorigin="anonymous">
    <script defer src="https://cdn.jsdelivr.net/npm/katex@0.13.19/dist/katex.min.js" integrity="sha384-aaNb715UK1HuP4rjZxyzph+dVss/5Nx3mLImBe9b0EW4vMUkc1Guw4VRyQKBC0eG" crossorigin="anonymous"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/katex@0.13.19/dist/contrib/auto-render.min.js" integrity="sha384-+XBljXPPiv+OzfbB3cVmLHf4hdUFHlWNZN5spNQ7rmHTXpd7WvJum6fIACpNNfIR" crossorigin="anonymous"
    onload="renderMathInElement(document.body);"></script>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@8.13.3/dist/mermaid.min.js"></script>
    <script>
      document.addEventListener("DOMContentLoaded", function () {
        mermaid.initialize({ startOnLoad: false });
        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition, function (svgSource, bindListeners) {
            graphEl.innerHTML = svgSource;
            bindListeners && bindListeners(graphEl);
            preEl.insertAdjacentElement("afterend", graphEl);
            preEl.remove();
          });
        }
      });
    </script>
    """
  end

  defp before_closing_body_tag(_), do: ""

  defp groups_for_modules do
    [
      "ICON 2.0 SDK": [
        Icon,
        Icon.Config
      ],
      "JSON RPC v3": [
        Icon.RPC.Identity,
        Icon.RPC.Request,
        Icon.RPC.Request.Goloop
      ],
      "ICON 2.0 WebSocket": [
        Icon.Stream,
        Icon.Stream.Consumer.Publisher,
        Icon.Stream.Supervisor,
        Icon.Stream.WebSocket
      ],
      "Yggdrasil Websocket adapter": [
        Yggdrasil.Adapter.Icon,
        Yggdrasil.Config.Icon,
        Yggdrasil.Publisher.Adapter.Icon,
        Yggdrasil.Subscriber.Adapter.Icon,
        Yggdrasil.Subscriber.Adapter.Icon.Message,
        Yggdrasil.Subscriber.Adapter.Icon.WebSocket
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
        Icon.Schema.Types.NegInteger,
        Icon.Schema.Types.NonNegInteger,
        Icon.Schema.Types.NonPosInteger,
        Icon.Schema.Types.PosInteger,
        Icon.Schema.Types.SCORE,
        Icon.Schema.Types.Signature,
        Icon.Schema.Types.String,
        Icon.Schema.Types.Timestamp
      ],
      "Schema Complex Types": [
        Icon.Schema.Types.Block,
        Icon.Schema.Types.Block.Tick,
        Icon.Schema.Types.Transaction,
        Icon.Schema.Types.Transaction.Result,
        Icon.Schema.Types.Transaction.Status
      ]
    ]
  end

  defp nest_modules_by_prefix do
    [
      Icon.Schema,
      Icon.Stream,
      Icon.RPC
    ]
  end
end
