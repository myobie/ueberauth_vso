use Mix.Config

config :ueberauth, Ueberauth.Strategy.VSTS.OAuth,
  redirect_uri: "http://localhost:4000/auth/vsts/callback",
  client_id: "test",
  client_secret: "sekr3t"
