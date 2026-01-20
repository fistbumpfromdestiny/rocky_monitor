defmodule RockyMonitor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RockyMonitorWeb.Telemetry,
      RockyMonitor.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:rocky_monitor, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:rocky_monitor, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RockyMonitor.PubSub},
      # Start a worker by calling: RockyMonitor.Worker.start_link(arg)
      # {RockyMonitor.Worker, arg},
      # Start to serve requests, typically the last entry
      RockyMonitorWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RockyMonitor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RockyMonitorWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
