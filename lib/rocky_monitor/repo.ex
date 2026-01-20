defmodule RockyMonitor.Repo do
  use Ecto.Repo,
    otp_app: :rocky_monitor,
    adapter: Ecto.Adapters.SQLite3
end
