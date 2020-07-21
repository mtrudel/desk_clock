defmodule DeskClock.Faces.NoSync do
  @moduledoc """
  A face that displays an 'NTP not synced message'
  """

  @behaviour DeskClock.Face

  alias ExPaint.{Color, Font}

  @impl DeskClock.Face
  def create(upper_zone, lower_zone) do
    %{
      label_font: Font.load("fixed7x14"),
      upper_zone: upper_zone,
      lower_zone: lower_zone,
      drawn: false
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
  def set_zone(_subface, _zone, state) do
    # Don't change zones since there's no UI for users to interact with
    state
  end

  @impl DeskClock.Face
  def build_drawlist_for_time(_time, %{drawn: false} = state) do
    {:ok, background} = ExPaint.create(256, 64)
    ExPaint.filled_rect(background, {0, 0}, {256, 64}, Color.black())

    text = draw_text("Not synchronized to NTP", state[:label_font])

    {[{background, {0, 0}}, {text, {44, 20}}], %{state | drawn: true}}
  end

  @impl DeskClock.Face
  def build_drawlist_for_time(_time, %{drawn: true} = state) do
    {[], state}
  end

  defp draw_text(text, font, {origin_x, _originy} = origin \\ {4, 0}) do
    {glyph_width, height} = Font.size(font)
    width = glyph_width * String.length(text) + origin_x

    # Pad width out to the next multiple of 4
    width = 4 + width + (4 - rem(width, 4))

    {:ok, image} = ExPaint.create(width, height)
    ExPaint.filled_rect(image, {0, 0}, {width, height}, Color.black())
    ExPaint.text(image, origin, font, text, Color.white())
    image
  end
end
