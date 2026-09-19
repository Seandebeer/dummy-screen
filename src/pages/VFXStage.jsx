import React, { useState, useEffect, useRef, useCallback } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { getColor, trackingMarks, vfxColors } from "@/lib/vfxData";
import { TrackingMarks } from "@/components/vfx/TrackingMarks";
import { cn } from "@/lib/utils";

export default function VFXStage() {
  const [params] = useSearchParams();
  const colorId = params.get("color") || "green";
  const marksId = params.get("marks") || "cross";
  const color = getColor(colorId);
  const isLight = ["white", "green", "grey"].includes(colorId);

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
      <TrackingMarks type={marksId} color={isLight ? "#000000" : "#FFFFFF"} opacity={marksId === "checkerboard" ? 1 : 0.85} />

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
            <Link to="/" className={cn("flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-body backdrop-blur",
              isLight ? "bg-black/60 text-white" : "bg-white/15 text-white")}>
              ← Exit
            </Link>
            <div className="mt-3 flex flex-col gap-2">
              {marksId === "checkerboard" ? (
                <span className={cn("px-3 py-1.5 rounded-full text-[10px] font-body backdrop-blur w-max",
                  isLight ? "bg-black/60 text-white" : "bg-white/15 text-white")}>
                  Black &amp; white only
                </span>
              ) : (
                vfxColors.map((c) => (
                  <Link key={c.id} to={`/vfx?color=${c.id}&marks=${marksId}`}
                    title={c.label}
                    className={cn("h-6 w-6 rounded-full border-2 transition",
                      colorId === c.id ? "border-amber" : "border-white/40 hover:border-white/80")}
                    style={{ background: c.hex }} />
                ))
              )}
            </div>
          </div>
          <div className="absolute bottom-6 inset-x-0 flex justify-center z-40 pointer-events-none">
            <div className={cn("px-4 py-2 rounded-full text-xs font-body backdrop-blur flex items-center gap-2",
              isLight ? "bg-black/60 text-white" : "bg-white/15 text-white")}>
              <span className="h-1.5 w-1.5 rounded-full bg-amber amber-pulse" />
              3-Finger Tap to Lock / Unlock
            </div>
          </div>
          <div className="absolute top-4 right-4 z-40 flex flex-wrap justify-end gap-2 max-w-[280px]">
            {trackingMarks.map((m) => (
              <Link key={m.id} to={`/vfx?color=${colorId}&marks=${m.id}`}
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