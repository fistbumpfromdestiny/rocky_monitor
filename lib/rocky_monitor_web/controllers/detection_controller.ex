defmodule RockyMonitorWeb.DetectionController do
  use RockyMonitorWeb, :controller

  require Logger
  alias RockyMonitor.SessionManager

  @doc """
  POST /api/detections

  Expects JSON body:
  {
    "timestamp": "2026-01-20T10:30:00Z",
    "confidence": 0.95,
    "snapshot_base64": "base64_encoded_image_data"
  }
  """

  def create(conn, params) do
    Logger.info("Received detection with confidence: #{params["confidence"]}")

    case SessionManager.process_detection(params) do
      {:ok, detection} ->
        json(conn, %{
          status: "accepted",
          visit_id: detection.visit_id,
          detection_id: detection.id
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = format_changeset_errors(changeset)

        conn
        |> put_status(:bad_request)
        |> json(%{error: "Validation failed", details: errors})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: to_string(reason)})
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
