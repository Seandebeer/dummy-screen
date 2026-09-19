import React, { useEffect } from "react";
import L from "leaflet";
import {
  MapContainer, TileLayer, Marker, Polyline, Popup, useMap, useMapEvents,
} from "react-leaflet";
import "leaflet/dist/leaflet.css";

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
        paddingTopLeft: [36, 80], paddingBottomRight: [36, 220], animate: true,
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

export default function MapCanvas({
  center, zoom, origin, stops, me, puck, onMapClick, onStopMove, onStopRemove,
}) {
  const routePoints = origin ? [origin, ...stops.map((s) => s.pos)] : [];
  return (
    <MapContainer center={center} zoom={zoom} zoomControl={false} doubleClickZoom={false}
      style={{ height: "100%", width: "100%" }}>
      <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution="&copy; OpenStreetMap" />
      <ClickCatcher onClick={onMapClick} />
      <FitRoute points={routePoints} />
      <FlyToMe me={me} />
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
      {me && <Marker position={me} icon={meIcon} interactive={false} />}
      {puck && (
        <Marker position={[puck.lat, puck.lng]} icon={puckIcon(puck.bearing)}
          interactive={false} zIndexOffset={1000} />
      )}
    </MapContainer>
  );
}