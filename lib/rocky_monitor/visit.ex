defmodule RockyMonitor.Visit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "visits" do
    field :arrival_time, :utc_datetime
    field :departure_time, :utc_datetime
    field :duration_seconds, :integer
    field :detection_count, :integer, default: 0
    field :first_snapshot_base64, :string
    field :last_snapshot_base64, :string
    field :status, :string, default: "active"

    has_many :detections, RockyMonitor.Detection

    timestamps()
  end

  @doc false
  def create_changeset(visit, attrs) do
    visit
    |> cast(attrs, [:arrival_time, :first_snapshot_base64])
    |> validate_required([:arrival_time])
    |> put_change(:status, "active")
    |> put_change(:detection_count, 1)
  end

  @doc false
  def update_changeset(visit, attrs) do
    visit
    |> cast(attrs, [:last_snapshot_base64])
    |> increment_detection_count()
  end

  @doc false
  def end_changeset(visit, attrs) do
    visit
    |> cast(attrs, [:departure_time, :last_snapshot_base64])
    |> validate_required([:departure_time])
    |> put_change(:status, "completed")
    |> calculate_duration()
  end

  defp increment_detection_count(changeset) do
    case get_field(changeset, :detection_count) do
      nil -> put_change(changeset, :detection_count, 1)
      count -> put_change(changeset, :detection_count, count + 1)
    end
  end

  defp calculate_duration(changeset) do
    arrival = get_field(changeset, :arrival_time)
    departure = get_change(changeset, :departure_time)

    case {arrival, departure} do
      {%DateTime{} = arr, %DateTime{} = dep} ->
        duration = DateTime.diff(dep, arr, :second)
        put_change(changeset, :duration_seconds, duration)

      _ ->
        changeset
    end
  end
end
