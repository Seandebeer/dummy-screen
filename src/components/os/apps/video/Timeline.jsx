import React, { useRef, useEffect } from "react";
import { fmtDur } from "@/lib/videoStore";

// professional trim timeline: filmstrip, in/out trim handles, scrubbing playhead
export default function Timeline({ duration, trim, currentTime, thumbs, onTrim, onSeek }) {
  const trackRef = useRef(null);
  const drag = useRef(null);

  const pct = (t) => Math.max(0, Math.min(100, (t / duration) * 100));

  const timeAt = (clientX) => {
    const rect = trackRef.current?.getBoundingClientRect();
    if (!rect) return 0;
    return Math.max(0, Math.min(duration, ((clientX - rect.left) / rect.width) * duration));
  };

  const startDrag = (mode) => (e) => {
    e.stopPropagation();
    e.preventDefault();
    drag.current = mode;
  };

  // registered fresh each render so the latest trim / seek handlers are used
  useEffect(() => {
    const move = (e) => {
      const mode = drag.current;
      if (!mode) return;
      const t = timeAt(e.clientX);
      if (mode === "in") onTrim("start", t);
      else if (mode === "out") onTrim("end", t);
      else onSeek(t);
    };
    const up = () => { drag.current = null; };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
    window.addEventListener("pointercancel", up);
    return () => {
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", up);
      window.removeEventListener("pointercancel", up);
    };
  });

  return (
    <div className="select-none">
      <div className="mb-1 flex items-center justify-between text-[9px] font-mono text-white/50">
        <span>{fmtDur(trim.start)}</span>
        <span className="text-white">{fmtDur(currentTime)}</span>
        <span>{fmtDur(trim.end)}</span>
      </div>
      <div ref={trackRef} className="relative h-12 cursor-pointer touch-none overflow-hidden rounded-lg border border-white/15 bg-black"
        onPointerDown={(e) => { drag.current = "play"; onSeek(timeAt(e.clientX)); }}>
        <div className="absolute inset-0 flex">
          {(thumbs || []).map((src, i) => (
            <img key={i} src={src} alt="" draggable={false}
              className="h-full min-w-0 flex-1 object-cover opacity-60" />
          ))}
        </div>
        <div className="absolute inset-y-0 left-0 border-r border-amber/70 bg-black/75" style={{ width: `${pct(trim.start)}%` }} />
        <div className="absolute inset-y-0 right-0 border-l border-amber/70 bg-black/75" style={{ left: `${pct(trim.end)}%` }} />
        <div className="absolute inset-y-0 w-[2px] bg-white shadow-[0_0_6px_rgba(255,255,255,0.8)]" style={{ left: `${pct(currentTime)}%` }} />
        <div className="absolute inset-y-0 flex w-3 cursor-ew-resize touch-none items-center justify-center rounded-l bg-white/95"
          style={{ left: `${pct(trim.start)}%` }} onPointerDown={startDrag("in")}>
          <div className="h-4 w-0.5 rounded bg-black/70" />
        </div>
        <div className="absolute inset-y-0 flex w-3 cursor-ew-resize touch-none items-center justify-center rounded-r bg-white/95"
          style={{ left: `calc(${pct(trim.end)}% - 12px)` }} onPointerDown={startDrag("out")}>
          <div className="h-4 w-0.5 rounded bg-black/70" />
        </div>
      </div>
      <div className="mt-1 flex items-center justify-between text-[8px] uppercase tracking-wider text-white/30">
        <span>Trim in</span>
        <span>Drag edges · drag strip to scrub</span>
        <span>Trim out</span>
      </div>
    </div>
  );
}