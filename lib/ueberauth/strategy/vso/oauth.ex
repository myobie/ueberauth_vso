defmodule Ueberauth.Strategy.VSO.OAuth do
  @moduledoc """
  An implementation of OAuth2 for VSO.

  To add your `client_id` and `client_secret` include these values in your configuration.

      config :ueberauth, Ueberauth.Strategy.VSO.OAuth,
        client_id: System.get_env("VSO_APP_ID"),
        client_secret: System.get_env("VSO_CLIENT_SECRET")
  """

  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    response_type: "Assertion",
    site: "https://app.vssps.visualstudio.com/",
    authorize_url: "https://app.vssps.visualstudio.com/oauth2/authorize",
    token_url: "https://app.vssps.visualstudio.com/oauth2/token"
  ]

  @doc """
  Construct a client for requests to Github.

  Optionally include any OAuth2 options here to be merged with the defaults.

      Ueberauth.Strategy.VSO.OAuth.client(redirect_uri: "http://localhost:4000/auth/vso/callback")

  This will be setup automatically for you in `Ueberauth.Strategy.VSO`.
  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    config =
      :ueberauth
      |> Application.fetch_env!(Ueberauth.Strategy.VSO.OAuth)
      |> check_config_key_exists(:client_id)
      |> check_config_key_exists(:client_secret)
      |> check_config_key_exists(:redirect_uri)

    client_opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    OAuth2.Client.new(client_opts)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.

  ## Examples

      iex> Ueberauth.Strategy.VSO.OAuth.authorize_url!(
      ...>   scope: "vso.profile",
      ...>   state: 123
      ...> )
      "https://app.vssps.visualstudio.com/oauth2/authorize?client_id=test&redirect_uri=http%3A%2F%2Flocalhost%3A4000%2Fauth%2Fvso%2Fcallback&response_type=Assertion&scope=vso.profile&state=123"
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client()
    |> OAuth2.Client.authorize_url!(params)
  end

  def get(token, url, headers \\ [], opts \\ []) do
    [token: token]
    |> client()
    |> OAuth2.Client.get(url, headers, opts)
  end

  def get_token!(params \\ [], options \\ []) do
    headers        = Keyword.get(options, :headers, [])
    options        = Keyword.get(options, :options, [])
    client_options = Keyword.get(options, :client_options, [])
    client         = OAuth2.Client.get_token!(client(client_options), params, headers, options)

    %{client.token | token_type: "Bearer"} # Note: the token_type returned from the api is jwt-bearer, but that doesn't apply to the HTTP header so we override it here
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.Assertion.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param(:client_secret, client.client_secret)
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.Assertion.get_token(params, headers)
  end

  defp check_config_key_exists(config, key) when is_list(config) do
    unless Keyword.has_key?(config, key) do
      raise "#{inspect key} missing from config :ueberauth, Ueberauth.Strategy.VSO"
    end
    config
  end

  defp check_config_key_exists(_, _) do
    raise "Config :ueberauth, Ueberauth.Strategy.VSO is not a keyword list, as expected"
  end
end
