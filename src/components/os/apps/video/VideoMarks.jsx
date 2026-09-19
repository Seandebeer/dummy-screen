import React, { useState, useRef, useEffect } from "react";
import { TrackingMarks } from "@/components/vfx/TrackingMarks";
import { defaultLayoutFor } from "@/hooks/useScreenMarks";

// tracking-mark overlay for the video player - works the same way as the
// UI marker marks: pick a style, hold & drag to move (snapped to the same
// 5 x 8 grid), double-tap to rotate 45 degrees
const COLS = 5;
const ROWS = 8;
// grid lines plus the centre-line exception, so the middle marker can sit
// exactly on the centre screen point
const XS = [...Array.from({ length: COLS + 1 }, (_, i) => (i / COLS) * 100), 50];
const YS = Array.from({ length: ROWS + 1 }, (_, i) => (i / ROWS) * 100);
const nearest = (v, arr) => arr.reduce((a, b) => (Math.abs(b - v) < Math.abs(a - v) ? b : a));

export const MARK_STYLES = [
  { id: "cross", label: "Cross" },
  { id: "circles", label: "Targets" },
  { id: "squares", label: "Squares" },
  { id: "brackets", label: "Brackets" },
  { id: "diamond", label: "Diamond" },
];

export const MARK_COLORS = ["#FFFFFF", "#000000", "#FF3B30", "#34C759", "#0A84FF", "#FF9F0A"];

const rgba = (hex, a) => {
  const m = /^#?([0-9a-f]{6})$/i.exec(hex || "");
  if (!m) return hex;
  const n = parseInt(m[1], 16);
  return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${a})`;
};

export default function VideoMarks({ marks, onChange, locked, color = "#FFFFFF" }) {
  const [dragMark, setDragMark] = useState(null);
  const boxRef = useRef(null);
  const holdTimer = useRef(null);
  const pendingId = useRef(null);
  const lastTap = useRef({ id: null, t: 0 });

  const style = marks.style || "none";
  const snapLayout = (list) => list.map((m) => ({ ...m, x: nearest(m.x, XS), y: nearest(m.y, YS) }));
  const layout = marks.layouts?.[style] || snapLayout(defaultLayoutFor(style));

  const updateLayout = (fn) => onChange((m) => ({
    ...m,
    layouts: { ...(m.layouts || {}), [style]: fn(m.layouts?.[style] || snapLayout(defaultLayoutFor(style))) },
  }));

  const onMarkDown = (id, e) => {
    e.stopPropagation();
    if (e.pointerType === "mouse" && e.button !== 0) return;
    clearTimeout(holdTimer.current);
    pendingId.current = id;
    holdTimer.current = setTimeout(() => { pendingId.current = null; setDragMark(id); }, 250);
  };

  // drag the held marker - snaps to the UI marker grid
  useEffect(() => {
    if (!dragMark) return;
    const move = (e) => {
      const rect = boxRef.current?.getBoundingClientRect();
      if (!rect) return;
      const x = Math.max(2, Math.min(98, nearest(((e.clientX - rect.left) / rect.width) * 100, XS)));
      const y = Math.max(2, Math.min(98, nearest(((e.clientY - rect.top) / rect.height) * 100, YS)));
      updateLayout((list) => list.map((m) => (m.id !== dragMark ? m : { ...m, x, y })));
    };
    window.addEventListener("pointermove", move);
    return () => window.removeEventListener("pointermove", move);
  }, [dragMark, style]);

  // release: end a drag; a double-tap rotates the mark 45 degrees
  useEffect(() => {
    const up = () => {
      clearTimeout(holdTimer.current);
      const tapped = pendingId.current;
      pendingId.current = null;
      if (dragMark) { setDragMark(null); return; }
      if (!tapped) return;
      const now = Date.now();
      if (lastTap.current.id === tapped && now - lastTap.current.t < 350) {
        lastTap.current = { id: null, t: 0 };
        updateLayout((list) => list.map((m) => (m.id !== tapped ? m : { ...m, rot: ((m.rot || 0) + 45) % 360 })));
      } else {
        lastTap.current = { id: tapped, t: now };
      }
    };
    window.addEventListener("pointerup", up);
    window.addEventListener("pointercancel", up);
    return () => {
      window.removeEventListener("pointerup", up);
      window.removeEventListener("pointercancel", up);
    };
  }, [dragMark, style]);

  if (style === "none") return null;

  return (
    // stops marker taps from bubbling into the stage's play/pause toggle
    <div ref={boxRef} className="pointer-events-none absolute inset-0 z-[5]" onClick={(e) => e.stopPropagation()}>
      <TrackingMarks type={style} color={color} opacity={0.85} size={1.1} thickness={0.6}
        markers={layout} dragId={dragMark}
        onMarkerDown={!locked ? onMarkDown : undefined} />
      {dragMark && (
        <div className="pointer-events-none absolute inset-0" style={{
          backgroundImage: `linear-gradient(to right, ${rgba(color, 0.35)} 1px, transparent 1px), linear-gradient(to bottom, ${rgba(color, 0.35)} 1px, transparent 1px)`,
          backgroundSize: `${100 / COLS}% ${100 / ROWS}%`,
        }}>
          <div className="absolute inset-y-0 left-1/2 w-px" style={{ background: rgba(color, 0.45) }} />
          <span className="absolute left-1/2 top-1/2 h-1.5 w-1.5 -translate-x-1/2 -translate-y-1/2 rounded-full" style={{ background: rgba(color, 0.8) }} />
        </div>
      )}
    </div>
  );
}