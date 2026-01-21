defmodule RockyMonitor.Webhook do
  @moduledoc """
  Handles sending cat detection events to the webhook endpoint
  """
  require Logger

  @doc """
  Sends a detection event to the configured webhook URL.

  ## Parameters
    - detection: Map containing detection data (timestamp, confidence, etc.)

  ## Examples
      iex> RockyMonitor.Webhook.send_detection(%{
        timestamp: ~U[2024-01-20 10:30:00Z],
        confidence: 0.95,
        cat_detected: true,
        is_new_session: true
      })
      {:ok, %{status: 200}}
  """

  def send_detection(detection) do
    url = webhook_url()
    payload = build_payload(detection)

    Logger.info("Sending webhook to #{url}")

    case Req.post(url, json: payload) do
      {:ok, %{status: status} = response} when status in 200..299 ->
        Logger.info("Webhook delivered successfully: #{status}")
        {:ok, response}

      {:ok, %{status: status} = response} ->
        Logger.warning("Webhook failed with status #{status}: #{inspect(response.body)}")
        {:error, {:http_error, status, response}}

      {:error, reason} ->
        Logger.error("Webhook request failed: #{inspect(reason)}")
    end
  end

  @doc """
  Sends a detection asynchronously
  """
  def send_detection_async(detection) do
    Task.start(fn -> send_detection(detection) end)
  end

  defp build_payload(detection) do
    %{
      timestamp: detection.timestamp,
      confidence: detection.confidence,
      cat_detected: detection.cat_detected,
      is_new_session: detection.is_new_session,
      metadata: Map.get(detection, :metadata, %{})
    }
  end

  defp webhook_url do
    Application.get_env(:rocky_monitor, :webhook_url)
  end
end
