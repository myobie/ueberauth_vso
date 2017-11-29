defmodule UeberauthVsts.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :ueberauth_vsts,
      version: @version,
      name: "Ueberauth VSTS",
      package: package(),
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      source_url: "https://github.com/myobie/ueberauth_vsts",
      homepage_url: "https://github.com/myobie/ueberauth_vsts",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:oauth2, "~> 0.9"},
      {:ueberauth, "~> 0.4"}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Nathan Herald"],
      licenses: ["MIT"],
      links: %{"GitHub": "https://github.com/myobie/ueberauth_vsts"}
    ]
  end
end
