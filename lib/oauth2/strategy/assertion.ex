defmodule OAuth2.Strategy.Assertion do
  use OAuth2.Strategy

  def authorize_url(client, params) do
    client
    |> put_param(:response_type, "Assertion")
    |> put_param(:client_id, client.client_id)
    |> put_param(:redirect_uri, client.redirect_uri)
    |> merge_params(params)
  end

  def get_token(client, params, headers) do
    {code, params} = Keyword.pop(params, :code, client.params["code"])

    unless code do
      raise OAuth2.Error, reason: "Missing required key `code` for `#{inspect __MODULE__}`"
    end

    client
    |> put_param(:client_assertion_type, "urn:ietf:params:oauth:client-assertion-type:jwt-bearer")
    |> put_param(:client_assertion, client.client_secret)
    |> put_param(:grant_type, "urn:ietf:params:oauth:grant-type:jwt-bearer")
    |> put_param(:assertion, code)
    |> put_param(:redirect_uri, client.redirect_uri)
    |> merge_params(params)
    |> put_headers(headers)
  end
end
