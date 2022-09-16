defmodule BoatVisualizer.Coordinates do
  @default_path "priv/external/"

  def get_coordinates(filename) do
    {:ok, rows} = File.read(@default_path <> filename)

    rows
    |> String.split("\n", trim: true)
    |> Enum.drop(1)
    |> Enum.map(
      &(&1
        |> String.split(",")
        |> List.to_tuple()
        |> then(fn {time, longitude, latitude} ->
          {NaiveDateTime.from_iso8601!(time), String.to_float(longitude),
           String.to_float(latitude)}
        end))
    )
  end

  def get_center(coordinates) do
    longitudes = Enum.map(coordinates, fn {_, longitude, _} -> longitude end)
    latitudes = Enum.map(coordinates, fn {_, _, latitude} -> latitude end)

    min_longitude = Enum.min(longitudes)
    max_longitude = Enum.max(longitudes)

    min_latitude = Enum.min(latitudes)
    max_latitude = Enum.max(latitudes)

    {(min_longitude + max_longitude) / 2, (min_latitude + max_latitude) / 2}
  end
end
