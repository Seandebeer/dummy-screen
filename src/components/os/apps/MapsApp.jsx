import React, { useState, useEffect, useMemo, useRef, useCallback } from "react";
import { Crosshair, Pause, Play, RotateCcw, Trash2 } from "lucide-react";
import MapCanvas from "./maps/MapCanvas";
import {
  buildRoute, positionAt, compass, turnName, fmtDist, fmtTime,
} from "@/lib/routeMath";

const SPEEDS = [
  { label: "1×", mult: 1 },
  { label: "8×", mult: 8 },
  { label: "32×", mult: 32 },
];
const BASE_SPEED = 50 / 3.6; // simulated 50 km/h in m/s

export default function MapsApp() {
  const [origin, setOrigin] = useState(null); // [lat, lng]
  const [stops, setStops] = useState([]); // { id, pos }
  const [me, setMe] = useState(null);
  const [locating, setLocating] = useState(false);
  const [playing, setPlaying] = useState(false);
  const [dist, setDist] = useState(0);
  const [speedIdx, setSpeedIdx] = useState(1);
  const idRef = useRef(0);

  const points = useMemo(
    () => (origin ? [origin, ...stops.map((s) => s.pos)] : []),
    [origin, stops]
  );
  const route = useMemo(() => (points.length >= 2 ? buildRoute(points) : null), [points]);
  const speedMs = BASE_SPEED * SPEEDS[speedIdx].mult;
  const arrived = !!route && dist >= route.total;

  // advance the simulation while playing
  useEffect(() => {
    if (!playing || !route) return;
    let raf;
    let last = performance.now();
    const tick = (now) => {
      const dt = (now - last) / 1000;
      last = now;
      setDist((d) => Math.min(d + dt * speedMs, route.total));
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [playing, route, speedMs]);

  // clamp + stop when the route ends (or shrinks from edits)
  useEffect(() => {
    if (route && dist > route.total) setDist(route.total);
  }, [route, dist]);
  useEffect(() => {
    if (playing && arrived) setPlaying(false);
  }, [playing, arrived]);

  const onMapClick = useCallback((pos) => {
    setDist(0);
    if (!origin) setOrigin(pos);
    else setStops((s) => [...s, { id: ++idRef.current, pos }]);
  }, [origin]);

  const onStopMove = useCallback((id, pos) => {
    setStops((s) => s.map((w) => (w.id === id ? { ...w, pos } : w)));
  }, []);

  const onStopRemove = useCallback((id) => {
    setStops((s) => s.filter((w) => w.id !== id));
  }, []);

  const locate = () => {
    if (!navigator.geolocation) return;
    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      (p) => {
        const pos = [p.coords.latitude, p.coords.longitude];
        setMe(pos);
        setLocating(false);
        if (!origin) setOrigin(pos);
      },
      () => setLocating(false),
      { enableHighAccuracy: true, timeout: 8000 }
    );
  };

  const clearAll = () => {
    setOrigin(null);
    setStops([]);
    setDist(0);
    setPlaying(false);
  };

  const togglePlay = () => {
    if (!route) return;
    if (!playing && arrived) setDist(0);
    setPlaying((p) => !p);
  };

  const pos = route ? positionAt(route, dist) : null;
  const seg = pos ? route.segments[pos.segIndex] : null;
  const instruction = !route
    ? ""
    : arrived
      ? "You have arrived"
      : pos.segIndex === 0
        ? `Head ${compass(seg.bearing)}`
        : `${turnName(seg.turnDelta)}, then head ${compass(seg.bearing)}`;

  const remaining = route ? route.total - dist : 0;
  const eta = remaining / speedMs;
  const nextStop = pos && pos.segIndex < stops.length
    ? `Stop ${pos.segIndex + 1} in ${fmtDist(pos.segRemaining)}`
    : "";
  const center = origin || me || [-26.2041, 28.0473];

  return (
    <div className="relative h-full w-full bg-black">
      <MapCanvas center={center} zoom={13} origin={origin} stops={stops} me={me}
        puck={route && dist > 0 ? pos : null}
        onMapClick={onMapClick} onStopMove={onStopMove} onStopRemove={onStopRemove} />

      {/* top bar */}
      <div className="pointer-events-none absolute inset-x-0 top-0 z-[1000] flex items-start justify-between p-2">
        <div className="rounded-full border border-white/10 bg-black/80 px-3 py-1.5 text-[12px] font-semibold text-white backdrop-blur">
          Maps
        </div>
        <div className="flex gap-1.5">
          <button onClick={locate} disabled={locating}
            className="pointer-events-auto rounded-full border border-white/10 bg-black/80 p-2 text-white/90 backdrop-blur disabled:opacity-50">
            <Crosshair size={14} className={locating ? "animate-spin" : ""} />
          </button>
          {(origin || stops.length > 0) && (
            <button onClick={clearAll}
              className="pointer-events-auto rounded-full border border-white/10 bg-black/80 p-2 text-white/90 backdrop-blur">
              <Trash2 size={14} />
            </button>
          )}
        </div>
      </div>

      {/* hints */}
      {!origin && (
        <div className="pointer-events-none absolute inset-x-0 top-14 z-[1000] flex justify-center">
          <span className="rounded-full bg-black/75 px-3 py-1 text-[10px] font-medium text-white/85 backdrop-blur">
            Tap the map to set your start point
          </span>
        </div>
      )}
      {origin && stops.length === 0 && (
        <div className="pointer-events-none absolute inset-x-0 top-14 z-[1000] flex justify-center">
          <span className="rounded-full bg-black/75 px-3 py-1 text-[10px] font-medium text-white/85 backdrop-blur">
            Tap to add stops · drag pins to adjust
          </span>
        </div>
      )}

      {/* bottom navigation card */}
      {route && (
        <div className="absolute inset-x-2 bottom-2 z-[1000] rounded-2xl border border-white/10 bg-black/80 p-3 text-white shadow-2xl backdrop-blur-xl">
          <div className="flex items-center gap-3">
            <button onClick={() => { setDist(0); setPlaying(false); }}
              className="rounded-full bg-white/10 p-2 text-white/85">
              <RotateCcw size={14} />
            </button>
            <button onClick={togglePlay}
              className="rounded-full bg-[#0A84FF] p-2.5 text-white shadow-lg">
              {playing ? <Pause size={16} /> : <Play size={16} className="ml-0.5" />}
            </button>
            <div className="min-w-0 flex-1">
              <div className="truncate text-[13px] font-semibold">{instruction}</div>
              <div className="truncate text-[10px] text-white/60">
                {arrived
                  ? `${stops.length} stop${stops.length === 1 ? "" : "s"} · ${fmtDist(route.total)} total`
                  : `${nextStop || "Approaching destination"} · ${fmtDist(remaining)} left · ETA ${fmtTime(eta)}`}
              </div>
            </div>
            <div className="flex flex-col gap-1">
              {SPEEDS.map((s, i) => (
                <button key={s.label} onClick={() => setSpeedIdx(i)}
                  className={`rounded-full px-2 py-0.5 text-[9px] font-semibold leading-none ${
                    i === speedIdx ? "bg-white text-black" : "bg-white/10 text-white/70"
                  }`}>
                  {s.label}
                </button>
              ))}
            </div>
          </div>
          <div className="mt-2 h-1 overflow-hidden rounded-full bg-white/15">
            <div className="h-full rounded-full bg-[#0A84FF] transition-[width] duration-100"
              style={{ width: `${(dist / route.total) * 100}%` }} />
          </div>
        </div>
      )}
    </div>
  );
}