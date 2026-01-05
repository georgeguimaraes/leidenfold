defmodule Leidenfold.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :leidenfold,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir bindings for the Leiden community detection algorithm",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:rustler, "~> 0.36.0"},
      {:rustler_precompiled, "~> 0.8"}
    ]
  end

  defp package do
    [
      name: "leidenfold",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/your-org/leidenfold"},
      files: ~w(lib native .formatter.exs mix.exs README.md LICENSE)
    ]
  end
end
