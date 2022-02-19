defmodule BoatTracker.Sentences.Parser do
  alias BoatTracker.Sentences.RMC

  @rmc_content_size 12
  @time_size 6

  def parse("$GPRMC," <> content) do
    content_list = String.split(content, ",")

    if valid_content_size?(:rmc, content_list) do
      %RMC{
        time: parse_time(Enum.at(content_list, 0)),
        status: parse_string(Enum.at(content_list, 1))
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
end
