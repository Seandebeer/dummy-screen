import React from "react";
import { cn } from "@/lib/utils";

// brief on-screen prompt - the 3-finger tap is the hidden way out of any
// fullscreen / locked takeover (OS, UI markers, VFX stage, video player)
export default function ThreeFingerHint({ light }) {
  return (
    <div className="pointer-events-none absolute inset-x-0 bottom-3 z-50 flex justify-center">
      <span className={cn("rounded-full px-3 py-1 text-[10px] font-body backdrop-blur",
        light ? "bg-black/5 text-black/50" : "bg-white/10 text-white/50")}>
        Tap screen with 3 fingers to unlock
      </span>
    </div>
  );
}