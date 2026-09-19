import React, { useState, useEffect, useRef, useCallback } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { getColor } from "@/lib/vfxData";
import { saveConfig } from "@/lib/savedConfigs";
import { TrackingMarks } from "@/components/vfx/TrackingMarks";
import useScreenMarks, { defaultLayoutFor } from "@/hooks/useScreenMarks";
import StageToolbar from "@/components/vfx/StageToolbar";

const POINT_STYLES = ["cross", "circles", "squares", "brackets"];

export default function VFXStage() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const colorId = params.get("color") || "green";
  const marksId = params.get("marks") || "cross";
  const color = getColor(colorId);
  const isLight = ["white", "green", "grey"].includes(colorId);

  const { marks, update } = useScreenMarks();
  const isPoint = POINT_STYLES.includes(marksId);
  const layout = isPoint ? (marks.layouts[marksId] ?? defaultLayoutFor(marksId)) : [];
  // which marker kind the "+" button adds - follows the current style
  const [addKind, setAddKind] = useState("cross");
  useEffect(() => { if (isPoint) setAddKind(marksId); }, [isPoint, marksId]);

  const [locked, setLocked] = useState(false);
  const [banner, setBanner] = useState(null);
  const [dragId, setDragId] = useState(null);
  const lastTap = useRef({ id: null, t: 0 });
  const removeTimer = useRef(null);
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

  const addMarker = () => updateLayout((list) => [...list, { id: `m-${Date.now()}`, kind: addKind, x: 50, y: 50, rot: 0 }]);
  const rotateMarker = (id) => updateLayout((list) => list.map((m) => m.id !== id ? m : { ...m, rot: ((m.rot || 0) + 45) % 360 }));
  const rotateAll = () => updateLayout((list) => list.map((m) => ({ ...m, rot: ((m.rot || 0) + 45) % 360 })));

  const onMarkerDown = (id, e) => {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    pendingId.current = id;
    clearTimeout(holdTimer.current);
    holdTimer.current = setTimeout(() => { pendingId.current = null; setDragId(id); }, 250);
  };

  // move the held marker - snaps to a 5% grid
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

  // release: end a drag; a double-tap rotates 45°, a single tap removes
  useEffect(() => {
    const up = () => {
      clearTimeout(holdTimer.current);
      const tapped = pendingId.current;
      pendingId.current = null;
      if (dragId) { setDragId(null); return; }
      if (!tapped) return;
      const now = Date.now();
      if (lastTap.current.id === tapped && now - lastTap.current.t < 350) {
        clearTimeout(removeTimer.current);
        lastTap.current = { id: null, t: 0 };
        rotateMarker(tapped);
      } else {
        lastTap.current = { id: tapped, t: now };
        removeTimer.current = setTimeout(() => updateLayout((list) => list.filter((m) => m.id !== tapped)), 350);
      }
    };
    window.addEventListener("pointerup", up);
    window.addEventListener("pointercancel", up);
    return () => {
      window.removeEventListener("pointerup", up);
      window.removeEventListener("pointercancel", up);
      clearTimeout(removeTimer.current);
    };
  }, [dragId, marksId]);

  const resetCustomisation = () => update((m) => ({
    scale: 1,
    thickness: 1,
    markColor: null,
    layouts: { ...m.layouts, [marksId]: defaultLayoutFor(marksId) },
  }));

  const saveScreen = () => {
    const name = window.prompt("Name this screen:", `${marksId} · ${colorId}`);
    if (!name) return;
    saveConfig({ kind: "screen", name: name.trim() || "Untitled", colorId, marksId, marks });
  };

  return (
    <div className="fixed inset-0 z-50 overflow-hidden" style={{ background: color.hex }}>
      <TrackingMarks type={marksId} color={marks.markColor || (isLight ? "#000000" : "#FFFFFF")}
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
          <div className="px-5 py-2.5 rounded-full font-display font-bold text-xs tracking-[0.25em] bg-black/55 text-white border border-white/15 shadow-2xl backdrop-blur-xl">
            {banner}
          </div>
        </div>
      )}

      {/* unlocked: single tucked-away toolbar */}
      {!locked && (
        <>
          {isPoint && (
            <div className="absolute bottom-36 inset-x-0 flex justify-center z-40 pointer-events-none">
              <div className="px-3.5 py-1.5 rounded-full text-[10px] font-body tracking-wide bg-black/55 text-white border border-white/15 shadow-2xl backdrop-blur-xl">
                Hold &amp; drag to move · double-tap to rotate · tap to remove
              </div>
            </div>
          )}
          <StageToolbar
            colorId={colorId} marksId={marksId} isPoint={isPoint} marks={marks}
            addKind={addKind} onSelectAddKind={setAddKind} onRotateAll={rotateAll}
            onSelectColor={(id) => navigate(`/vfx?color=${id}&marks=${marksId}`)}
            onSelectMarks={(id) => navigate(`/vfx?color=${colorId}&marks=${id}`)}
            onScale={(v) => update((m) => ({ scale: v }))}
            onThick={(v) => update((m) => ({ thickness: v }))}
            onMarkColor={(v) => update((m) => ({ markColor: v }))}
            onAdd={addMarker} onSave={saveScreen} onReset={resetCustomisation}
          />
        </>
      )}

    </div>
  );
}