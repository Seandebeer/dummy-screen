import React, { useRef, useState, useEffect } from "react";
import { Fingerprint } from "lucide-react";
import { cn } from "@/lib/utils";

const HOLD_MS = 1200;
const R = 44;
const CIRC = 2 * Math.PI * R;

export default function FingerprintSensor({ light, onUnlock }) {
  const [holding, setHolding] = useState(false);
  const timer = useRef(null);

  useEffect(() => () => clearTimeout(timer.current), []);

  const start = (e) => {
    if (timer.current) return;
    e.preventDefault();
    setHolding(true);
    timer.current = setTimeout(() => {
      clearTimeout(timer.current);
      timer.current = null;
      onUnlock?.();
    }, HOLD_MS);
  };

  const stop = () => {
    if (!timer.current) return;
    clearTimeout(timer.current);
    timer.current = null;
    setHolding(false);
  };

  return (
    <div className="flex flex-col items-center gap-3">
      <button
        onPointerDown={start}
        onPointerUp={stop}
        onPointerLeave={stop}
        onPointerCancel={stop}
        onContextMenu={(e) => e.preventDefault()}
        className={cn(
          "relative flex h-32 w-32 items-center justify-center rounded-full touch-none select-none transition",
          light ? "bg-black/5" : "bg-white/5",
          holding && (light ? "bg-black/10" : "bg-white/10")
        )}
      >
        <svg className="absolute inset-0 -rotate-90 pointer-events-none" viewBox="0 0 100 100">
          <circle cx="50" cy="50" r={R} fill="none" strokeWidth="3" className={light ? "stroke-black/15" : "stroke-white/20"} />
          <circle
            cx="50"
            cy="50"
            r={R}
            fill="none"
            strokeWidth="3"
            strokeLinecap="round"
            stroke={light ? "#111111" : "#ffffff"}
            strokeDasharray={CIRC}
            strokeDashoffset={holding ? 0 : CIRC}
            style={{ transition: holding ? `stroke-dashoffset ${HOLD_MS}ms linear` : "stroke-dashoffset 200ms ease" }}
          />
        </svg>
        <Fingerprint
          size={48}
          strokeWidth={1.5}
          className={cn("transition", holding ? (light ? "text-black" : "text-white") : light ? "text-black/50" : "text-white/50")}
        />
      </button>
      <p className={cn("text-[11px] font-body uppercase tracking-widest", light ? "text-black/60" : "text-white/60")}>
        {holding ? "Hold…" : "Press & hold to unlock"}
      </p>
    </div>
  );
}