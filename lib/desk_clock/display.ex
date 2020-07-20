defmodule DeskClock.Display do
  @moduledoc """
  Responsible for managing a display & a face
  """

  use GenServer

  alias DeskClock.Face

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def update(time) do
    GenServer.call(__MODULE__, {:update, time})
  end

  def set_zone(zone, direction) do
    GenServer.call(__MODULE__, {:set_zone, zone, direction})
  end

  def set_contrast(constrast) do
    GenServer.call(__MODULE__, {:set_contrast, constrast})
  end

  def toggle_display() do
    GenServer.call(__MODULE__, :toggle_display)
  end

  def init(_args) do
    upper_zone = "Etc/UTC"
    lower_zone = "America/New_York"
    face_state = Face.init(DeskClock.Faces.Lazy, upper_zone, lower_zone)
    {:ok, device_pid} = SSD1322.start_link()
    SSD1322.contrast(device_pid, 128)

    {:ok,
     %{
       face_state: face_state,
       device_pid: device_pid,
       display_on: true
     }}
  end

  def handle_call({:update, time}, _from, %{display_on: true} = state) do
    {:reply, :ok, %{state | face_state: do_update(time, state)}}
  end

  def handle_call({:update, _time}, _from, %{display_on: false} = state) do
    {:reply, :ok, state}
  end

  def handle_call({:set_zone, subface, direction}, _from, state) do
    state = %{state | face_state: Face.set_zone(subface, direction, state[:face_state])}
    state = %{state | face_state: do_update(DateTime.utc_now(), state)}
    {:reply, :ok, state}
  end

  def handle_call({:set_contrast, contrast}, _from, %{device_pid: device_pid} = state) do
    SSD1322.contrast(device_pid, min(max(contrast, 0), 0xFF))
    {:reply, :ok, state}
  end

  def handle_call(:toggle_display, _from, %{display_on: true, device_pid: device_pid} = state) do
    SSD1322.display_off(device_pid)
    {:reply, :ok, %{state | display_on: false}}
  end

  def handle_call(:toggle_display, _from, %{display_on: false, device_pid: device_pid} = state) do
    SSD1322.display_on(device_pid)
    {:reply, :ok, %{state | display_on: true}}
  end

  def terminate(_reason, %{device_pid: device_pid}) do
    SSD1322.display_off(device_pid)
  end

  defp do_update(time, %{face_state: face_state, device_pid: device_pid}) do
    {images, face_state} = Face.build_images_for_time(time, face_state)

    images
    |> Enum.each(fn {data, origin, size} ->
      SSD1322.draw(device_pid, data, origin, size)
    end)

    face_state
  end
end
