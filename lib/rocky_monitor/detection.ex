defmodule RockyMonitor.Detection do
  use Ecto.Schema
  import Ecto.Changeset

  schema "detections" do
    field :timestamp, :utc_datetime
    field :confidence, :float
    field :snapshot_base64, :string

    belongs_to :visit, RockyMonitor.Visit

    timestamps()
  end

  @doc false
  def changeset(detection, attrs) do
    detection
    |> cast(attrs, [:timestamp, :confidence, :snapshot_base64, :visit_id])
    |> validate_required([:timestamp, :confidence])
    |> validate_number(:confidence, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
  end
end
