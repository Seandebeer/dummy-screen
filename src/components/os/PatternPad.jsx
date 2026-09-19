import React, { useRef, useState, useEffect, useCallback } from "react";
import { cn } from "@/lib/utils";

const STEP = 72;
const ORIGIN = 42;
const SIZE = ORIGIN * 2 + STEP * 2;
const center = (i) => ({ x: ORIGIN + (i % 3) * STEP, y: ORIGIN + Math.floor(i / 3) * STEP });

export default function PatternPad({ light, clearKey, onComplete }) {
  const [path, setPath] = useState([]);
  const drawing = useRef(false);
  const padRef = useRef(null);
  const pathRef = useRef([]);

  useEffect(() => { pathRef.current = path; }, [path]);
  useEffect(() => { drawing.current = false; setPath([]); }, [clearKey]);

  const localPoint = (e) => {
    const rect = padRef.current.getBoundingClientRect();
    return { x: e.clientX - rect.left, y: e.clientY - rect.top };
  };

  const hitDot = (p) => {
    for (let i = 0; i < 9; i++) {
      const c = center(i);
      if (Math.hypot(p.x - c.x, p.y - c.y) <= 32) return i;
    }
    return -1;
  };

  const onDown = (e) => {
    const i = hitDot(localPoint(e));
    if (i === -1) return;
    e.preventDefault();
    e.currentTarget.setPointerCapture?.(e.pointerId);
    drawing.current = true;
    setPath([i]);
  };

  const onMove = (e) => {
    if (!drawing.current) return;
    e.preventDefault();
    const i = hitDot(localPoint(e));
    if (i !== -1 && !pathRef.current.includes(i)) setPath((p) => [...p, i]);
  };

  const onUp = useCallback(() => {
    if (!drawing.current) return;
    drawing.current = false;
    const p = pathRef.current;
    if (p.length >= 4) onComplete?.(p.join(""));
    setTimeout(() => setPath([]), 400);
  }, [onComplete]);

  const points = path.map(center);

  return (
    <div
      ref={padRef}
      onPointerDown={onDown}
      onPointerMove={onMove}
      onPointerUp={onUp}
      onPointerCancel={onUp}
      className="relative mx-auto select-none touch-none"
      style={{ width: SIZE, height: SIZE }}
    >
      <svg width={SIZE} height={SIZE} className="absolute inset-0 pointer-events-none">
        {points.length > 1 && (
          <polyline
            points={points.map((p) => `${p.x},${p.y}`).join(" ")}
            fill="none"
            strokeWidth="4"
            strokeLinecap="round"
            strokeLinejoin="round"
            stroke={light ? "rgba(0,0,0,0.7)" : "rgba(255,255,255,0.9)"}
          />
        )}
      </svg>
      {Array.from({ length: 9 }, (_, i) => {
        const c = center(i);
        const active = path.includes(i);
        return (
          <span
            key={i}
            className={cn(
              "absolute rounded-full border-2 transition-all",
              active
                ? cn("h-4 w-4 border-current", light ? "bg-black/80" : "bg-white/90")
                : cn("h-3.5 w-3.5", light ? "bg-black/15 border-black/40" : "bg-white/20 border-white/50")
            )}
            style={{ left: c.x, top: c.y, transform: "translate(-50%, -50%)" }}
          />
        );
      })}
    </div>
  );
}