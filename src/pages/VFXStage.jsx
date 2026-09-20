import React, { useState, useEffect, useRef, useCallback } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { compositeMarks, getColor } from "@/lib/vfxData";
import SaveTargetSheet from "@/components/save/SaveTargetSheet";
import { TrackingMarks } from "@/components/vfx/TrackingMarks";
import useScreenMarks, { defaultLayoutFor } from "@/hooks/useScreenMarks";
import StageToolbar from "@/components/vfx/StageToolbar";

const POINT_STYLES = ["cross", "circles", "squares", "brackets", "triangle", ...compositeMarks.map((m) => m.id)];

export default function VFXStage() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const colorId = params.get("color") || "green";
  const marksId = params.get("marks") || "cross";
  const color = getColor(colorId);
  const { marks, update } = useScreenMarks();

  // light backgrounds get black auto-marks / grid lines
  const isLightHex = (hex) => {
    const m = /^#?([0-9a-f]{6})$/i.exec(hex || "");
    if (!m) return false;
    const n = parseInt(m[1], 16);
    return ((n >> 16) & 255) * 0.299 + ((n >> 8) & 255) * 0.587 + (n & 255) * 0.114 > 150;
  };
  const isLight = !marks.bgImage && (marks.bgColor ? isLightHex(marks.bgColor) : ["white", "green", "grey"].includes(colorId));
  const isPoint = POINT_STYLES.includes(marksId);
  const layout = isPoint ? (marks.layouts[marksId] ?? defaultLayoutFor(marksId)) : [];
  // which marker kind the "+" button adds - follows the current style
  const [addKind, setAddKind] = useState("cross");
  useEffect(() => { if (isPoint) setAddKind(marksId); }, [isPoint, marksId]);

  // drag snap grid mirrors the UI marker grid: 5 columns x 8 rows
  const snapC = (v, cells) => Math.min(100, Math.max(0, (Math.round((v / 100) * cells) / cells) * 100));
  // centre-line exception: x can also snap to the vertical centre / centre point
  const snapX = (v) => {
    const grid = snapC(v, 5);
    return Math.abs(50 - v) < Math.abs(grid - v) ? 50 : grid;
  };

  const [locked, setLocked] = useState(false);
  const [banner, setBanner] = useState(null);
  const [saveOpen, setSaveOpen] = useState(false);
  const [dragId, setDragId] = useState(null);
  const lastTap = useRef({ id: null, t: 0 });
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
        x: snapX((e.clientX / window.innerWidth) * 100),
        y: snapC((e.clientY / window.innerHeight) * 100, 8),
      }));
    };
    window.addEventListener("pointermove", move);
    return () => window.removeEventListener("pointermove", move);
  }, [dragId, marksId]);

  // release: end a drag; a tap rotates 45°, a double-tap deletes the marker
  useEffect(() => {
    const up = () => {
      clearTimeout(holdTimer.current);
      const tapped = pendingId.current;
      pendingId.current = null;
      if (dragId) { setDragId(null); return; }
      if (!tapped) return;
      const now = Date.now();
      if (lastTap.current.id === tapped && now - lastTap.current.t < 350) {
        lastTap.current = { id: null, t: 0 };
        updateLayout((list) => list.filter((m) => m.id !== tapped));
      } else {
        lastTap.current = { id: tapped, t: now };
        rotateMarker(tapped);
      }
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
    markColor: null,
    bgColor: null,
    bgImage: null,
    layouts: { ...m.layouts, [marksId]: defaultLayoutFor(marksId) },
  }));

  // saving offers a choice: the Saved card (favourites) or this device's folder
  const saveScreen = () => setSaveOpen(true);

  return (
    <div className="fixed inset-0 z-50 overflow-hidden"
      style={marks.bgImage
        ? { backgroundImage: `url("${marks.bgImage}")`, backgroundSize: "cover", backgroundPosition: "center" }
        : { background: marks.bgColor || color.hex }}>
      <TrackingMarks type={marksId} color={marks.markColor || (isLight ? "#000000" : "#FFFFFF")}
        opacity={marksId === "checkerboard" ? 1 : 0.85}
        size={marks.scale} thickness={marks.thickness}
        markers={layout} dragId={dragId}
        onMarkerDown={!locked && isPoint ? onMarkerDown : undefined} />

      {/* temporary snap grid while dragging a marker */}
      {dragId && (
        <div className="absolute inset-0 pointer-events-none" style={{
          backgroundImage: `linear-gradient(to right, ${isLight ? "rgba(0,0,0,0.3)" : "rgba(255,255,255,0.3)"} 1px, transparent 1px), linear-gradient(to bottom, ${isLight ? "rgba(0,0,0,0.3)" : "rgba(255,255,255,0.3)"} 1px, transparent 1px)`,
          backgroundSize: `${100 / 5}% ${100 / 8}%`,
        }}>
          {/* centre line + centre screen point */}
          <div className="absolute inset-y-0 left-1/2 w-px" style={{ background: isLight ? "rgba(0,0,0,0.45)" : "rgba(255,255,255,0.45)" }} />
          <span className="absolute left-1/2 top-1/2 h-1.5 w-1.5 -translate-x-1/2 -translate-y-1/2 rounded-full"
            style={{ background: isLight ? "#000000" : "#FFFFFF", opacity: 0.9 }} />
        </div>
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
                Hold &amp; drag to move · tap to rotate · double-tap to delete
              </div>
            </div>
          )}
          <StageToolbar
            colorId={colorId} marksId={marksId} isPoint={isPoint} marks={marks}
            addKind={addKind} onSelectAddKind={setAddKind} onRotateAll={rotateAll}
            onSelectColor={(id) => { update((m) => ({ bgColor: null })); navigate(`/vfx?color=${id}&marks=${marksId}`); }}
            onSelectMarks={(id) => navigate(`/vfx?color=${colorId}&marks=${id}`)}
            onScale={(v) => update((m) => ({ scale: v }))}
            onThick={(v) => update((m) => ({ thickness: v }))}
            onMarkColor={(v) => update((m) => ({ markColor: v }))}
            onBgColor={(v) => update((m) => ({ bgColor: v }))}
            onBgImage={(v) => update((m) => ({ bgImage: v }))}
            onAdd={addMarker} onSave={saveScreen} onReset={resetCustomisation}
          />
        </>
      )}

      {saveOpen && (
        <SaveTargetSheet title="Save screen" defaultName={`${marksId} · ${colorId}`}
          build={(n) => ({ kind: "screen", name: n, colorId, marksId, marks })}
          onClose={() => setSaveOpen(false)} />
      )}
    </div>
  );
}