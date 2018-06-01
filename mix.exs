defmodule KaurError.MixProject do
  use Mix.Project

  @project_url "https://github.com/fewlinesco/kaur_error"

  def project do
    [
      app: :kaur_error,
      build_embedded: Mix.env() == :prod,
      consolidate_protocols: false,
      deps: deps(),
      description: "Utilities for working with errors",
      dialyzer: dialyzer(),
      docs: [main: "readme", extras: ["README.md"]],
      elixir: "~> 1.4",
      homepage_url: @project_url,
      name: "kaur_error",
      package: package(),
      source_url: @project_url,
      start_permanent: Mix.env() == :prod,
      version: "1.0.0"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 0.8.10", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:dev, :test]},
      {:earmark, ">= 1.0.3", only: [:docs]},
      {:ex_doc, "~> 0.16.2", only: [:docs]},
      {:excoveralls, "~> 0.7.1", only: [:test]},
      {:inch_ex, "~> 0.5.5", only: [:docs]},
      {:kaur, "~> 1.1.0", only: [:test]}
    ]
  end

  defp dialyzer do
    [verbose: true, flags: [:error_handling, :race_conditions]]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @project_url},
      maintainers: ["Fewlines SAS"]
    ]
  end
end
