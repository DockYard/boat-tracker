import Leaflet from "leaflet";

export function interactiveMap(hook) {
  let divElement = hook.el;

  var map = Leaflet.map(divElement).setView([42.27, -70.997], 14);
  var polyline = Leaflet.polyline([], { color: "red" }).addTo(map);
  let trackCoordinates = [];

  Leaflet.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    maxZoom: 19,
    attribution: "© OpenStreetMap",
  }).addTo(map);

  var marker = L.marker([42.27, -70.997]).addTo(map);
  marker.bindPopup("Boat Node");

  window.addEventListener(`phx:track_coordinates`, (e) => {
    const { detail: { coordinates } } = e;

    trackCoordinates = coordinates;
  });

  window.addEventListener(`phx:marker_coordinates`, (e) => {
    const {
      detail: { latitude, longitude },
    } = e;

    marker.setLatLng({ lat: latitude, lng: longitude });
  });

  window.addEventListener(`phx:marker_position`, (e) => {
    const { detail: { position } } = e;

    const [latitude, longitude] = trackCoordinates[position];
    marker.setLatLng({ lat: latitude, lng: longitude });
    polyline.setLatLngs(trackCoordinates.slice(0, position));
  });

  window.addEventListener(`phx:map_view`, (e) => {
    map.setView([e.detail.latitude, e.detail.longitude], 14);
  });

  window.addEventListener(`phx:clear_polyline`, (_e) => {
    polyline.setLatLngs([]);
  });

  window.addEventListener(`phx:toggle_track`, (e) => {
    if (e.detail.value) {
      polyline.addTo(map);
    } else {
      polyline.remove();
    }
  });
}
