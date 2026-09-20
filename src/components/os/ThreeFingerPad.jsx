import React from "react";
import { Lock } from "lucide-react";

// Big open pad shown during a trigger-driven takeover: the ONLY place a
// 3-finger tap unlocks the screen - the rest of the screen ignores the
// gesture so every phone button keeps working normally.
export default function ThreeFingerPad({ onUnlock }) {
  const onTouchStart = (e) => {
    if (e.touches.length >= 3) onUnlock();
  };
  // desktop fallback: a triple-click inside the pad does the same thing
  const onClick = (e) => {
    if (e.detail >= 3) onUnlock();
  };
  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-4 z-[70] flex justify-center px-4">
      <div onTouchStart={onTouchStart} onClick={onClick}
        className="pointer-events-auto flex h-20 w-[min(70vw,320px)] cursor-pointer select-none flex-col items-center justify-center gap-1 rounded-3xl border border-white/15 bg-black/45 text-white/70 backdrop-blur-md">
        <Lock size={20} strokeWidth={2.2} />
        <span className="text-xs font-body font-semibold tracking-wide">Tap with 3 fingers to unlock</span>
      </div>
    </div>
  );
}