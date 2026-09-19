import React, { useRef, useState } from "react";
import { ChevronUp } from "lucide-react";
import { cn } from "@/lib/utils";

const THRESHOLD = 80;

export default function SwipeUpUnlock({ light, onUnlock }) {
  const [progress, setProgress] = useState(0);
  const start = useRef(null);

  const onDown = (e) => { start.current = e.clientY; };
  const onMove = (e) => {
    if (start.current === null) return;
    const dy = start.current - e.clientY;
    setProgress(Math.max(0, Math.min(1, dy / THRESHOLD)));
  };
  const onUp = () => {
    const released = progress;
    start.current = null;
    setProgress(0);
    if (released >= 1) onUnlock?.();
  };

  return (
    <div
      onPointerDown={onDown}
      onPointerMove={onMove}
      onPointerUp={onUp}
      onPointerCancel={onUp}
      onContextMenu={(e) => e.preventDefault()}
      className="w-full max-w-[280px] py-2 mx-auto flex flex-col items-center gap-4 cursor-pointer touch-none select-none"
    >
      <div
        className={cn("flex flex-col items-center gap-1.5 transition-transform", light ? "text-black/70" : "text-white/70")}
        style={{ transform: `translateY(${-progress * 34}px)` }}
      >
        <ChevronUp size={22} />
        <span className="h-1 w-20 rounded-full bg-current opacity-40" />
      </div>
      <p className={cn("text-[11px] font-body uppercase tracking-widest", light ? "text-black/60" : "text-white/60")}>
        Swipe up to unlock
      </p>
    </div>
  );
}