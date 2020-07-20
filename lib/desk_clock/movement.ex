defmodule DeskClock.Movement do
  @moduledoc """
  Responsible for firing updates to the Display in such a way that the update
  calls return as close to second crossings as possible.
  """

  use Task, restart: :permanent

  require Logger

  alias DeskClock.Display

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(_arg) do
    next_tick(DateTime.utc_now(), 0)
  end

  def next_tick(time, avg_draw_time) do
    # Draw the time as passed in, and update the average time it takes to draw
    draw_start = System.monotonic_time()
    Display.update(time)
    draw_end = System.monotonic_time()
    avg_draw_time = div(4 * avg_draw_time + (draw_end - draw_start), 5)

    drawing_duration = System.convert_time_unit(draw_end - draw_start, :native, :millisecond)
    Logger.info("Drew #{time} at #{DateTime.utc_now()}, drawing took #{drawing_duration}")

    # It's possible that we took longer than a second to draw the time. Figure out if that's 
    # the case and build our next time from this by moving forward 1 second
    now = DateTime.utc_now()
    next_time = time |> later(now) |> DateTime.truncate(:second) |> Timex.shift(seconds: 1)

    # Figure out how long to sleep, taking into account the average delay to draw
    # We want to wake up 'avg_draw_time' ms before next_time, but if that 
    # time is in the past, then let's just wake up as soon as possible
    next_time
    |> Timex.shift(milliseconds: -System.convert_time_unit(avg_draw_time, :native, :millisecond))
    |> later(now)
    |> DateTime.diff(now, :milliseconds)
    |> Process.sleep()

    next_tick(next_time, avg_draw_time)
  end

  def later(time_a, time_b) do
    if Timex.after?(time_a, time_b), do: time_a, else: time_b
  end
end
