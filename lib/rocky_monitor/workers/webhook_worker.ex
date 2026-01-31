defmodule RockyMonitor.Workers.WebhookWorker do
  use Oban.Worker,
    queue: :webhooks,
    max_attempts: 3

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    webhook_url = Application.get_env(:rocky_monitor, :webhook_url)
    webhook_secret = Application.get_env(:rocky_monitor, :webhook_secret)
    timeout = Application.get_env(:rocky_monitor, :webhook_timeout_ms, 5000)

    if is_nil(webhook_url) or webhook_url == "" do
      Logger.warning("Webhook URL not configured, skipping webhook delivery")
      :ok
    else
      send_webhook(webhook_url, webhook_secret, args, timeout)
    end
  end

  defp send_webhook(url, secret, payload, timeout) do
    Logger.info("Sending webhook: #{payload["event"]} to #{url}")
    Logger.info("Webhook payload: #{Jason.encode!(payload)}")

    headers = [
      {"authorization", "Bearer #{secret}"},
      {"content-type", "application/json"}
    ]

    case Req.post(url,
           json: payload,
           headers: headers,
           receive_timeout: timeout,
           retry: false
         ) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        Logger.info("Webhook delivered successfully: #{payload["event"]} (status: #{status})")
        Logger.info("Webhook response: #{inspect(body)}")
        :ok

      {:ok, %{status: status, body: body}} ->
        Logger.error("Webhook failed with status #{status}: #{inspect(body)}")
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        Logger.error("Webhook request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
