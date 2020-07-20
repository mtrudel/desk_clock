defmodule DeskClock.Timezones do
  @moduledoc """
  Database of ordered timezones
  """
  @zones [
    "Pacific/Honolulu",
    "America/Juneau",
    "America/Los_Angeles",
    "America/Phoenix",
    "America/Chicago",
    "America/New_York",
    "America/Halifax",
    "America/St_Johns",
    "Etc/UTC",
    "Europe/London",
    "Europe/Amsterdam",
    "Europe/Riga",
    "Asia/Karachi",
    "Asia/Shanghai",
    "Australia/Perth",
    "Australia/Darwin",
    "Australia/Sydney",
    "Pacific/Auckland"
  ]

  def next_zone(zone, :next) do
    do_next_zone(zone, 1)
  end

  def next_zone(zone, :prev) do
    do_next_zone(zone, -1)
  end

  defp do_next_zone(zone, direction) do
    idx =
      @zones
      |> Enum.find_index(&(&1 == zone))
      |> Kernel.+(direction)
      |> Integer.mod(length(@zones))

    Enum.at(@zones, idx)
  end
end
