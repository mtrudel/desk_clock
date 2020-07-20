defmodule DeskClock.Faces.Lazy do
  @moduledoc """
  A face that optimizes writes to be minimal on every pass
  """

  @behaviour DeskClock.Face

  alias ExPaint.{Color, Font}

  @impl DeskClock.Face
  def create(upper_zone, lower_zone) do
    %{
      label_font: Font.load("fixed6x12"),
      time_font: Font.load("Terminus22"),
      last_upper_time: nil,
      last_lower_time: nil,
      last_upper_label: nil,
      last_lower_label: nil,
      upper_zone: upper_zone,
      lower_zone: lower_zone,
      dirty_components: [:background]
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
    %{
      state
      | upper_zone: zone,
        dirty_components: state[:dirty_components] ++ [:upper_time, :upper_label]
    }
  end

  @impl DeskClock.Face
  def set_zone(:lower_zone, zone, state) do
    %{
      state
      | lower_zone: zone,
        dirty_components: state[:dirty_components] ++ [:lower_time, :lower_label]
    }
  end

  @impl DeskClock.Face
  def build_drawlist_for_time(%DateTime{} = time, state) do
    upper_time_as_time = Timex.Timezone.convert(time, state[:upper_zone])
    upper_time = formatted_time(upper_time_as_time)
    upper_label = formatted_label(upper_time_as_time)
    lower_time_as_time = Timex.Timezone.convert(time, state[:lower_zone])
    lower_time = formatted_time(lower_time_as_time)
    lower_label = formatted_label(lower_time_as_time)

    state = %{
      state
      | dirty_components:
          state[:dirty_components] ++ [:upper_time, :lower_time, :upper_label, :lower_label]
    }

    {build_dirty_components(upper_time, lower_time, upper_label, lower_label, state),
     %{
       state
       | last_upper_time: upper_time,
         last_lower_time: lower_time,
         last_upper_label: upper_label,
         last_lower_label: lower_label,
         dirty_components: []
     }}
  end

  defp build_dirty_components(upper_time, lower_time, upper_label, lower_label, state) do
    state[:dirty_components]
    |> Enum.flat_map(
      &build_component(&1, upper_time, lower_time, upper_label, lower_label, state)
    )
  end

  defp build_component(:background, _upper_time, _lower_time, _upper_label, _lower_label, _state) do
    {:ok, image} = ExPaint.create(256, 64)
    ExPaint.filled_rect(image, {0, 0}, {256, 64}, Color.black())
    [{image, {0, 0}}]
  end

  defp build_component(:upper_label, _upper_time, _lower_time, upper_label, _lower_label, state) do
    draw_label(upper_label, state[:last_upper_label], state[:label_font], {8, 8})
  end

  defp build_component(:lower_label, _upper_time, _lower_time, _upper_label, lower_label, state) do
    draw_label(lower_label, state[:last_lower_label], state[:label_font], {8, 40})
  end

  defp build_component(:upper_time, upper_time, _lower_time, _upper_label, _lower_label, state) do
    draw_time(upper_time, state[:last_upper_time], state[:time_font], {40, 1})
  end

  defp build_component(:lower_time, _upper_time, lower_time, _upper_label, _lower_label, state) do
    draw_time(lower_time, state[:last_lower_time], state[:time_font], {40, 33})
  end

  defp draw_label(label, last_label, font, {x, y}) do
    last_label =
      case last_label do
        nil -> String.duplicate("X", String.length(label))
        other -> other
      end

    case label do
      ^last_label -> []
      other -> [{draw_text(other, font, 0), {x, y}}]
    end
  end

  defp draw_time(time, last_time, font, {x, y}) do
    last_time =
      case last_time do
        nil -> String.duplicate("X", String.length(time))
        other -> other
      end

    {glyph_width, _height} = Font.size(font)

    first_changed_character =
      Enum.zip(String.graphemes(time), String.graphemes(last_time))
      |> Enum.with_index()
      |> Enum.find(fn {{old, new}, _index} -> old != new end)

    case first_changed_character do
      nil ->
        []

      {_, index} ->
        substring_origin_x = x + glyph_width * index
        aligned_substring_origin_x = substring_origin_x - rem(substring_origin_x, 4)

        {slice_to_draw, x_offset} =
          case substring_origin_x - aligned_substring_origin_x do
            0 -> {index..-1, 0}
            offset when offset > 0 -> {(index - 1)..-1, offset - glyph_width}
          end

        image = time |> String.slice(slice_to_draw) |> draw_text(font, x_offset)
        [{image, {aligned_substring_origin_x, y}}]
    end
  end

  defp draw_text(text, font, x_offset) do
    {glyph_width, height} = Font.size(font)
    width = x_offset + glyph_width * String.length(text)

    # Pad width out to the next multiple of 4
    width = width + (4 - rem(width, 4))

    {:ok, image} = ExPaint.create(width, height)
    ExPaint.filled_rect(image, {0, 0}, {width, height}, Color.black())
    ExPaint.text(image, {x_offset, 0}, font, text, Color.white())
    image
  end

  defp formatted_time(time) do
    Timex.format!(time, "{ISOdate}T{h24}:{m}:{s}")
  end

  defp formatted_label(time) do
    time
    |> Timex.format!("{Zabbr}")
    |> String.pad_leading(4)
  end
end
