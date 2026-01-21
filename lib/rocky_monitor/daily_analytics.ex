defmodule RockyMonitor.DailyAnalytics do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:date, :date, autogenerate: false}
  schema "daily_analytics" do
    field :visit_count, :integer, default: 0
    field :total_duration_seconds, :integer, default: 0
    field :avg_visit_duration_seconds, :integer
    field :total_detections, :integer, default: 0
    field :longest_visit_seconds, :integer

    timestamps()
  end

  @doc false
  def changeset(analytics, attrs) do
    analytics
    |> cast(attrs, [
      :date,
      :visit_count,
      :total_duration_seconds,
      :avg_visit_duration_seconds,
      :total_detections,
      :longest_visit_seconds
    ])
    |> validate_required([:date])
  end
end
