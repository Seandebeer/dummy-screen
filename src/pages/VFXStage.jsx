import React, { useState, useEffect, useRef, useCallback } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { Plus, RotateCcw } from "lucide-react";
import { getColor, trackingMarks, vfxColors } from "@/lib/vfxData";
import { TrackingMarks } from "@/components/vfx/TrackingMarks";
import useScreenMarks, { defaultLayoutFor } from "@/hooks/useScreenMarks";
import { Slider } from "@/components/ui/slider";
import { cn } from "@/lib/utils";

const POINT_STYLES = ["cross", "circles", "squares", "brackets"];

export default function VFXStage() {
  const [params] = useSearchParams();
  const colorId = params.get("color") || "green";
  const marksId = params.get("marks") || "cross";
  const color = getColor(colorId);
  const isLight = ["white", "green", "grey"].includes(colorId);

  const { marks, update } = useScreenMarks();
  const isPoint = POINT_STYLES.includes(marksId);
  const layout = isPoint ? (marks.layouts[marksId] ?? defaultLayoutFor(marksId)) : [];

  const [locked, setLocked] = useState(false);
  const [banner, setBanner] = useState(null);
  const [dragId, setDragId] = useState(null);
  const bannerTimer = useRef(null);
  const holdTimer = useRef(null);
  const pendingId = useRef(null);

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

  // three-finger tap (touch) or 'L' key (desktop fallback)
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

  const updateLayout = (fn) => update((m) => ({
    layouts: { ...m.layouts, [marksId]: fn(m.layouts[marksId] ?? defaultLayoutFor(marksId)) },
  }));

  const addMarker = () => updateLayout((list) => [...list, { id: `m-${Date.now()}`, kind: marksId, x: 50, y: 50 }]);

  const onMarkerDown = (id, e) => {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    pendingId.current = id;
    clearTimeout(holdTimer.current);
    holdTimer.current = setTimeout(() => { pendingId.current = null; setDragId(id); }, 250);
  };

  // move the held marker — snaps to a 5% grid
  useEffect(() => {
    if (!dragId) return;
    const move = (e) => {
      updateLayout((list) => list.map((m) => m.id !== dragId ? m : {
        ...m,
        x: Math.min(100, Math.max(0, Math.round((e.clientX / window.innerWidth) * 20) * 5)),
        y: Math.min(100, Math.max(0, Math.round((e.clientY / window.innerHeight) * 20) * 5)),
      }));
    };
    window.addEventListener("pointermove", move);
    return () => window.removeEventListener("pointermove", move);
  }, [dragId, marksId]);

  // release: end a drag, or a short tap removes the marker
  useEffect(() => {
    const up = () => {
      clearTimeout(holdTimer.current);
      const tapped = pendingId.current;
      pendingId.current = null;
      if (dragId) { setDragId(null); return; }
      if (tapped) updateLayout((list) => list.filter((m) => m.id !== tapped));
    };
    window.addEventListener("pointerup", up);
    window.addEventListener("pointercancel", up);
    return () => {
      window.removeEventListener("pointerup", up);
      window.removeEventListener("pointercancel", up);
    };
  }, [dragId, marksId]);

  const resetCustomisation = () => update((m) => ({
    scale: 1,
    thickness: 1,
    layouts: { ...m.layouts, [marksId]: defaultLayoutFor(marksId) },
  }));

  const chip = "rounded-full backdrop-blur border";
  const chipStyle = isLight ? "bg-black/60 text-white border-white/20" : "bg-white/15 text-white border-white/20";

  return (
    <div className="fixed inset-0 z-50 overflow-hidden" style={{ background: color.hex }}>
      <TrackingMarks type={marksId} color={isLight ? "#000000" : "#FFFFFF"}
        opacity={marksId === "checkerboard" ? 1 : 0.85}
        size={marks.scale} thickness={marks.thickness}
        markers={layout} dragId={dragId}
        onMarkerDown={!locked && isPoint ? onMarkerDown : undefined} />

      {/* temporary snap grid while dragging a marker */}
      {dragId && (
        <div className="absolute inset-0 pointer-events-none" style={{
          backgroundImage: `linear-gradient(to right, ${isLight ? "rgba(0,0,0,0.3)" : "rgba(255,255,255,0.3)"} 1px, transparent 1px), linear-gradient(to bottom, ${isLight ? "rgba(0,0,0,0.3)" : "rgba(255,255,255,0.3)"} 1px, transparent 1px)`,
          backgroundSize: "5% 5%",
        }} />
      )}

      {/* lock / unlock banner */}
      {banner && (
        <div className="absolute inset-x-0 top-8 flex justify-center pointer-events-none z-50">
          <div className={cn("px-4 py-2 rounded-full font-display font-bold text-sm tracking-widest", chip, chipStyle)}>
            {banner}
          </div>
        </div>
      )}

      {/* unlocked controls */}
      {!locked && (
        <>
          <div className="absolute top-4 left-4 z-40">
            <Link to="/" className={cn("flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-body", chip, chipStyle)}>
              ← Exit
            </Link>
            <div className="mt-3 flex flex-col gap-2">
              {marksId === "checkerboard" ? (
                <span className={cn("px-3 py-1.5 text-[10px] font-body w-max", chip, chipStyle)}>
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

            {/* marker size / thickness sliders */}
            {marksId !== "none" && (
              <div className="mt-3 flex flex-col gap-1.5">
                <div className={cn("flex items-center gap-2 px-3 py-1.5", chip, chipStyle)}>
                  <span className="text-[10px] font-body w-9">Size</span>
                  <Slider className="w-24" value={[marks.scale]} min={0.5} max={3} step={0.25}
                    onValueChange={([v]) => update((m) => ({ scale: v }))} />
                </div>
                {marksId !== "checkerboard" && (
                  <div className={cn("flex items-center gap-2 px-3 py-1.5", chip, chipStyle)}>
                    <span className="text-[10px] font-body w-9">Thick</span>
                    <Slider className="w-24" value={[marks.thickness]} min={0.5} max={3} step={0.25}
                      onValueChange={([v]) => update((m) => ({ thickness: v }))} />
                  </div>
                )}
              </div>
            )}

            {/* add markers / reset customisation */}
            {isPoint && (
              <button onClick={addMarker}
                className={cn("mt-3 flex items-center gap-1 px-2.5 py-1 text-[10px] font-body", chip, chipStyle)}>
                <Plus size={11} /> Add
              </button>
            )}
            {marksId !== "none" && (
              <button onClick={resetCustomisation}
                className={cn("mt-2 flex items-center gap-1 px-2.5 py-1 text-[10px] font-body", chip, chipStyle)}>
                <RotateCcw size={11} /> Reset
              </button>
            )}
          </div>

          {isPoint && (
            <div className="absolute bottom-16 inset-x-0 flex justify-center z-40 pointer-events-none">
              <div className={cn("px-3 py-1 rounded-full text-[10px] font-body", chip, chipStyle)}>
                Hold &amp; drag to move · tap to remove
              </div>
            </div>
          )}
          <div className="absolute bottom-6 inset-x-0 flex justify-center z-40 pointer-events-none">
            <div className={cn("px-4 py-2 rounded-full text-xs font-body flex items-center gap-2", chip, chipStyle)}>
              <span className="h-1.5 w-1.5 rounded-full bg-amber amber-pulse" />
              3-Finger Tap to Lock / Unlock
            </div>
          </div>
          <div className="absolute top-4 right-4 z-40 flex flex-wrap justify-end gap-2 max-w-[280px]">
            {trackingMarks.map((m) => (
              <Link key={m.id} to={`/vfx?color=${colorId}&marks=${m.id}`}
                className={cn("px-2.5 py-1 rounded-full text-[10px] font-body border",
                  marksId === m.id ? "bg-amber text-black border-amber" : chipStyle)}>
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