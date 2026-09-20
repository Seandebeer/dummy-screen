import React from "react";
import { cn } from "@/lib/utils";

// brief on-screen prompt - the 3-finger tap is the hidden way out of any
// fullscreen / locked takeover (OS, UI markers, VFX stage, video player)
export default function ThreeFingerHint({ light }) {
  return (
    <div className="pointer-events-none absolute inset-0 z-50 flex items-center justify-center">
      <span className={cn("rounded-2xl px-6 py-3.5 text-base font-display font-semibold backdrop-blur-xl",
        light ? "bg-black/10 text-black/80" : "bg-white/15 text-white/90")}>
        Tap screen with 3 fingers to unlock
      </span>
    </div>
  );
}