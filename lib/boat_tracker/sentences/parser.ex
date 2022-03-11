defmodule BoatTracker.Sentences.Parser do
  @moduledoc """
  NMEA sentences parser module.
  """
  alias BoatTracker.Sentences.RMC

  @rmc_content_size 11
  @time_size 6
  @date_size 6

  @doc """
  Parses a NMEA sentence into a struct.

  ## Examples

    iex> BoatTracker.Sentences.Parser.parse("$GPRMC,220516,A,5133.82,N,00042.24,W,173.8,231.8,130694,004.2,W*70")
    %BoatTracker.Sentences.RMC{
      date: ~D[2006-06-13],
      latitude: 51.56366666666667,
      longitude: -0.7040000000000001,
      magnetic_variation: 4.2,
      speed: 173.8,
      status: "A",
      time: ~T[22:05:16.000000],
      track_angle: 231.8
    }
  """
  @spec parse(String.t()) :: RMC.t() | nil
  def parse("$GPRMC," <> content) do
    content_list = String.split(content, ",")

    if valid_content_size?(:rmc, content_list) do
      %RMC{
        time: parse_time(Enum.at(content_list, 0)),
        status: parse_string(Enum.at(content_list, 1)),
        latitude: parse_latitude(Enum.at(content_list, 2), Enum.at(content_list, 3)),
        longitude: parse_longitude(Enum.at(content_list, 4), Enum.at(content_list, 5)),
        speed: parse_float(Enum.at(content_list, 6)),
        track_angle: parse_float(Enum.at(content_list, 7)),
        date: parse_date(Enum.at(content_list, 8)),
        magnetic_variation: parse_float(Enum.at(content_list, 9))
      }
    end
  end

  def parse(_invalid_sentence), do: nil

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
    {deg, _} = Float.parse(String.slice(string, 0, 2))
    {min, _} = Float.parse(String.slice(string, 2, 100))
    latitude_to_decimal_degrees(deg, min, bearing)
  end

  defp latitude_to_decimal_degrees(degrees, minutes, "N"), do: degrees + minutes / 60.0
  defp latitude_to_decimal_degrees(degrees, minutes, "S"), do: (degrees + minutes / 60.0) * -1.0

  defp parse_longitude("", ""), do: nil

  defp parse_longitude(string, bearing) do
    {deg, _} = Float.parse(String.slice(string, 0, 3))
    {min, _} = Float.parse(String.slice(string, 3, 100))
    longitude_to_decimal_degrees(deg, min, bearing)
  end

  defp longitude_to_decimal_degrees(degrees, minutes, "E"), do: degrees + minutes / 60.0
  defp longitude_to_decimal_degrees(degrees, minutes, "W"), do: (degrees + minutes / 60.0) * -1.0

  defp parse_float(""), do: nil

  defp parse_float(value) do
    {float, _} = Float.parse(value)

    float
  end

  defp parse_date(<<raw_date::binary-size(@date_size)>>) do
    {day, _} = Integer.parse(String.slice(raw_date, 0, 2))
    {month, _} = Integer.parse(String.slice(raw_date, 2, 2))
    {year, _} = Integer.parse("20" <> String.slice(raw_date, 2, 2))
    {:ok, date} = Date.new(year, month, day)

    date
  end

  defp parse_date(_raw_date), do: nil
end
