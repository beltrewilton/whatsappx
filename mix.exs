defmodule Whatsappx.MixProject do
  use Mix.Project

  @version "0.1.2"
  @repo_url "https://github.com/beltrewilton/whatsappx"

  def project do
    [
      app: :whatsappx,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "Open source Elixir wrapper + Crypto for the WhatsApp Cloud API",
      package: package(),

      # Docs
      name: "whatsappx",
      docs: [
        name: "whatsappx",
        source_ref: "v#{@version}",
        source_url: @repo_url,
        homepage_url: @repo_url,
        main: "readme",
        extras: ["README.md"],
        links: %{
          "GitHub" => @repo_url,
          "Sponsor" => "https://github.com/beltrewilton/"
        }
      ]
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @repo_url
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    # export WHATSAPP_FLOW_CRYPTO_PATH=/home/wilton/plex_env/whatsappx

    [
      {:req, "~> 0.5.6"},
      {:jason, "~> 1.4"},
      {:httpoison, "~> 2.2.1"},
      {:uuid, "~> 1.1"},

      {:rustler, "~> 0.34.0"},
      {:ex_doc, "~> 0.32.2", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    ]
  end
end
