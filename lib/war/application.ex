defmodule War.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      WarWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: War.PubSub},
      # Start the Endpoint (http/https)
      WarWeb.Endpoint,
      # Start a worker by calling: War.Worker.start_link(arg)
      # {War.Worker, arg}
      {DynamicSupervisor,
       strategy: :one_for_one, restart: :temporary, name: War.DynamicGameServerSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: War.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    WarWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
