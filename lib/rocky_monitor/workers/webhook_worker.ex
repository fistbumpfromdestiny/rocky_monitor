defmodule RockyMonitor.Workers.WebhookWorker do
  use Oban.Worker,
    queue: :webhooks,
    max_attempts: 3

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    webhook_url = Application.get_env(:rocky_monitor, :webhook_url)
    timeout = Application.get_env(:rocky_monitor, :webhook_timeout_ms, 5000)

    if is_nil(webhook_url) or webhook_url == "" do
      Logger.warning("Webhook URL not configured, skipping webhook delivery")
      :ok
    else
      send_webhook(webhook_url, args, timeout)
    end
  end

  defp send_webhook(url, payload, timeout) do
    Logger.info("Sending webhook: #{payload["event"]} to #{url}")

    case Req.post(url,
           json: payload,
           receive_timeout: timeout,
           retry: false
         ) do
      {:ok, %{status: status}} when status in 200..299 ->
        Logger.info("Webhook delivered successfully: #{payload["event"]}")
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
