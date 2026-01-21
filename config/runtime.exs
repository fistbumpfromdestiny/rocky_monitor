import Config

# Load .env file in all environments
Dotenvy.source!([".env", System.get_env()])

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/rocky_monitor start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :rocky_monitor, RockyMonitorWeb.Endpoint, server: true
end

config :rocky_monitor, RockyMonitorWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT") || "4000")]

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      """

  config :rocky_monitor, RockyMonitor.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  webhook_url =
    System.get_env("WEBHOOK_URL") ||
      raise """
      environment variable WEBHOOK_URL is missing.
      For example: https://your-nextjs-app.com/api/webhook
      """

  webhook_secret =
    System.get_env("WEBHOOK_SECRET") ||
      raise """
      environment variable WEBHOOK_SECRET is missing.
      Generate with: openssl rand -base64 32
      """

  config :rocky_monitor,
    webhook_url: webhook_url,
    webhook_secret: webhook_secret,
    webhook_retry_attempts: String.to_integer(System.get_env("WEBHOOK_RETRY_ATTEMPTS") || "3"),
    webhook_timeout_ms: String.to_integer(System.get_env("WEBHOOK_TIMEOUT_MS") || "5000")
else
  # Dev/test configuration
  config :rocky_monitor,
    webhook_url: System.get_env("WEBHOOK_URL") || "http://localhost:3000/api/webhook",
    webhook_secret: System.get_env("WEBHOOK_SECRET") || "dev-secret-change-in-production",
    webhook_retry_attempts: 3,
    webhook_timeout_ms: 5000
end
