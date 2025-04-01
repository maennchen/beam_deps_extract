defmodule BeamDepsExtract.MixProject do
  use Mix.Project

  def project do
    [
      app: :beam_deps_extract,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  def application do
    [
      mod: {BeamDepsExtract, []},
      extra_applications: [:mix]
    ]
  end

  def releases do
    [
      beam_deps_extract: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            linux: [os: :linux, cpu: :x86_64]
          ]
        ]
      ]
    ]
  end

  defp deps do
    [
      {:burrito, "~> 1.0"},
      {:jason, "~> 1.4"}
    ]
  end
end
