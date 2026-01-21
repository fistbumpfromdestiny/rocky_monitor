defmodule RockyMonitor.Repo.Migrations.CreateCoreTables do
  use Ecto.Migration

  def change do
    # Create visits table
    create table(:visits) do
      add :arrival_time, :utc_datetime, null: false
      add :departure_time, :utc_datetime
      add :duration_seconds, :integer
      add :detection_count, :integer, default: 0
      add :first_snapshot_base64, :text
      add :last_snapshot_base64, :text
      add :status, :string, default: "active"

      timestamps()
    end

    create index(:visits, [:status])
    create index(:visits, [:arrival_time])

    # Create detections table
    create table(:detections) do
      add :timestamp, :utc_datetime, null: false
      add :confidence, :float, null: false
      add :snapshot_base64, :text
      add :visit_id, references(:visits, on_delete: :nilify_all)

      timestamps()
    end

    create index(:detections, [:timestamp])
    create index(:detections, [:visit_id])

    # Create daily_analytics table
    create table(:daily_analytics, primary_key: false) do
      add :date, :date, primary_key: true
      add :visit_count, :integer, default: 0
      add :total_duration_seconds, :integer, default: 0
      add :avg_visit_duration_seconds, :integer
      add :total_detections, :integer, default: 0
      add :longest_visit_seconds, :integer

      timestamps()
    end

    create unique_index(:daily_analytics, [:date])
  end
end
