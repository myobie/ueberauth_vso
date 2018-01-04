use Mix.Config

config :ueberauth, Ueberauth.Strategy.VSO.OAuth,
  redirect_uri: "http://localhost:4000/auth/vso/callback",
  client_id: "test",
  client_secret: "sekr3t"
