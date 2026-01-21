defmodule RockyMonitor.SessionManager do
  use GenServer
  require Logger

  alias RockyMonitor.{Repo, Visit, Detection, Webhooks}

  # 5 minutes
  @session_timeout_ms 5 * 60 * 1000

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Process a new detection. Creates a new visit if needed, or updates existing visit.
  Returns {:ok, detection} or {:error, reason}.
  """
  def process_detection(params) do
    GenServer.call(__MODULE__, {:process_detection, params})
  end

  @doc """
  Get the current active visit, if any.
  """
  def get_current_visit do
    GenServer.call(__MODULE__, :get_current_visit)
  end

  # Server Callbacks

  @impl true
  def init(_) do
    state = %{
      current_visit_id: nil,
      last_detection_at: nil,
      timer_ref: nil
    }

    Logger.info("SessionManager started")
    {:ok, state}
  end

  @impl true
  def handle_call({:process_detection, params}, _from, state) do
    timestamp = parse_timestamp(params["timestamp"]) || DateTime.utc_now()
    confidence = parse_float(params["confidence"]) || 0.0
    snapshot = params["snapshot_base64"]

    case state.current_visit_id do
      nil ->
        # No active visit - create new one
        handle_new_visit(timestamp, confidence, snapshot, state)

      visit_id ->
        # Active visit exists - add detection and reset timer
        handle_existing_visit(visit_id, timestamp, confidence, snapshot, state)
    end
  end

  @impl true
  def handle_call(:get_current_visit, _from, state) do
    visit =
      case state.current_visit_id do
        nil -> nil
        id -> Repo.get(Visit, id)
      end

    {:reply, visit, state}
  end

  @impl true
  def handle_info(:timeout_check, state) do
    # Session timeout - finalize the visit
    case state.current_visit_id do
      nil ->
        {:noreply, state}

      visit_id ->
        Logger.info("Session timeout - finalizing visit #{visit_id}")
        finalize_visit(visit_id, state.last_detection_at)

        new_state = %{
          current_visit_id: nil,
          last_detection_at: nil,
          timer_ref: nil
        }

        {:noreply, new_state}
    end
  end

  # Private Functions

  defp handle_new_visit(timestamp, confidence, snapshot, state) do
    Logger.info("Creating new visit")

    # Cancel existing timer if any
    cancel_timer(state.timer_ref)

    # Create new visit
    visit_attrs = %{
      arrival_time: timestamp,
      first_snapshot_base64: snapshot
    }

    case %Visit{}
         |> Visit.create_changeset(visit_attrs)
         |> Repo.insert() do
      {:ok, visit} ->
        # Create detection record
        case create_detection(timestamp, confidence, snapshot, visit.id) do
          {:ok, detection} ->
            # Send arrival webhook
            Webhooks.send_arrival(visit)

            # Start timeout timer
            timer_ref = schedule_timeout_check()

            new_state = %{
              current_visit_id: visit.id,
              last_detection_at: timestamp,
              timer_ref: timer_ref
            }

            {:reply, {:ok, detection}, new_state}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end

      {:error, changeset} ->
        {:reply, {:error, changeset}, state}
    end
  end

  defp handle_existing_visit(visit_id, timestamp, confidence, snapshot, state) do
    # Cancel existing timer
    cancel_timer(state.timer_ref)

    # Get the visit
    visit = Repo.get!(Visit, visit_id)

    # Update visit with latest snapshot
    visit_attrs = %{last_snapshot_base64: snapshot}

    case visit
         |> Visit.update_changeset(visit_attrs)
         |> Repo.update() do
      {:ok, _updated_visit} ->
        # Create detection record
        case create_detection(timestamp, confidence, snapshot, visit_id) do
          {:ok, detection} ->
            # Restart timeout timer
            timer_ref = schedule_timeout_check()

            new_state = %{
              state
              | last_detection_at: timestamp,
                timer_ref: timer_ref
            }

            {:reply, {:ok, detection}, new_state}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end

      {:error, changeset} ->
        {:reply, {:error, changeset}, state}
    end
  end

  defp create_detection(timestamp, confidence, snapshot, visit_id) do
    attrs = %{
      timestamp: timestamp,
      confidence: confidence,
      snapshot_base64: snapshot,
      visit_id: visit_id
    }

    %Detection{}
    |> Detection.changeset(attrs)
    |> Repo.insert()
  end

  defp finalize_visit(visit_id, last_detection_time) do
    visit = Repo.get!(Visit, visit_id)
    departure_time = last_detection_time || DateTime.utc_now()

    attrs = %{
      departure_time: departure_time,
      last_snapshot_base64: visit.last_snapshot_base64
    }

    case visit
         |> Visit.end_changeset(attrs)
         |> Repo.update() do
      {:ok, completed_visit} ->
        Logger.info(
          "Visit #{visit_id} completed - Duration: #{completed_visit.duration_seconds}s"
        )

        # Send departure webhook
        Webhooks.send_departure(completed_visit)
        :ok

      {:error, changeset} ->
        Logger.error("Failed to finalize visit: #{inspect(changeset)}")
        {:error, changeset}
    end
  end

  defp schedule_timeout_check do
    Process.send_after(self(), :timeout_check, @session_timeout_ms)
  end

  defp cancel_timer(nil), do: :ok

  defp cancel_timer(timer_ref) do
    Process.cancel_timer(timer_ref)
    :ok
  end

  defp parse_timestamp(nil), do: nil

  defp parse_timestamp(timestamp) when is_binary(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end

  defp parse_timestamp(%DateTime{} = dt), do: dt

  defp parse_float(nil), do: nil
  defp parse_float(value) when is_float(value), do: value
  defp parse_float(value) when is_integer(value), do: value * 1.0

  defp parse_float(value) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> nil
    end
  end
end
