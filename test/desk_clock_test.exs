defmodule DeskClockTest do
  use ExUnit.Case
  doctest DeskClock

  test "greets the world" do
    assert DeskClock.hello() == :world
  end
end
