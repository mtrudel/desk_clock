defmodule DeskClock.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: DeskClock.Supervisor]
    children = [] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  def children(:host) do
    [
      # Children that only run on the host
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      DeskClock.Display,
      DeskClock.Movement,
      DeskClock.RotaryEncoder
    ]
  end

  def target() do
    Application.get_env(:desk_clock, :target)
  end
end
