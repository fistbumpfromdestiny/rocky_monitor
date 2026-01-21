defmodule RockyMonitorWeb.HealthController do
  use RockyMonitorWeb, :controller

  alias RockyMonitor.Repo

  @doc """
  GET /api/health

  Basic health check endpoint.
  """
  def index(conn, _params) do
    db_status = check_database()

    json(conn, %{
      status: "ok",
      database: db_status,
      timestamp: DateTime.utc_now()
    })
  end

  defp check_database do
    try do
      Repo.query!("SELECT 1")
      "connected"
    rescue
      _ -> "disconnected"
    end
  end
end
