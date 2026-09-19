import React, { useState, useRef, useEffect } from "react";
import { Lock, RotateCcw } from "lucide-react";
import { cn } from "@/lib/utils";

const COLS = 5;
const ROWS = 8;

export default function UIMarkersApp({ config, update, onLockChange }) {
  const markers = config.uiMarkers || {};
  const assignments = markers.assignments || {};
  const barRow = markers.barRow ?? 7;
  const barCol = markers.barCol ?? 5;
  const barNumber = markers.barNumber ?? "";
  const barVNumber = markers.barVNumber ?? "";

  const [locked, setLocked] = useState(false);
  const [hint, setHint] = useState(false);
  const [pressedBtn, setPressedBtn] = useState(null);
  const [pressedBar, setPressedBar] = useState(null);
  const [dragBar, setDragBar] = useState(null); // "h" | "v"
  const containerRef = useRef(null);
  const holdTimer = useRef(null);
  const suppressClick = useRef(false);

  useEffect(() => { onLockChange?.(locked); }, [locked]);

  const saveMarkers = (patch) => update((c) => ({
    uiMarkers: {
      ...(c.uiMarkers || {}),
      ...(typeof patch === "function" ? patch(c.uiMarkers || {}) : patch),
    },
  }));

  const nextNumber = () => {
    const used = Object.values(assignments);
    return used.length ? Math.max(...used) + 1 : 1;
  };

  const toggleAssign = (i) => {
    if (assignments[i] != null) {
      const next = { ...assignments };
      delete next[i];
      saveMarkers({ assignments: next });
    } else {
      saveMarkers({ assignments: { ...assignments, [i]: nextNumber() } });
    }
  };

  const resetNumbers = () => saveMarkers({ assignments: {}, barNumber: "", barVNumber: "" });

  const lock = () => {
    setLocked(true);
    setHint(true);
    setTimeout(() => setHint(false), 2400);
  };

  // 3-finger tap to unlock
  useEffect(() => {
    if (!locked) return;
    const onTouch = (e) => { if (e.touches.length >= 3) setLocked(false); };
    window.addEventListener("touchstart", onTouch, { passive: true });
    return () => window.removeEventListener("touchstart", onTouch);
  }, [locked]);

  // hold a bar (edit mode) → drag it to a new row (horizontal) / column (vertical)
  const onBarPointerDown = (e, which) => {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    clearTimeout(holdTimer.current);
    holdTimer.current = setTimeout(() => { suppressClick.current = true; setDragBar(which); }, 250);
  };

  const cancelDrag = () => {
    clearTimeout(holdTimer.current);
    setDragBar(null);
  };

  useEffect(() => {
    if (!dragBar) return;
    const move = (e) => {
      const rect = containerRef.current?.getBoundingClientRect();
      if (!rect) return;
      if (dragBar === "h") {
        const band = rect.height / (ROWS + 1);
        const row = Math.max(0, Math.min(ROWS, Math.floor((e.clientY - rect.top) / band)));
        saveMarkers((m) => (m.barRow === row ? {} : { barRow: row }));
      } else {
        const band = rect.width / (COLS + 1);
        const col = Math.max(0, Math.min(COLS, Math.floor((e.clientX - rect.left) / band)));
        saveMarkers((m) => (m.barCol === col ? {} : { barCol: col }));
      }
    };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", cancelDrag);
    window.addEventListener("pointercancel", cancelDrag);
    return () => {
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", cancelDrag);
      window.removeEventListener("pointercancel", cancelDrag);
    };
  }, [dragBar]);

  // grid tracks — 1fr everywhere, so bars are exactly as thick as buttons
  const colTemplate = [];
  for (let c = 0; c <= COLS; c++) {
    if (c === barCol) colTemplate.push("1fr");
    if (c < COLS) colTemplate.push("1fr");
  }
  const rowTemplate = [];
  for (let r = 0; r <= ROWS; r++) {
    if (r === barRow) rowTemplate.push("1fr");
    if (r < ROWS) rowTemplate.push("1fr");
  }

  const markerButton = (r, c) => {
    const i = r * COLS + c;
    const assigned = assignments[i];
    const isPressed = pressedBtn === i;
    return (
      <button key={i}
        style={{ gridColumn: c + (c >= barCol ? 1 : 0) + 1, gridRow: r + (r >= barRow ? 1 : 0) + 1 }}
        onPointerDown={locked ? () => setPressedBtn(i) : undefined}
        onPointerUp={locked ? () => setPressedBtn(null) : undefined}
        onPointerLeave={locked ? () => setPressedBtn(null) : undefined}
        onPointerCancel={locked ? () => setPressedBtn(null) : undefined}
        onClick={locked ? undefined : () => toggleAssign(i)}
        onContextMenu={(e) => e.preventDefault()}
        className={cn("rounded-xl border flex items-center justify-center text-base font-display select-none touch-none transition-colors",
          isPressed ? "bg-white/30 border-white/70 marker-pulse" : "bg-white/10 border-white/15",
          !locked && assigned != null && "border-amber/60 text-amber",
          !locked && "hover:border-white/40")}>
        {assigned != null ? assigned : ""}
      </button>
    );
  };

  // smaller filler buttons that fill the gaps above / below the vertical bar
  const smallButton = (id) => {
    const assigned = assignments[id];
    const isPressed = pressedBtn === id;
    return (
      <button key={id}
        onPointerDown={locked ? () => setPressedBtn(id) : undefined}
        onPointerUp={locked ? () => setPressedBtn(null) : undefined}
        onPointerLeave={locked ? () => setPressedBtn(null) : undefined}
        onPointerCancel={locked ? () => setPressedBtn(null) : undefined}
        onClick={locked ? undefined : () => toggleAssign(id)}
        onContextMenu={(e) => e.preventDefault()}
        className={cn("flex-1 min-h-0 rounded-lg border flex items-center justify-center text-sm font-display select-none touch-none transition-colors",
          isPressed ? "bg-white/30 border-white/70 marker-pulse" : "bg-white/10 border-white/15",
          !locked && assigned != null && "border-amber/60 text-amber",
          !locked && "hover:border-white/40")}>
        {assigned != null ? assigned : ""}
      </button>
    );
  };

  // tap anywhere on a bar (edit mode) → next number appears, tap again to clear
  const toggleBarNumber = (key) => {
    if (suppressClick.current) { suppressClick.current = false; return; }
    const used = [...Object.values(assignments), Number(barNumber), Number(barVNumber)]
      .filter((n) => Number.isInteger(n) && n > 0);
    const next = used.length ? Math.max(...used) + 1 : 1;
    saveMarkers((m) => (m[key] ? { [key]: "" } : { [key]: String(next) }));
  };

  const horizontalBar = locked ? (
    <div
      style={{ gridColumn: "1 / -1", gridRow: barRow + 1 }}
      onPointerDown={() => setPressedBar("h")}
      onPointerUp={() => setPressedBar(null)}
      onPointerLeave={() => setPressedBar(null)}
      onPointerCancel={() => setPressedBar(null)}
      onContextMenu={(e) => e.preventDefault()}
      className="flex items-center justify-center">
      <div className={cn("w-full h-full rounded-xl border touch-none select-none transition-colors flex items-center justify-center text-base font-display",
        pressedBar === "h" ? "bg-white/30 border-white/70 marker-pulse" : "bg-white/10 border-white/15")}>
        {barNumber}
      </div>
    </div>
  ) : (
    <div
      style={{ gridColumn: "1 / -1", gridRow: barRow + 1 }}
      onPointerDown={(e) => onBarPointerDown(e, "h")}
      onPointerUp={cancelDrag}
      onPointerCancel={cancelDrag}
      onClick={() => toggleBarNumber("barNumber")}
      onContextMenu={(e) => e.preventDefault()}
      className={cn("flex items-center justify-center", dragBar === "h" ? "cursor-grabbing" : "cursor-grab")}>
      <div className={cn("w-full h-full rounded-xl border touch-none select-none transition-colors flex items-center justify-center text-base font-display",
        dragBar === "h" ? "bg-white/30 border-white/70" : "bg-amber/15 border-amber/50")}>
        {barNumber}
      </div>
    </div>
  );

  // vertical bar spans the same 6 tracks as the horizontal bar (h-2/3),
  // with three smaller buttons filling each gap above and below it
  const verticalBar = locked ? (
    <div style={{ gridColumn: barCol + 1, gridRow: "1 / -1" }} className="flex flex-col gap-1">
      <div className="flex-1 min-h-0 flex flex-col gap-1">
        {["vt0", "vt1", "vt2"].map(smallButton)}
      </div>
      <div className="h-2/3 shrink-0"
        onPointerDown={() => setPressedBar("v")}
        onPointerUp={() => setPressedBar(null)}
        onPointerLeave={() => setPressedBar(null)}
        onPointerCancel={() => setPressedBar(null)}
        onContextMenu={(e) => e.preventDefault()}>
        <div className={cn("w-full h-full rounded-xl border touch-none select-none transition-colors flex items-center justify-center text-base font-display",
          pressedBar === "v" ? "bg-white/30 border-white/70 marker-pulse" : "bg-white/10 border-white/15")}>
          {barVNumber}
        </div>
      </div>
      <div className="flex-1 min-h-0 flex flex-col gap-1">
        {["vb0", "vb1", "vb2"].map(smallButton)}
      </div>
    </div>
  ) : (
    <div style={{ gridColumn: barCol + 1, gridRow: "1 / -1" }} className="flex flex-col gap-1">
      <div className="flex-1 min-h-0 flex flex-col gap-1">
        {["vt0", "vt1", "vt2"].map(smallButton)}
      </div>
      <div
        onPointerDown={(e) => onBarPointerDown(e, "v")}
        onPointerUp={cancelDrag}
        onPointerCancel={cancelDrag}
        onClick={() => toggleBarNumber("barVNumber")}
        onContextMenu={(e) => e.preventDefault()}
        className={cn("h-2/3 shrink-0", dragBar === "v" ? "cursor-grabbing" : "cursor-grab")}>
        <div className={cn("w-full h-full rounded-xl border touch-none select-none transition-colors flex items-center justify-center text-base font-display",
          dragBar === "v" ? "bg-white/30 border-white/70" : "bg-amber/15 border-amber/50")}>
          {barVNumber}
        </div>
      </div>
      <div className="flex-1 min-h-0 flex flex-col gap-1">
        {["vb0", "vb1", "vb2"].map(smallButton)}
      </div>
    </div>
  );

  return (
    <div className="relative h-full bg-[#0b0b0f] overflow-hidden">
      {/* floating edit HUD — hidden when locked, never affects the grid layout */}
      {!locked && (
        <div className="absolute top-2 inset-x-2 z-10 flex items-center justify-between pointer-events-none">
          <span className="px-2.5 py-1 rounded-full text-[10px] uppercase tracking-wider text-white/50 font-body bg-white/10 backdrop-blur pointer-events-auto">UI Markers · Edit</span>
          <div className="flex items-center gap-2 pointer-events-auto">
            <button onClick={resetNumbers}
              className="flex items-center gap-1 rounded-full border border-white/20 px-2.5 py-1 text-[10px] font-body text-white/70 hover:text-white transition">
              <RotateCcw size={11} /> Reset
            </button>
            <button onClick={lock}
              className="flex items-center gap-1 rounded-full border border-white/20 px-2.5 py-1 text-[10px] font-body text-white/70 hover:text-white transition">
              <Lock size={11} /> Lock
            </button>
          </div>
        </div>
      )}
      {/* fixed full-screen grid — button size & position never change between modes */}
      <div ref={containerRef} className="absolute inset-0 grid p-1"
        style={{ gridTemplateColumns: colTemplate.join(" "), gridTemplateRows: rowTemplate.join(" "), gap: "4px" }}>
        {Array.from({ length: ROWS * COLS }, (_, i) => markerButton(Math.floor(i / COLS), i % COLS))}
        {horizontalBar}
        {verticalBar}
      </div>
      {locked && hint && (
        <div className="absolute inset-x-0 bottom-3 flex justify-center pointer-events-none">
          <span className="px-3 py-1 rounded-full text-[10px] font-body text-white/70 bg-white/10 backdrop-blur">
            3-finger tap to unlock
          </span>
        </div>
      )}
    </div>
  );
}