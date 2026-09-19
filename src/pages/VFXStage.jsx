import React, { useState, useEffect, useRef, useCallback } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { Plus, RotateCcw, Save } from "lucide-react";
import { getColor, trackingMarks, vfxColors } from "@/lib/vfxData";
import { saveConfig } from "@/lib/savedConfigs";
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

  const saveScreen = () => {
    const name = window.prompt("Name this screen:", `${marksId} · ${colorId}`);
    if (!name) return;
    saveConfig({ kind: "screen", name: name.trim() || "Untitled", colorId, marksId, marks });
  };

  // premium glass system shared by every floating control on the stage
  const glass = "backdrop-blur-xl border shadow-2xl";
  const glassStyle = isLight
    ? "bg-black/55 text-white border-white/15 shadow-black/30"
    : "bg-black/45 text-white border-white/15 shadow-black/50";
  const actionBtn = "flex items-center gap-1.5 rounded-full px-3 py-1.5 text-[10px] font-body tracking-wide transition hover:bg-white/15";

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
          <div className={cn("px-5 py-2.5 rounded-full font-display font-bold text-xs tracking-[0.25em]", glass, glassStyle)}>
            {banner}
          </div>
        </div>
      )}

      {/* unlocked controls */}
      {!locked && (
        <>
          <div className="absolute top-5 left-5 z-40">
            <Link to="/" className={cn("flex items-center gap-2 px-4 py-2 rounded-full text-[11px] font-display font-semibold uppercase tracking-[0.15em]", glass, glassStyle)}>
              ← Exit
            </Link>

            {/* chroma color swatches */}
            <div className={cn("mt-4 flex flex-col gap-2 rounded-2xl p-2.5 w-max", glass, glassStyle)}>
              {marksId === "checkerboard" ? (
                <span className="px-2 py-1 text-[10px] font-body tracking-wider">Black &amp; white only</span>
              ) : (
                vfxColors.map((c) => (
                  <Link key={c.id} to={`/vfx?color=${c.id}&marks=${marksId}`}
                    title={c.label}
                    className={cn("h-7 w-7 rounded-full border border-white/25 transition hover:scale-110",
                      colorId === c.id ? "ring-2 ring-amber ring-offset-2 ring-offset-black/60" : "hover:border-white/60")}
                    style={{ background: c.hex }} />
                ))
              )}
            </div>

            {/* add markers / save / reset customisation */}
            <div className={cn("mt-3 flex items-center gap-1 rounded-2xl p-1.5 w-max", glass, glassStyle)}>
              {isPoint && (
                <button onClick={addMarker} className={actionBtn}>
                  <Plus size={12} /> Add
                </button>
              )}
              <button onClick={saveScreen} className={actionBtn}>
                <Save size={12} /> Save
              </button>
              {marksId !== "none" && (
                <button onClick={resetCustomisation} className={actionBtn}>
                  <RotateCcw size={12} /> Reset
                </button>
              )}
            </div>
          </div>

          {/* vertical size / thickness sliders — right edge */}
          {marksId !== "none" && (
            <div className="absolute right-5 top-1/2 -translate-y-1/2 z-40 flex gap-3">
              <div className={cn("flex flex-col items-center gap-3 rounded-2xl px-3 py-4", glass, glassStyle)}>
                <span className="text-[9px] font-body uppercase tracking-[0.2em]">Size</span>
                <Slider orientation="vertical" className="h-32" value={[marks.scale]} min={0.5} max={3} step={0.25}
                  onValueChange={([v]) => update((m) => ({ scale: v }))} />
                <span className="text-[9px] font-body opacity-70">{Number(marks.scale.toFixed(2))}×</span>
              </div>
              {marksId !== "checkerboard" && (
                <div className={cn("flex flex-col items-center gap-3 rounded-2xl px-3 py-4", glass, glassStyle)}>
                  <span className="text-[9px] font-body uppercase tracking-[0.2em]">Thick</span>
                  <Slider orientation="vertical" className="h-32" value={[marks.thickness]} min={0.5} max={3} step={0.25}
                    onValueChange={([v]) => update((m) => ({ thickness: v }))} />
                  <span className="text-[9px] font-body opacity-70">{Number(marks.thickness.toFixed(2))}×</span>
                </div>
              )}
            </div>
          )}

          {/* tracking mark styles */}
          <div className={cn("absolute top-5 right-5 z-40 flex flex-wrap justify-end gap-1 rounded-2xl p-1.5 max-w-[320px]", glass, glassStyle)}>
            {trackingMarks.map((m) => (
              <Link key={m.id} to={`/vfx?color=${colorId}&marks=${m.id}`}
                className={cn("rounded-full px-3 py-1.5 text-[10px] font-body uppercase tracking-wider transition",
                  marksId === m.id ? "bg-amber text-black font-semibold" : "hover:bg-white/15")}>
                {m.name}
              </Link>
            ))}
          </div>

          {isPoint && (
            <div className="absolute bottom-16 inset-x-0 flex justify-center z-40 pointer-events-none">
              <div className={cn("px-3.5 py-1.5 rounded-full text-[10px] font-body tracking-wide", glass, glassStyle)}>
                Hold &amp; drag to move · tap to remove
              </div>
            </div>
          )}
          <div className="absolute bottom-6 inset-x-0 flex justify-center z-40 pointer-events-none">
            <div className={cn("px-4 py-2 rounded-full text-[11px] font-body tracking-wide flex items-center gap-2", glass, glassStyle)}>
              <span className="h-1.5 w-1.5 rounded-full bg-amber amber-pulse" />
              3-Finger Tap to Lock / Unlock
            </div>
          </div>
        </>
      )}

      {locked && (
        <div className="absolute top-3 right-4 z-40 pointer-events-none">
          <span className={cn("text-[10px] font-body tracking-[0.25em] opacity-60", isLight ? "text-black" : "text-white")}>LOCKED</span>
        </div>
      )}
    </div>
  );
}