defmodule NaturalSet.MixProject do
  use Mix.Project

  def project do
    [
      app: :natural_set,
      version: "0.2.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),

      # Hex
      description: "A set type for small non-negative integers.",
      package: package(),

      # Docs
      name: "NaturalSet",
      source_url: "https://github.com/standupdev/natural_set"
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
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:credo, "~> 1.0.5", only: [:dev, :test], runtime: false},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp package() do
    [
      licenses: ["BSD 2-Clause"],
      links: %{"GitHub" => "https://github.com/standupdev/natural_set"}
    ]
  end
end
