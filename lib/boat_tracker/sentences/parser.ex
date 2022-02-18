defmodule BoatTracker.Sentences.Parser do
  alias BoatTracker.Sentences.RMC

  @rmc_content_size 12

  def parse("$GPRMC," <> content) do
    content_list = String.split(content, ",")

    if valid_content_size?(:rmc, content_list) do
      %RMC{}
    end
  end

  defp valid_content_size?(:rmc, content), do: Enum.count(content) == @rmc_content_size
end
