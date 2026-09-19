// shared geo helpers for the OS Maps app - distances, bearings and
// simulated route playback along straight-leg segments
const R = 6371000;
const D2R = Math.PI / 180;
const R2D = 180 / Math.PI;

export function haversine(a, b) {
  const dLat = (b[0] - a[0]) * D2R;
  const dLon = (b[1] - a[1]) * D2R;
  const x =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(a[0] * D2R) * Math.cos(b[0] * D2R) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(x));
}

export function bearing(a, b) {
  const y = Math.sin((b[1] - a[1]) * D2R) * Math.cos(b[0] * D2R);
  const x =
    Math.cos(a[0] * D2R) * Math.sin(b[0] * D2R) -
    Math.sin(a[0] * D2R) * Math.cos(b[0] * D2R) * Math.cos((b[1] - a[1]) * D2R);
  return (Math.atan2(y, x) * R2D + 360) % 360;
}

// build straight-leg route: origin + stops -> ordered segments
export function buildRoute(points) {
  const segments = [];
  let total = 0;
  for (let i = 0; i < points.length - 1; i++) {
    const len = haversine(points[i], points[i + 1]);
    const b = bearing(points[i], points[i + 1]);
    const prev = segments[segments.length - 1];
    const turnDelta = prev ? ((b - prev.bearing + 540) % 360) - 180 : 0;
    segments.push({ from: points[i], to: points[i + 1], len, bearing: b, turnDelta });
    total += len;
  }
  return { points, segments, total };
}

// point + active segment at a distance travelled along the route
export function positionAt(route, dist) {
  if (!route || !route.segments.length) return null;
  const d = Math.max(0, Math.min(dist, route.total));
  let acc = 0;
  for (let i = 0; i < route.segments.length; i++) {
    const s = route.segments[i];
    if (d <= acc + s.len || i === route.segments.length - 1) {
      const t = s.len ? Math.max(0, Math.min(1, (d - acc) / s.len)) : 0;
      return {
        lat: s.from[0] + (s.to[0] - s.from[0]) * t,
        lng: s.from[1] + (s.to[1] - s.from[1]) * t,
        segIndex: i,
        bearing: s.bearing,
        segRemaining: s.len * (1 - t),
      };
    }
    acc += s.len;
  }
  return null;
}

const DIRS = ["north", "northeast", "east", "southeast", "south", "southwest", "west", "northwest"];
export const compass = (deg) => DIRS[Math.round((((deg % 360) + 360) % 360) / 45) % 8];

export function turnName(delta) {
  const d = Math.abs(delta);
  if (d < 20) return "Continue straight";
  if (d < 55) return delta > 0 ? "Keep right" : "Keep left";
  if (d < 140) return delta > 0 ? "Turn right" : "Turn left";
  return "Make a U-turn";
}

export function fmtDist(m) {
  if (m < 950) return `${Math.max(10, Math.round(m / 10) * 10)} m`;
  return `${(m / 1000).toFixed(1)} km`;
}

export function fmtTime(sec) {
  const s = Math.max(0, Math.round(sec));
  if (s < 3600) return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
  return `${Math.floor(s / 3600)}h ${Math.floor((s % 3600) / 60)}m`;
}