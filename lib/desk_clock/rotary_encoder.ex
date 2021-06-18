defmodule DeskClock.RotaryEncoder do
  @moduledoc """
  Responsible for updating the display based on an attached PEC11
  """

  use GenServer

  alias Circuits.GPIO
  alias DeskClock.Display

  # GPIO pins for a (quadrature trigger), b (quadrature direction), and z (button press)
  # These correspond to BCM XX pin numbers as described at https://pinout.xyz
  @a 26
  @b 19
  @z 13

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    {:ok, a} = GPIO.open(@a, :input)
    GPIO.set_interrupts(a, :rising)
    GPIO.set_pull_mode(a, :pullup)

    {:ok, b} = GPIO.open(@b, :input)
    GPIO.set_pull_mode(b, :pullup)

    {:ok, z} = GPIO.open(@z, :input)
    GPIO.set_interrupts(z, :both)
    GPIO.set_pull_mode(z, :pullup)

    {:ok, %{a: a, b: b, z: z, fresh_z: false}}
  end

  # Quadrature flipped; let's see which way we turned and if we're pushed down or not
  def handle_info({:circuits_gpio, @a, _time, 1}, %{b: b, z: z} = state) do
    zone = if GPIO.read(z) == 1, do: :upper_zone, else: :lower_zone
    direction = if GPIO.read(b) == 1, do: :next, else: :prev
    Display.set_zone(zone, direction)
    {:noreply, %{state | fresh_z: false}}
  end

  # z is being pushed, so set the 'fresh_z' flag
  def handle_info({:circuits_gpio, @z, _time, 0}, state) do
    {:noreply, %{state | fresh_z: true}}
  end

  # z is being released
  def handle_info({:circuits_gpio, @z, _time, 1}, %{fresh_z: fresh_z} = state) do
    # If fresh_z flag is still set, trigger our z button push action
    if fresh_z, do: Display.toggle_display()
    {:noreply, %{state | fresh_z: false}}
  end
end
