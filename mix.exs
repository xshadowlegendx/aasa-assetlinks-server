defmodule AasaAssetlinksServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :aasa_assetlinks_server,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :fast_xml],
      mod: {AasaAssetlinksServer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:plug, "~> 1.16"},
      {:bandit, "~> 1.0"},
      {:finch, "~> 0.19.0"},
      {:fast_xml, "~> 1.1"},
      {:libcluster, "~> 3.4"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end
end
