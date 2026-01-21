defmodule RockyMonitor.Webhooks do
  @moduledoc """
  Helper module for enqueueing webhook jobs via Oban.
  """

  alias RockyMonitor.Workers.WebhookWorker

  @doc """
  Enqueues an arrival webhook for a new visit.
  """
  def send_arrival(visit) do
    %{
      "event" => "rocky_arrived",
      "visit_id" => visit.id,
      "timestamp" => DateTime.to_iso8601(visit.arrival_time),
      "snapshot_base64" => visit.first_snapshot_base64
    }
    |> WebhookWorker.new()
    |> Oban.insert()
  end

  @doc """
  Enqueues a departure webhook for a completed visit.
  """
  def send_departure(visit) do
    %{
      "event" => "rocky_departed",
      "visit_id" => visit.id,
      "arrival_time" => DateTime.to_iso8601(visit.arrival_time),
      "departure_time" => DateTime.to_iso8601(visit.departure_time),
      "duration_seconds" => visit.duration_seconds,
      "duration_human" => humanize_duration(visit.duration_seconds),
      "detection_count" => visit.detection_count,
      "snapshot_base64" => visit.last_snapshot_base64
    }
    |> WebhookWorker.new()
    |> Oban.insert()
  end

  defp humanize_duration(nil), do: "unknown"

  defp humanize_duration(seconds) when is_integer(seconds) do
    cond do
      seconds < 60 ->
        "#{seconds} seconds"

      seconds < 3600 ->
        minutes = div(seconds, 60)
        remaining_seconds = rem(seconds, 60)
        "#{minutes} minutes, #{remaining_seconds} seconds"

      true ->
        hours = div(seconds, 3600)
        remaining_minutes = div(rem(seconds, 3600), 60)
        "#{hours} hours, #{remaining_minutes} minutes"
    end
  end
end
