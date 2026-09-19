import React, { useRef, useState } from "react";
import { ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";

// Classic 2007-2013 slider: drag the knob right past ~70% to unlock.
// Gloss variant matches iPhone OS 1 - iOS 6, flat matches iOS 7.
export default function SlideToUnlock({ light = false, flat = false, onUnlock }) {
  const [x, setX] = useState(0);
  const start = useRef(null);
  const trackRef = useRef(null);
  const KNOB = 48;
  const PAD = 3;

  const max = () => Math.max(0, (trackRef.current?.offsetWidth || 0) - KNOB - PAD * 2);

  const onDown = (e) => {
    start.current = e.clientX - x;
    e.currentTarget.setPointerCapture(e.pointerId);
  };
  const onMove = (e) => {
    if (start.current === null) return;
    setX(Math.max(0, Math.min(max(), e.clientX - start.current)));
  };
  const onUp = () => {
    start.current = null;
    if (x >= max() * 0.7) onUnlock?.();
    setX(0);
  };

  const txt = flat
    ? light ? "text-black/70" : "text-white/80"
    : light ? "text-black/70" : "text-white/90";

  return (
    <div
      ref={trackRef}
      onContextMenu={(e) => e.preventDefault()}
      className={cn("relative mx-auto w-full max-w-[300px] h-[54px] select-none touch-none",
        flat ? "rounded-full" : "rounded-full",
        flat
          ? light ? "border border-black/15 bg-black/5" : "border border-white/15 bg-white/10"
          : "border border-white/25")}
      style={!flat ? {
        backgroundImage: "linear-gradient(180deg, rgba(0,0,0,0.6) 0%, rgba(0,0,0,0.35) 100%)",
        boxShadow: "inset 0 2px 6px rgba(0,0,0,0.55)",
      } : undefined}
    >
      {/* track label + chevrons */}
      <div className="absolute inset-0 flex items-center justify-center gap-2 overflow-hidden">
        {!flat && (
          <span className={cn("flex", txt)}>
            {[0, 1, 2].map((i) => <ChevronRight key={i} size={13} className="-ml-1" />)}
          </span>
        )}
        <span className={cn("text-[13px] font-medium", txt)}
          style={!flat ? { textShadow: "0 1px 1px rgba(0,0,0,0.8)" } : undefined}>
          slide to unlock
        </span>
      </div>
      {/* the knob */}
      <div
        onPointerDown={onDown}
        onPointerMove={onMove}
        onPointerUp={onUp}
        onPointerCancel={onUp}
        className={cn("absolute flex items-center justify-center cursor-pointer",
          flat ? "rounded-full border" : "rounded-[1rem] border")}
        style={{
          left: PAD, top: PAD, width: KNOB, height: KNOB,
          transform: `translateX(${x}px)`,
          transition: start.current === null ? "transform 220ms ease-out" : "none",
          ...(flat
            ? {
                borderColor: light ? "rgba(0,0,0,0.25)" : "rgba(255,255,255,0.3)",
                background: light ? "rgba(255,255,255,0.5)" : "rgba(255,255,255,0.2)",
                boxShadow: "0 1px 4px rgba(0,0,0,0.3)",
              }
            : {
                borderColor: "rgba(255,255,255,0.5)",
                backgroundImage: "linear-gradient(180deg, #ffffff 0%, #d7dade 48%, #a8adb2 52%, #83888c 100%)",
                boxShadow: "0 1px 3px rgba(0,0,0,0.55)",
              }),
        }}
      >
        <ChevronRight size={20} className={flat ? (light ? "text-black/60" : "text-white/90") : "text-black/60"} />
      </div>
    </div>
  );
}