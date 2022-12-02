import Leaflet from "leaflet";
import "leaflet-rotatedmarker";

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
    const {
      detail: { coordinates },
    } = e;

    trackCoordinates = coordinates;
  });

  window.addEventListener(`phx:marker_coordinates`, (e) => {
    const {
      detail: { latitude, longitude },
    } = e;

    marker.setLatLng({ lat: latitude, lng: longitude });
  });

  window.addEventListener(`phx:marker_position`, (e) => {
    const {
      detail: { position },
    } = e;

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

  window.addEventListener(`phx:add_current_markers`, (e) => {
    const geojsonMarkerOptions = {
      radius: 2,
      fillColor: "#ff7800",
      color: "#000",
      weight: 1,
      opacity: 1,
      fillOpacity: 0.8,
    };

    // var myIcon = L.icon({
    //   iconUrl: "/images/arrow_sdf.png",
    //   iconSize: [100, 100],
    //   iconAnchor: [50, 50],
    //   popupAnchor: [0, 0],
    // });

    const svgIcon = L.divIcon({
      html: `
      <svg
        width="4"
        height="8"
        viewBox="0 0 100 100"
        version="1.1"
        preserveAspectRatio="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path d="M0 0 L50 100 L100 0 Z" fill="#7A8BE7"></path>
      </svg>`,
      className: "",
      iconSize: [4, 8],
      iconAnchor: [2, 4],
    });

    L.geoJSON(e.detail.current_data, {
      pointToLayer: function (feature, latlng) {
        return L.marker(latlng, {
          icon: svgIcon,
          rotationAngle: feature.properties.direction,
        });
        return L.circleMarker(latlng, geojsonMarkerOptions);
      },
    }).addTo(map);
  });
}
