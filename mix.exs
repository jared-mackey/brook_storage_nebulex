defmodule BrookStorageNebulex.MixProject do
  use Mix.Project

  @description """
  An implementation of `Brook.Storage` for Nebulex.
  """
  @github "https://github.com/mackeyja92/brook_storage_nebulex"
  @license "Apache 2.0"

  def project do
    [
      app: :brook_storage_nebulex,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      description: @description,
      source_url: @github,
      homepage_url: @github
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:brook, "~> 0.5"},
      {:ex_doc, "0.21.0", only: [:dev]},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:nebulex, "~> 1.2"}
    ]
  end

  defp package do
    [
      maintainers: ["Jared Mackey"],
      licenses: [@license],
      links: %{"GitHub" => @github}
    ]
  end

  defp docs do
    [
      source_url: @github,
      licenses: [@license],
      links: %{"GitHub" => @github},
      extras: ["README.md"]
    ]
  end
end
