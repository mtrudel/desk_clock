defmodule DeskClock.Faces.Basic do
  @moduledoc """
  A simple face that doesn't try to be at all clever about drawing, doing the whole
  screen on every pass
  """

  @behaviour DeskClock.Face

  alias ExPaint.{Color, Font}

  @impl DeskClock.Face
  def create(upper_zone, lower_zone) do
    %{
      label_font: Font.load("Helvetica11"),
      time_font: Font.load("Terminus22"),
      upper_zone: upper_zone,
      lower_zone: lower_zone
    }
  end

  @impl DeskClock.Face
  def get_zone(:upper_zone, state) do
    state[:upper_zone]
  end

  @impl DeskClock.Face
  def get_zone(:lower_zone, state) do
    state[:lower_zone]
  end

  @impl DeskClock.Face
  def set_zone(:upper_zone, zone, state) do
    %{state | upper_zone: zone}
  end

  @impl DeskClock.Face
  def set_zone(:lower_zone, zone, state) do
    %{state | lower_zone: zone}
  end

  @impl DeskClock.Face
  def build_drawlist_for_time(%DateTime{} = time, state) do
    {[
       draw_background(),
       draw_upper_label(time, state[:upper_zone], state[:label_font]),
       draw_upper_time(time, state[:upper_zone], state[:time_font]),
       draw_lower_label(time, state[:lower_zone], state[:label_font]),
       draw_lower_time(time, state[:lower_zone], state[:time_font])
     ], state}
  end

  defp draw_background do
    {:ok, image} = ExPaint.create(256, 64)
    ExPaint.filled_rect(image, {0, 0}, {256, 64}, Color.black())
    {image, {0, 0}}
  end

  defp draw_upper_label(time, zone, font) do
    {draw_label(time, zone, font), {4, 8}}
  end

  defp draw_lower_label(time, zone, font) do
    {draw_label(time, zone, font), {4, 40}}
  end

  defp draw_upper_time(time, zone, font) do
    {draw_time(time, zone, font), {40, 1}}
  end

  defp draw_lower_time(time, zone, font) do
    {draw_time(time, zone, font), {40, 33}}
  end

  defp draw_label(time, zone, font) do
    time
    |> Timex.Timezone.convert(zone)
    |> Timex.format!("{Zabbr}")
    |> draw_text(font)
  end

  defp draw_time(time, zone, font) do
    time
    |> Timex.Timezone.convert(zone)
    |> Timex.format!("{ISOdate}T{h24}:{m}:{s}")
    |> draw_text(font)
  end

  defp draw_text(text, font) do
    {glyph_width, height} = Font.size(font)
    width = glyph_width * String.length(text)
    width = width + (4 - rem(width, 4))
    {:ok, image} = ExPaint.create(width, height)
    ExPaint.filled_rect(image, {0, 0}, {width, height}, Color.black())
    ExPaint.text(image, {0, 0}, font, text, Color.white())
    image
  end
end
