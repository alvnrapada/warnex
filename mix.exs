defmodule Warnex.MixProject do
  use Mix.Project

  def project do
    [
      app: :warnex,
      version: "0.2.0",
      elixir: "~> 1.18.1",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: "https://github.com/alvnrapada/warnex"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp description() do
    """
    A Phoenix/Elixir application warning manager that helps track and manage application warnings effectively.
    """
  end

  defp package() do
    [
      name: "warnex",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/alvnrapada/warnex"}
    ]
  end

  defp docs() do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
