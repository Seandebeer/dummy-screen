import React, { useEffect } from "react";
import L from "leaflet";
import {
  MapContainer, TileLayer, Marker, Polyline, Popup, useMap, useMapEvents,
} from "react-leaflet";
import "leaflet/dist/leaflet.css";

// basemaps: street map, satellite imagery (Esri) and terrain (OpenTopoMap)
const LAYERS = {
  map: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
  satellite: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
  terrain: "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
};
const LAYER_ATTR = {
  map: "&copy; OpenStreetMap",
  satellite: "Imagery &copy; Esri",
  terrain: "&copy; OpenTopoMap",
};
// place + road labels drawn over the satellite imagery, like Google's hybrid view
const SAT_LABELS = "https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}";

// numbered stop pin (draggable), origin dot, "my location" pulse,
// and the moving navigation puck with a heading arrow
const stopIcon = (n) => L.divIcon({
  className: "",
  html: `<div style="width:24px;height:24px;border-radius:50%;background:#fff;border:3px solid #FF3B30;display:flex;align-items:center;justify-content:center;font:600 11px/1 -apple-system,'Helvetica Neue',sans-serif;color:#FF3B30;box-shadow:0 1px 4px rgba(0,0,0,.4)">${n}</div>`,
  iconSize: [24, 24],
  iconAnchor: [12, 12],
});

const originIcon = L.divIcon({
  className: "",
  html: `<div style="width:18px;height:18px;border-radius:50%;background:#0A84FF;border:3px solid #fff;box-shadow:0 1px 5px rgba(0,0,0,.45)"></div>`,
  iconSize: [18, 18],
  iconAnchor: [9, 9],
});

const meIcon = L.divIcon({
  className: "",
  html: `<span class="marker-pulse" style="display:block;width:14px;height:14px;border-radius:50%;background:#0A84FF;border:2px solid #fff;box-shadow:0 0 0 4px rgba(10,132,255,.3)"></span>`,
  iconSize: [14, 14],
  iconAnchor: [7, 7],
});

const puckIcon = (deg) => L.divIcon({
  className: "",
  html: `<div style="width:30px;height:30px;position:relative">
    <div style="position:absolute;inset:0;transform:rotate(${deg}deg);transform-origin:50% 50%">
      <span style="position:absolute;left:50%;top:-2px;transform:translateX(-50%);width:0;height:0;border-left:5px solid transparent;border-right:5px solid transparent;border-bottom:8px solid #0A84FF;filter:drop-shadow(0 0 2px rgba(0,0,0,.4))"></span>
    </div>
    <span style="position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);width:16px;height:16px;border-radius:50%;background:#0A84FF;border:3px solid #fff;box-shadow:0 1px 5px rgba(0,0,0,.5)"></span>
  </div>`,
  iconSize: [30, 30],
  iconAnchor: [15, 15],
});

// Google-style red place pin for search results
const placeIcon = L.divIcon({
  className: "",
  html: `<div style="width:26px;height:38px;filter:drop-shadow(0 2px 3px rgba(0,0,0,.4))"><svg viewBox="0 0 26 38" width="26" height="38"><path fill="#EA4335" d="M13 0C5.8 0 0 5.8 0 13c0 9.6 13 25 13 25s13-15.4 13-25C26 5.8 20.2 0 13 0z"/><circle cx="13" cy="13" r="4.6" fill="#fff"/></svg></div>`,
  iconSize: [26, 38],
  iconAnchor: [13, 38],
});

function ClickCatcher({ onClick }) {
  useMapEvents({ click: (e) => onClick([e.latlng.lat, e.latlng.lng]) });
  return null;
}

function FitRoute({ points }) {
  const map = useMap();
  useEffect(() => {
    if (points.length === 1) map.setView(points[0], 14);
    else if (points.length > 1) {
      map.fitBounds(L.latLngBounds(points), {
        paddingTopLeft: [36, 130], paddingBottomRight: [36, 220], animate: true,
      });
    }
  }, [map, points.length]);
  return null;
}

function FlyToMe({ me }) {
  const map = useMap();
  useEffect(() => { if (me) map.flyTo(me, 15, { duration: 0.8 }); }, [map, me]);
  return null;
}

// a search result selection flies the map to the place and opens its pin
function FlyToPlace({ place }) {
  const map = useMap();
  useEffect(() => {
    if (!place) return;
    map.flyTo(place.pos, 15, { duration: 0.8 });
  }, [map, place]);
  return null;
}

function ZoomButtons() {
  const map = useMap();
  return (
    <div className="absolute top-1/2 right-2 z-[500] flex -translate-y-1/2 flex-col overflow-hidden rounded-xl border border-white/15 bg-black/75 text-white backdrop-blur">
      <button onClick={() => map.zoomIn()} aria-label="Zoom in"
        className="px-2.5 py-1.5 text-[15px] font-semibold leading-none active:bg-white/10">+</button>
      <button onClick={() => map.zoomOut()} aria-label="Zoom out"
        className="border-t border-white/15 px-2.5 py-1.5 text-[15px] font-semibold leading-none active:bg-white/10">&minus;</button>
    </div>
  );
}

export default function MapCanvas({
  center, zoom, layer = "map", origin, stops, me, puck, place, onPlaceRoute,
  onMapClick, onStopMove, onStopRemove,
}) {
  const routePoints = origin ? [origin, ...stops.map((s) => s.pos)] : [];
  return (
    <MapContainer center={center} zoom={zoom} zoomControl={false} doubleClickZoom={false} attributionControl={false}
      style={{ height: "100%", width: "100%" }}>
      <TileLayer key={layer} url={LAYERS[layer] || LAYERS.map}
        attribution={LAYER_ATTR[layer] || LAYER_ATTR.map} />
      {layer === "satellite" && (
        <TileLayer url={SAT_LABELS} attribution="" />
      )}
      <ClickCatcher onClick={onMapClick} />
      <FitRoute points={routePoints} />
      <FlyToMe me={me} />
      <FlyToPlace place={place} />
      <ZoomButtons />
      <Polyline positions={routePoints}
        pathOptions={{ color: "#0A84FF", weight: 5, opacity: 0.85 }} />
      {origin && <Marker position={origin} icon={originIcon} interactive={false} zIndexOffset={200} />}
      {stops.map((s, i) => (
        <Marker key={s.id} position={s.pos} icon={stopIcon(i + 1)} draggable
          eventHandlers={{ dragend: (e) => onStopMove(s.id, [e.target.getLatLng().lat, e.target.getLatLng().lng]) }}>
          <Popup>
            <button onClick={() => onStopRemove(s.id)}
              className="rounded-md bg-red-500/90 px-2.5 py-1.5 text-[11px] font-semibold text-white">
              Remove stop
            </button>
          </Popup>
        </Marker>
      ))}
      {place && (
        <Marker position={place.pos} icon={placeIcon} zIndexOffset={400}>
          <Popup>
            <div className="max-w-[190px]">
              <div className="text-[12px] font-semibold text-black">{place.name}</div>
              <div className="mt-0.5 text-[10px] leading-snug text-black/60">{place.address}</div>
              <button onClick={() => onPlaceRoute(place.pos)}
                className="mt-2 rounded-md bg-[#0A84FF] px-2.5 py-1.5 text-[11px] font-semibold text-white">
                {origin ? "Add as stop" : "Set as start"}
              </button>
            </div>
          </Popup>
        </Marker>
      )}
      {me && <Marker position={me} icon={meIcon} interactive={false} />}
      {puck && (
        <Marker position={[puck.lat, puck.lng]} icon={puckIcon(puck.bearing)}
          interactive={false} zIndexOffset={1000} />
      )}
    </MapContainer>
  );
}