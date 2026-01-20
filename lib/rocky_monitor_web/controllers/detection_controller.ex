defmodule RockyMonitorWeb.DetectionController do
  use RockyMonitorWeb, :controller

  require Logger

  @doc """
  POST /api/detections

  Expects JSON body:
  {
    "timestamp": "2026-01-20T10:30:00Z",
    "confidence": 0.95,
    "cat_detected": true,
    "metadata" : {
      "camera_id": "tapo_c200"
    }
  }
  """

  def create(conn, params) do
    Logger.info("Received detection: #{inspect(params)}")

    case validate_detection(params) do
      {:ok, detection} ->
        RockyMonitor.Webhook.send_detection_async(detection)

        json(conn, %{status: "accepted", message: "Detection received"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  defp validate_detection(params) do
    with {:ok, timestamp} <- parse_timestamp(params["timestamp"]),
         {:ok, confidence} <- parse_confidence(params["confidence"]) do
      detection = %{
        timestamp: timestamp,
        confidence: confidence,
        cat_detected: params["cat_detected"] || true,
        metadata: params["metadata"] || %{}
      }

      {:ok, detection}
    else
      {:error, _} = error -> error
    end
  end

  defp parse_timestamp(nil), do: {:ok, DateTime.utc_now()}

  defp parse_timestamp(timestamp) when is_binary(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, dt, _offset} -> {:ok, dt}
      {:error, _} -> {:error, "invalid timestamp format"}
    end
  end

  defp parse_confidence(confidence)
       when is_number(confidence) and confidence >= 0 and confidence <= 1 do
    {:ok, confidence}
  end

  defp parse_confidence(_), do: {:error, "confidence must be a number between 0 and 1"}
end
