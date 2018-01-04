defmodule Ueberauth.Strategy.VSO do
  use Ueberauth.Strategy, uid_field: :id,
                          default_scope: "vso.profile",
                          oauth2_module: Ueberauth.Strategy.VSO.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    send_redirect_uri = Keyword.get(options(conn), :send_redirect_uri, true)

    opts =
      if send_redirect_uri do
        [redirect_uri: callback_url(conn), scope: scopes]
      else
        [scope: scopes]
      end

    opts =
      if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [[code: code]])

    if token.access_token == nil do
      set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    else
      fetch_profile(conn, token)
    end
  end

  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  def handle_cleanup!(conn) do
    conn
    |> put_private(:vso_profile, nil)
    |> put_private(:vso_token, nil)
  end

  def uid(conn) do
    field =
      conn
      |> option(:uid_field)
      |> to_string
    conn.private.vso_profile[field]
  end

  def credentials(conn) do
    token        = conn.private.vso_token
    scope_string = (token.other_params["scope"] || "")
    scopes       = String.split(scope_string, ",")

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: scopes
    }
  end

  def info(conn) do
    profile = conn.private.vso_profile

    name = profile["displayName"]
    email = profile["emailAddress"]

    nickname =
      email
      |> String.split(~r(@))
      |> List.first()

    %Info{
      name: name,
      nickname: nickname,
      email: email
    }
  end

  def extra(conn) do
    %Extra {
      raw_info: %{
        token: conn.private.vso_token,
        profile: conn.private.vso_profile
      }
    }
  end

  defp fetch_profile(conn, token) do
    conn = put_private(conn, :vso_token, token)

    with {:ok, profile} <- fetch_vso_profile(token) do
      put_private(conn, :vso_profile, profile)
    else
      error ->
        set_errors!(conn, [error])
    end
  end

  defp fetch_vso_profile(token) do
    case Ueberauth.Strategy.VSO.OAuth.get(token, "/_apis/profile/profiles/me?api-version=1.0") do
      {:error, %OAuth2.Error{reason: reason}} ->
        error("OAuth2", reason)
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        error("token", "unauthorized")
      {:ok, %OAuth2.Response{status_code: status_code, body: profile}} when status_code in 200..299 ->
        {:ok, profile}
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
