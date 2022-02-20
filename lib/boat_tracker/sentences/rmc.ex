defmodule BoatTracker.Sentences.RMC do
  defstruct time: nil,
            status: nil,
            latitude: nil,
            longitude: nil,
            speed: nil,
            track_angle: nil,
            date: nil,
            magnetic_variation: nil
end
