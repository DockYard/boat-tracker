import Leaflet, { canvas } from "leaflet";
// import "leaflet-rotatedmarker";
import "leaflet-canvas-markers";

L.Canvas.include({
  _updateCustomIconMarker: function (layer) {
    if (!this._drawing || layer._empty()) {
      return;
    }

    const p = layer._point;
    const ctx = this._ctx;
    const { options: {rotationAngle, width, height} } = layer;
    const h = Math.max(Math.round(height), 1);
    const w = Math.max(Math.round(width), 1);
    console.log(layer);

    this._layers[layer._leaflet_id] = layer;

    const theta = (rotationAngle * Math.PI) / 180;

    ctx.save();
    ctx.translate(p.x, p.y);
    ctx.rotate(theta);
    ctx.beginPath();
    ctx.moveTo(0, -h / 2);
    ctx.lineTo(-w / 2, h / 2);
    ctx.lineTo(w / 2, h / 2);
    ctx.closePath();
    this._fillStroke(ctx, layer);
    ctx.restore();
  },
});

const CustomIconMarker = L.CircleMarker.extend({
  _updatePath: function () {
    this._renderer._updateCustomIconMarker(this);
  },
});

export function interactiveMap(hook) {
  let divElement = hook.el;

  var map = Leaflet.map(divElement, { preferCanvas: true }).setView(
    [42.27, -70.997],
    14
  );

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

  const colorArrayToRgb = ([r, g, b]) => `rgb(${r}, ${g}, ${b})`;

  const colorLerp = ([s_r, s_g, s_b], [e_r, e_g, e_b], t) => {
    const lerp = (x, y, t) => Math.round(x + (y - x) * t);
    return colorArrayToRgb([
      lerp(s_r, e_r, t),
      lerp(s_g, e_g, t),
      lerp(s_b, e_b, t),
    ]);
  };

  const interpolateColors = (value) => {
    const config = [
      [0, [0, 0, 255]],
      [0.56, [0, 255, 255]],
      [1.13, [0, 255, 0]],
      [1.69, [255, 255, 0]],
      [2.25, [255, 0, 0]],
    ];

    for (let i = 0; i < config.length - 1; i++) {
      const [lowerBound, startColor] = config[i];
      const [upperBound, endColor] = config[i + 1];
      if (value >= lowerBound && value < upperBound) {
        const t = (value - lowerBound) / (upperBound - lowerBound);
        return colorLerp(startColor, endColor, t);
      }
    }

    return colorArrayToRgb(config[config.length - 1][1]);
  };

  window.addEventListener(`phx:add_current_markers`, (e) => {
    const markerBaseColor = interpolateColors(0);

    const canvasRenderer = L.canvas({ padding: 0.5 });

    const geojsonMarkerOptions = {
      radius: 0.5,
      fillColor: markerBaseColor,
      color: markerBaseColor,
      weight: 1,
      opacity: 1,
      fillOpacity: 1,
      filter: (_) => map.getZoom() >= 12,
      keyboard: false,
      renderer: canvasRenderer,
    };

    // const arrowIcon = (speed) => {
    //   const color = interpolateColors(speed);
    //   const svg = `
    //     <svg width="14px" height="14px" viewBox="0 0 14 14" version="1.1">
    //       <path style="stroke:none;fill-rule:evenodd;fill:${color};fill-opacity:1;" d="M 12.765625 7 L 8.375 10.636719 L 8.75 11.082031 L 14 6.695312 L 8.75 2.332031 L 8.375 2.777344 L 12.765625 6.417969 L 0 6.417969 L 0 7 Z M 12.765625 7 "/>
    //     </svg>`;

    //   return L.divIcon({
    //     html: svg,
    //     className: "",
    //     iconSize: [12, 8],
    //     iconAnchor: [6, 4],
    //   });
    // };

    L.geoJSON(e.detail.current_data, {
      pointToLayer: function (feature, latlng) {
        const { direction, speed } = feature.properties;

        if (speed == 0) {
          return undefined;
        }

        if (speed > 0 && speed < 0.05) {
          return L.circleMarker(latlng, geojsonMarkerOptions);
        }

        const color = interpolateColors(speed);

        return new CustomIconMarker(latlng, {
          ...geojsonMarkerOptions,
          rotationAngle: direction,
          width: 4,
          height: 8,
          fillColor: color,
          color: color,
        });
      },
    }).addTo(map);
  });
}
