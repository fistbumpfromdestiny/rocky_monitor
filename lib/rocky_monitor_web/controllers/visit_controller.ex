defmodule RockyMonitorWeb.VisitController do
  use RockyMonitorWeb, :controller

  alias RockyMonitor.{Repo, Visit, SessionManager}
  import Ecto.Query

  @doc """
  GET /api/visits/current

  Returns the currently active visit, if any.
  """
  def current(conn, _params) do
    case SessionManager.get_current_visit() do
      nil ->
        json(conn, %{current_visit: nil})

      visit ->
        json(conn, %{
          current_visit: %{
            id: visit.id,
            arrival_time: visit.arrival_time,
            detection_count: visit.detection_count,
            status: visit.status
          }
        })
    end
  end

  @doc """
  GET /api/visits/recent?limit=10

  Returns recent completed visits.
  """
  def recent(conn, params) do
    limit = parse_limit(params["limit"])

    visits =
      Visit
      |> where([v], v.status == "completed")
      |> order_by([v], desc: v.arrival_time)
      |> limit(^limit)
      |> Repo.all()

    visits_json =
      Enum.map(visits, fn visit ->
        %{
          id: visit.id,
          arrival_time: visit.arrival_time,
          departure_time: visit.departure_time,
          duration_seconds: visit.duration_seconds,
          detection_count: visit.detection_count,
          status: visit.status
        }
      end)

    json(conn, %{visits: visits_json, count: length(visits_json)})
  end

  defp parse_limit(nil), do: 10
  defp parse_limit(limit) when is_integer(limit), do: min(limit, 100)

  defp parse_limit(limit) when is_binary(limit) do
    case Integer.parse(limit) do
      {num, _} -> min(num, 100)
      :error -> 10
    end
  end
end
