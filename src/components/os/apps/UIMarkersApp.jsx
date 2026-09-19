import React, { useState, useRef, useEffect } from "react";
import { Lock, RotateCcw, Save } from "lucide-react";
import { saveConfig } from "@/lib/savedConfigs";
import { cn } from "@/lib/utils";

const COLS = 5;
const ROWS = 8;

export default function UIMarkersApp({ config, update, onLockChange }) {
  const markers = config.uiMarkers || {};
  const assignments = markers.assignments || {};
  const barRow = Math.max(0, Math.min(ROWS, markers.barRow ?? 7));
  const barCol = Math.max(1, Math.min(COLS, markers.barCol ?? COLS));
  const vStart = Math.max(1, Math.min(ROWS - 4, markers.barVRow ?? 1));
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

  // next free number across buttons, bars and fillers — never repeats
  const nextNumber = () => {
    const used = [...Object.values(assignments), Number(barNumber), Number(barVNumber)]
      .filter((n) => Number.isInteger(n) && n > 0);
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

  const saveLayout = () => {
    const name = window.prompt("Name this marker configuration:", `Markers ${new Date().toLocaleDateString()}`);
    if (!name) return;
    saveConfig({ kind: "markers", name: name.trim() || "Untitled", uiMarkers: markers });
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
        const col = Math.max(1, Math.min(COLS, Math.floor((e.clientX - rect.left) / band)));
        // slide up / down in whole-button steps, keeping the 6-button length
        const track = ((e.clientY - rect.top) / rect.height) * (ROWS + 1);
        const row = Math.max(1, Math.min(ROWS - 4, Math.round(track - 2.5)));
        saveMarkers((m) => (m.barCol === col && m.barVRow === row ? {} : { barCol: col, barVRow: row }));
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

  // one shared renderer for every standard grid cell — main buttons and the
  // cells around the bars, so there is never a gap anywhere on the grid
  const cellButton = (key, style) => {
    const assigned = assignments[key];
    const isPressed = pressedBtn === key;
    return (
      <button key={key} style={style}
        onPointerDown={locked ? () => setPressedBtn(key) : undefined}
        onPointerUp={locked ? () => setPressedBtn(null) : undefined}
        onPointerLeave={locked ? () => setPressedBtn(null) : undefined}
        onPointerCancel={locked ? () => setPressedBtn(null) : undefined}
        onClick={locked ? undefined : () => toggleAssign(key)}
        onContextMenu={(e) => e.preventDefault()}
        className={cn("rounded-xl border flex items-center justify-center text-base font-display select-none touch-none transition-colors",
          isPressed ? "border-foreground/50 marker-pulse" : "border-foreground/10",
          !locked && assigned != null && "text-foreground/90",
          !locked && "hover:border-foreground/30")}>
        {assigned != null ? assigned : ""}
      </button>
    );
  };

  const markerButton = (r, c) => cellButton(r * COLS + c, {
    gridColumn: c + (c >= barCol ? 1 : 0) + 1,
    gridRow: r + (r >= barRow ? 1 : 0) + 1,
  });

  // tap anywhere on a bar (edit mode) → next number appears, tap again to clear
  const toggleBarNumber = (key) => {
    if (suppressClick.current) { suppressClick.current = false; return; }
    saveMarkers((m) => (m[key] ? { [key]: "" } : { [key]: String(nextNumber()) }));
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
        pressedBar === "h" ? "border-foreground/50 marker-pulse" : "border-foreground/10")}>
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
        dragBar === "h" ? "border-foreground/50" : "border-foreground/10")}>
        {barNumber}
      </div>
    </div>
  );

  // vertical bar — fixed length of 6 small buttons, flush to the top edge of
  // its column; every cell the bars leave open holds a standard button, and a
  // cell covered by a bar never holds a small one
  const columnFillers = [];
  for (let t = 1; t <= ROWS + 1; t++) {
    if (t >= vStart && t <= vStart + 5) continue; // under the vertical bar
    if (t === barRow + 1) continue; // under the horizontal bar
    columnFillers.push(cellButton(`vc-${t}`, { gridColumn: barCol + 1, gridRow: t }));
  }

  const verticalBar = locked ? (
    <div style={{ gridColumn: barCol + 1, gridRow: `${vStart} / ${vStart + 6}` }}
      onPointerDown={() => setPressedBar("v")}
      onPointerUp={() => setPressedBar(null)}
      onPointerLeave={() => setPressedBar(null)}
      onPointerCancel={() => setPressedBar(null)}
      onContextMenu={(e) => e.preventDefault()}
      className={cn("rounded-xl border touch-none select-none transition-colors flex items-center justify-center text-base font-display",
        pressedBar === "v" ? "border-foreground/50 marker-pulse" : "border-foreground/10")}>
      {barVNumber}
    </div>
  ) : (
    <div style={{ gridColumn: barCol + 1, gridRow: `${vStart} / ${vStart + 6}` }}
      onPointerDown={(e) => onBarPointerDown(e, "v")}
      onPointerUp={cancelDrag}
      onPointerCancel={cancelDrag}
      onClick={() => toggleBarNumber("barVNumber")}
      onContextMenu={(e) => e.preventDefault()}
      className={cn("rounded-xl border touch-none select-none transition-colors flex items-center justify-center text-base font-display",
        dragBar === "v" ? "border-foreground/50 cursor-grabbing" : "border-foreground/10 cursor-grab")}>
      {barVNumber}
    </div>
  );

  return (
    <div className="relative h-full bg-background overflow-hidden">
      {/* floating edit HUD — hidden when locked, never affects the grid layout */}
      {!locked && (
        <div className="absolute top-2 inset-x-2 z-10 flex items-center justify-end pointer-events-none">
          <div className="flex items-center gap-2 pointer-events-auto">
            <button onClick={saveLayout}
              className="flex items-center gap-1 rounded-full border border-border px-2.5 py-1 text-[10px] font-body text-muted-foreground hover:text-foreground transition">
              <Save size={11} /> Save
            </button>
            <button onClick={resetNumbers}
              className="flex items-center gap-1 rounded-full border border-border px-2.5 py-1 text-[10px] font-body text-muted-foreground hover:text-foreground transition">
              <RotateCcw size={11} /> Reset
            </button>
            <button onClick={lock}
              className="flex items-center gap-1 rounded-full border border-border px-2.5 py-1 text-[10px] font-body text-muted-foreground hover:text-foreground transition">
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
        {columnFillers}
      </div>
      {locked && hint && (
        <div className="absolute inset-x-0 bottom-3 flex justify-center pointer-events-none">
          <span className="px-3 py-1 rounded-full text-[10px] font-body text-muted-foreground bg-muted backdrop-blur">
            3-finger tap to unlock
          </span>
        </div>
      )}
    </div>
  );
}