defmodule BoatTracker.Sentences.Parser do
  alias BoatTracker.Sentences.RMC

  @rmc_content_size 11
  @time_size 6

  def parse("$GPRMC," <> content) do
    content_list = String.split(content, ",")

    if valid_content_size?(:rmc, content_list) do
      %RMC{
        time: parse_time(Enum.at(content_list, 0)),
        status: parse_string(Enum.at(content_list, 1)),
        latitude: parse_latitude(Enum.at(content_list, 2), Enum.at(content_list, 3)),
        longitude: parse_longitude(Enum.at(content_list, 4), Enum.at(content_list, 5)),
        speed: parse_float(Enum.at(content_list, 6))
      }
    end
  end

  defp valid_content_size?(:rmc, content), do: Enum.count(content) == @rmc_content_size

  defp parse_time(time) when byte_size(time) < @time_size, do: nil

  defp parse_time(time) do
    time
    |> String.split(".")
    |> parse_hours_minutes_seconds_ms()
  end

  defp parse_hours_minutes_seconds_ms([<<main::binary-size(@time_size)>>]),
    do: parse_hours_minutes_seconds_ms([main, "0"])

  defp parse_hours_minutes_seconds_ms([<<main::binary-size(@time_size)>>, millis]) do
    {ms, _} = Integer.parse(millis)
    {h, _} = Integer.parse(String.slice(main, 0, 2))
    {m, _} = Integer.parse(String.slice(main, 2, 2))
    {s, _} = Integer.parse(String.slice(main, 4, 2))
    {:ok, time} = Time.new(h, m, s, ms)

    time
  end

  defp parse_hours_minutes_seconds_ms(_), do: nil

  defp parse_string(""), do: nil
  defp parse_string(value), do: value

  defp parse_latitude("", ""), do: nil

  defp parse_latitude(string, bearing) do
    {deg, _} =
      string
      |> String.slice(0, 2)
      |> Float.parse()

    {min, _} =
      string
      |> String.slice(2, 100)
      |> Float.parse()

    latitude_to_decimal_degrees(deg, min, bearing)
  end

  defp latitude_to_decimal_degrees(degrees, minutes, "N"), do: degrees + minutes / 60.0
  defp latitude_to_decimal_degrees(degrees, minutes, "S"), do: (degrees + minutes / 60.0) * -1.0

  defp parse_longitude("", ""), do: nil

  defp parse_longitude(string, bearing) do
    {deg, _} =
      string
      |> String.slice(0, 3)
      |> Float.parse()

    {min, _} =
      string
      |> String.slice(3, 100)
      |> Float.parse()

    longitude_to_decimal_degrees(deg, min, bearing)
  end

  defp longitude_to_decimal_degrees(degrees, minutes, "E"), do: degrees + minutes / 60.0
  defp longitude_to_decimal_degrees(degrees, minutes, "W"), do: (degrees + minutes / 60.0) * -1.0

  defp parse_float(""), do: nil

  defp parse_float(value) do
    value
    |> Float.parse()
    |> elem(0)
  end
end
