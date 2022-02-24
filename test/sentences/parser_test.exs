defmodule BoatTrackerTest.Sentences.ParserTest do
  use ExUnit.Case

  alias BoatTracker.Sentences.{Parser, RMC}

  describe "Parse $GPRMC sentences" do
    test "parse valid sentences" do
      sentence_1 = "$GPRMC,081836,A,3751.65,S,14507.36,E,000.0,360.0,130998,011.3,E*62"
      sentence_2 = "$GPRMC,225446,A,4916.45,N,12311.12,W,000.5,054.7,191194,020.3,E*68"
      sentence_3 = "$GPRMC,220516,A,5133.82,N,00042.24,W,173.8,231.8,130694,004.2,W*70"

      assert Parser.parse(sentence_1) == %RMC{
               date: ~D[2009-09-13],
               latitude: -37.86083333333333,
               longitude: 145.12266666666667,
               magnetic_variation: 11.3,
               speed: 0.0,
               status: "A",
               time: ~T[08:18:36.000000],
               track_angle: 360.0
             }

      assert Parser.parse(sentence_2) == %RMC{
               date: ~D[2011-11-19],
               latitude: 49.274166666666666,
               longitude: -123.18533333333333,
               magnetic_variation: 20.3,
               speed: 0.5,
               status: "A",
               time: ~T[22:54:46.000000],
               track_angle: 54.7
             }

      assert Parser.parse(sentence_3) == %RMC{
               date: ~D[2006-06-13],
               latitude: 51.56366666666667,
               longitude: -0.7040000000000001,
               magnetic_variation: 4.2,
               speed: 173.8,
               status: "A",
               time: ~T[22:05:16.000000],
               track_angle: 231.8
             }
    end

    test "parse invalid sentences" do
      sentence_1 = "$GPRMC,081836,A,3751.65,S,14507.36,E,000.0,360.0,130998,011.3"
      sentence_2 = "GPRMC,220516,A,5133.82,N,00042.24,W,173.8,231.8,130694,004.2,W*70"
      sentence_3 = "Do you even sail?"

      refute Parser.parse(sentence_1)
      refute Parser.parse(sentence_2)
      refute Parser.parse(sentence_3)
    end
  end
end
