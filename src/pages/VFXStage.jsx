import React, { useState, useEffect, useRef, useCallback } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { getColor, trackingMarks } from "@/lib/vfxData";
import { TrackingMarks } from "@/components/vfx/TrackingMarks";
import { cn } from "@/lib/utils";

export default function VFXStage() {
  const [params] = useSearchParams();
  const colorId = params.get("color") || "green";
  const marksId = params.get("marks") || "crosshair";
  const color = getColor(colorId);
  const isLight = colorId === "white" || colorId === "green";

  const [locked, setLocked] = useState(false);
  const [banner, setBanner] = useState(null);
  const tapTimer = useRef(null);
  const bannerTimer = useRef(null);

  const flash = useCallback((msg) => {
    setBanner(msg);
    clearTimeout(bannerTimer.current);
    bannerTimer.current = setTimeout(() => setBanner(null), 1400);
  }, []);

  const toggleLock = useCallback(() => {
    setLocked((l) => {
      const next = !l;
      flash(next ? "STAGE LOCKED" : "STAGE UNLOCKED");
      return next;
    });
  }, [flash]);

  // three-finger tap (touch) or triple-click / 'L' key (desktop fallback)
  useEffect(() => {
    const onTouch = (e) => { if (e.touches.length >= 3) { e.preventDefault(); toggleLock(); } };
    const onKey = (e) => { if (e.key.toLowerCase() === "l") toggleLock(); };
    window.addEventListener("touchstart", onTouch, { passive: false });
    window.addEventListener("keydown", onKey);
    return () => {
      window.removeEventListener("touchstart", onTouch);
      window.removeEventListener("keydown", onKey);
      clearTimeout(bannerTimer.current);
    };
  }, [toggleLock]);

  return (
    <div className="fixed inset-0 z-50 overflow-hidden" style={{ background: color.hex }}>
      <TrackingMarks type={marksId} color={isLight ? "#000000" : "#FFFFFF"} opacity={0.85} />

      {/* lock / unlock banner */}
      {banner && (
        <div className="absolute inset-x-0 top-8 flex justify-center pointer-events-none z-50">
          <div className={cn("px-4 py-2 rounded-full font-display font-bold text-sm tracking-widest backdrop-blur",
            isLight ? "bg-black/70 text-white" : "bg-white/15 text-white")}>
            {banner}
          </div>
        </div>
      )}

      {/* unlocked controls */}
      {!locked && (
        <>
          <div className="absolute top-4 left-4 z-40">
            <Link to="/vfx" className={cn("flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-body backdrop-blur",
              isLight ? "bg-black/60 text-white" : "bg-white/15 text-white")}>
              ← Exit
            </Link>
          </div>
          <div className="absolute bottom-6 inset-x-0 flex justify-center z-40 pointer-events-none">
            <div className={cn("px-4 py-2 rounded-full text-xs font-body backdrop-blur flex items-center gap-2",
              isLight ? "bg-black/60 text-white" : "bg-white/15 text-white")}>
              <span className="h-1.5 w-1.5 rounded-full bg-amber amber-pulse" />
              3-Finger Tap to Lock / Unlock
            </div>
          </div>
          <div className="absolute top-4 right-4 z-40 flex gap-2">
            {trackingMarks.map((m) => (
              <Link key={m.id} to={`/vfx-stage?color=${colorId}&marks=${m.id}`}
                className={cn("px-2.5 py-1 rounded-full text-[10px] font-body backdrop-blur border",
                  marksId === m.id ? "bg-amber text-black border-amber" : isLight ? "bg-black/40 text-white border-white/20" : "bg-white/15 text-white border-white/20")}>
                {m.name}
              </Link>
            ))}
          </div>
        </>
      )}

      {locked && (
        <div className="absolute top-3 right-4 z-40 pointer-events-none">
          <span className={cn("text-[10px] font-body tracking-widest opacity-60", isLight ? "text-black" : "text-white")}>LOCKED</span>
        </div>
      )}
    </div>
  );
}