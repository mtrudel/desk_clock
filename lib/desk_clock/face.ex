defmodule DeskClock.Face do
  @type t :: {module(), map()}

  @callback create(String.t(), String.t()) :: Face.t()
  @callback get_zone(atom(), Face.t()) :: String.t()
  @callback set_zone(atom(), String.t(), Face.t()) :: Face.t()
  @callback build_drawlist_for_time(DateTime.t(), Face.t()) :: {list(), Face.t()}

  def init(face_mod, upper_zone, lower_zone) do
    {face_mod, face_mod.create(upper_zone, lower_zone)}
  end

  def get_zone(subface, {face_mod, face_state}) do
    face_mod.get_zone(subface, face_state)
  end

  def set_zone(subface, direction, {face_mod, face_state}) do
    current_zone = face_mod.get_zone(subface, face_state)
    new_zone = DeskClock.Timezones.next_zone(current_zone, direction)
    {face_mod, face_mod.set_zone(subface, new_zone, face_state)}
  end

  def build_images_for_time(time, {face_mod, face_state}) do
    {drawlist, new_face_state} = face_mod.build_drawlist_for_time(time, face_state)

    images =
      drawlist
      |> Enum.map(fn {image, origin} ->
        {:ok, data} = ExPaint.render(image, ExPaint.FourBitGreyscaleRasterizer)
        size = ExPaint.Image.dimensions(image)
        ExPaint.destroy(image)
        {data, origin, size}
      end)

    {images, {face_mod, new_face_state}}
  end
end
