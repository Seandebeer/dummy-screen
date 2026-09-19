import React, { useState, useRef, useEffect } from "react";
import { ScanFace } from "lucide-react";
import { cn } from "@/lib/utils";

const SCAN_MS = 1600;

export default function FaceScan({ light, onUnlock }) {
  const [scanning, setScanning] = useState(false);
  const timer = useRef(null);

  useEffect(() => () => clearTimeout(timer.current), []);

  const start = () => {
    if (scanning) return;
    setScanning(true);
    timer.current = setTimeout(() => onUnlock?.(), SCAN_MS);
  };

  return (
    <div className="flex flex-col items-center gap-3">
      <button
        onClick={start}
        className={cn(
          "relative flex h-28 w-28 items-center justify-center rounded-[2rem] border-2 overflow-hidden transition",
          scanning
            ? light ? "border-black/70" : "border-white/80"
            : light ? "border-black/25" : "border-white/30"
        )}
      >
        <ScanFace
          size={64}
          strokeWidth={1.5}
          className={cn("transition", scanning ? (light ? "text-black" : "text-white") : light ? "text-black/40" : "text-white/40")}
        />
        {scanning && (
          <span className={cn("absolute inset-x-3 top-1/2 h-0.5 rounded-full scan-line", light ? "bg-black/80" : "bg-white/90")} />
        )}
      </button>
      <p className={cn("text-[11px] font-body uppercase tracking-widest", light ? "text-black/60" : "text-white/60")}>
        {scanning ? "Scanning…" : "Face Scan · Tap to unlock"}
      </p>
    </div>
  );
}