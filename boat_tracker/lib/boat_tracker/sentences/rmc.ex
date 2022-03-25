defmodule BoatTracker.Sentences.RMC do
  @moduledoc """
  Recommended minimum specific GPS/Transit data.

  $GPRMC,hhmmss.ss,A,llll.ll,a,yyyyy.yy,a,x.x,x.x,ddmmyy,x.x,a*hh
            1      2     3   4     5    6  7   8    9     10 11 12

  1    = UTC of position fix
  2    = Data status (A = OK, V = Navigation receiver warning)
  3    = Latitude of fix
  4    = N or S
  5    = Longitude of fix
  6    = E or W
  7    = Speed over ground in knots
  8    = Track made good in degrees True
  9    = UT date
  10   = Magnetic variation degrees (Easterly var. subtracts from true course)
  11   = E or W
  12   = Checksum
  """
  defstruct time: nil,
            status: nil,
            latitude: nil,
            longitude: nil,
            speed: nil,
            track_angle: nil,
            date: nil,
            magnetic_variation: nil
end
