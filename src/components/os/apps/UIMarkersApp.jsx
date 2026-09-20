import React, { useState, useRef, useEffect } from "react";
import { Check, Lock, Palette, RotateCcw, Save, Shapes } from "lucide-react";
import SaveTargetSheet from "@/components/save/SaveTargetSheet";
import MarkAdjust from "@/components/os/MarkAdjust";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { TrackingMarks } from "@/components/vfx/TrackingMarks";
import { defaultLayoutFor } from "@/hooks/useScreenMarks";
import { compositeMarks, vfxColors } from "@/lib/vfxData";
import { cn } from "@/lib/utils";

const MARK_STYLES = [
  { id: "cross", label: "Cross" },
  { id: "circles", label: "Targets" },
  { id: "squares", label: "Squares" },
  { id: "brackets", label: "Brackets" },
  { id: "diamond", label: "Diamond" },
  { id: "triangle", label: "Triangle" },
  ...compositeMarks,
];

const COLS = 5;
const ROWS = 8;

export default function UIMarkersApp({ config, update, onLockChange }) {
  const markers = config.uiMarkers || {};
  const assignments = markers.assignments || {};
  const barRow = Math.max(0, Math.min(ROWS, markers.barRow ?? ROWS - 1));
  const barCol = Math.max(1, Math.min(COLS, markers.barCol ?? COLS));
  const vStart = Math.max(1, Math.min(ROWS - 4, markers.barVRow ?? 1));
  const barNumber = markers.barNumber ?? "";
  const barVNumber = markers.barVNumber ?? "";
  const bgColor = markers.bgColor ?? null;
  const markStyle = markers.markStyle ?? "none";

  // colors follow the mock OS theme (Settings - Themes)
  const light = config.theme === "light";
  const line = light ? "border-black/10" : "border-white/10";
  const strongLine = light ? "border-black/50" : "border-white/50";
  const lineHover = light ? "hover:border-black/30" : "hover:border-white/30";
  const txt = light ? "text-black/90" : "text-white/90";

  const [locked, setLocked] = useState(false);
  const [hint, setHint] = useState(false);
  const [saveOpen, setSaveOpen] = useState(false);
  const [pressedBtn, setPressedBtn] = useState(null);
  const [pressedBar, setPressedBar] = useState(null);
  const [dragBar, setDragBar] = useState(null); // "h" | "v"
  const containerRef = useRef(null);
  const holdTimer = useRef(null);
  const suppressClick = useRef(false);
  const [dragMark, setDragMark] = useState(null);
  const holdMarkTimer = useRef(null);
  const pendingMarkId = useRef(null);
  const lastMarkTap = useRef({ id: null, t: 0 });

  useEffect(() => { onLockChange?.(locked); }, [locked]);

  const saveMarkers = (patch) => update((c) => ({
    uiMarkers: {
      ...(c.uiMarkers || {}),
      ...(typeof patch === "function" ? patch(c.uiMarkers || {}) : patch),
    },
  }));

  // next free number across buttons, bars and fillers - never repeats
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

  // saving offers a choice: the Saved card (favourites) or this device's folder
  const saveLayout = () => setSaveOpen(true);

  // tracking marks: auto contrast against the background
  const isLightHex = (hex) => {
    const m = /^#?([0-9a-f]{6})$/i.exec(hex || "");
    if (!m) return false;
    const n = parseInt(m[1], 16);
    return ((n >> 16) & 255) * 0.299 + ((n >> 8) & 255) * 0.587 + (n & 255) * 0.114 > 150;
  };
  const markColor = bgColor ? (isLightHex(bgColor) ? "#000000" : "#FFFFFF") : (light ? "#000000" : "#FFFFFF");

  // per-style tracking-mark layout - draggable, rotatable, persisted
  const markLayout = markers.markLayouts?.[markStyle] || defaultLayoutFor(markStyle);
  const updateMarkLayout = (fn) => saveMarkers((m) => ({
    markLayouts: {
      ...(m.markLayouts || {}),
      [markStyle]: fn(m.markLayouts?.[markStyle] || defaultLayoutFor(markStyle)),
    },
  }));

  // snap grid lines sit in the gaps between the grid buttons (the long bars
  // are the exception - lines simply run across them)
  const snapLines = (rect) => {
    const pad = 4, gap = 4;
    const cols = COLS + 1, rows = ROWS + 1;
    const tw = (rect.width - 2 * pad - (cols - 1) * gap) / cols;
    const th = (rect.height - 2 * pad - (rows - 1) * gap) / rows;
    return {
      // grid lines plus the centre-line exception, so the middle marker can
      // sit exactly on the centre screen point
      xs: [...Array.from({ length: cols - 1 }, (_, i) => pad + i * (tw + gap) + tw + gap / 2), rect.width / 2],
      ys: Array.from({ length: rows - 1 }, (_, i) => pad + i * (th + gap) + th + gap / 2),
    };
  };
  const nearest = (v, arr) => arr.reduce((a, b) => (Math.abs(b - v) < Math.abs(a - v) ? b : a));

  const onMarkDown = (id, e) => {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    clearTimeout(holdMarkTimer.current);
    pendingMarkId.current = id;
    holdMarkTimer.current = setTimeout(() => { pendingMarkId.current = null; setDragMark(id); }, 250);
  };

  // drag a mark - snaps to the button-gap grid lines
  useEffect(() => {
    if (!dragMark) return;
    const move = (e) => {
      const rect = containerRef.current?.getBoundingClientRect();
      if (!rect) return;
      const { xs, ys } = snapLines(rect);
      const x = Math.max(2, Math.min(98, (nearest(e.clientX - rect.left, xs) / rect.width) * 100));
      const y = Math.max(2, Math.min(98, (nearest(e.clientY - rect.top, ys) / rect.height) * 100));
      updateMarkLayout((list) => list.map((m) => (m.id !== dragMark ? m : { ...m, x, y })));
    };
    window.addEventListener("pointermove", move);
    return () => window.removeEventListener("pointermove", move);
  }, [dragMark, markStyle]);

  // the first time a mark style is shown, place its default marks on the
  // grid intersections (button gaps)
  useEffect(() => {
    if (locked || markStyle === "none" || markers.markLayouts?.[markStyle]) return;
    const rect = containerRef.current?.getBoundingClientRect();
    if (!rect || !rect.width || !rect.height) return;
    const { xs, ys } = snapLines(rect);
    const layout = defaultLayoutFor(markStyle).map((m) => ({
      ...m,
      x: (nearest((m.x / 100) * rect.width, xs) / rect.width) * 100,
      y: (nearest((m.y / 100) * rect.height, ys) / rect.height) * 100,
    }));
    saveMarkers((mm) => ({ markLayouts: { ...(mm.markLayouts || {}), [markStyle]: layout } }));
  }, [markStyle, locked]);

  // release: end a drag; a tap rotates the mark 45°, a double-tap deletes it
  useEffect(() => {
    if (locked || markStyle === "none") return;
    const up = () => {
      clearTimeout(holdMarkTimer.current);
      const tapped = pendingMarkId.current;
      pendingMarkId.current = null;
      if (dragMark) { setDragMark(null); return; }
      if (!tapped) return;
      const now = Date.now();
      if (lastMarkTap.current.id === tapped && now - lastMarkTap.current.t < 350) {
        lastMarkTap.current = { id: null, t: 0 };
        updateMarkLayout((list) => list.filter((m) => m.id !== tapped));
      } else {
        lastMarkTap.current = { id: tapped, t: now };
        updateMarkLayout((list) => list.map((m) => (m.id !== tapped ? m : { ...m, rot: ((m.rot || 0) + 45) % 360 })));
      }
    };
    window.addEventListener("pointerup", up);
    window.addEventListener("pointercancel", up);
    return () => {
      window.removeEventListener("pointerup", up);
      window.removeEventListener("pointercancel", up);
    };
  }, [dragMark, markStyle, locked]);

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

  // grid tracks - 1fr everywhere, so bars are exactly as thick as buttons
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

  // one shared renderer for every standard grid cell - main buttons and the
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
          locked && assigned == null ? "border-transparent" : isPressed ? `${strongLine} marker-pulse` : line,
          !locked && assigned != null && txt,
          !locked && lineHover)}>
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
        barNumber ? (pressedBar === "h" ? `${strongLine} marker-pulse` : line) : "border-transparent")}>
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
        dragBar === "h" ? strongLine : line)}>
        {barNumber}
      </div>
    </div>
  );

  // vertical bar - fixed length of 6 small buttons, flush to the top edge of
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
        barVNumber ? (pressedBar === "v" ? `${strongLine} marker-pulse` : line) : "border-transparent")}>
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
        dragBar === "v" ? `${strongLine} cursor-grabbing` : `${line} cursor-grab`)}>
      {barVNumber}
    </div>
  );

  return (
    <div className={cn("relative h-full overflow-hidden", light ? "text-black" : "text-white")}
      style={bgColor ? { background: bgColor } : (light ? { background: "#f2f2f7" } : { background: "#0b0b0f" })}>
      {/* floating edit HUD - hidden when locked, never affects the grid layout */}
      {!locked && (
        <div className="absolute top-2 inset-x-2 z-10 flex items-center justify-end pointer-events-none">
          <div className="flex items-center gap-2 pointer-events-auto">
            <Popover>
              <PopoverTrigger asChild>
                <button title="Background colour"
                  className={cn("flex items-center gap-1 rounded-full border px-2.5 py-1 text-[10px] font-body transition", light ? "border-black/10 text-black/50 hover:text-black" : "border-white/10 text-white/50 hover:text-white")}>
                  <Palette size={11} />
                  <span className="h-2.5 w-2.5 rounded-full border border-current"
                    style={bgColor ? { background: bgColor } : (light ? { background: "#0b0b0f" } : { background: "#f2f2f7" })} />
                </button>
              </PopoverTrigger>
              <PopoverContent side="bottom" align="end" className="w-44 p-2 border-white/15 bg-black/80 text-white backdrop-blur-xl shadow-2xl">
                <button onClick={() => saveMarkers({ bgColor: null })}
                  className="flex w-full items-center gap-2.5 rounded-lg px-2 py-1.5 text-[11px] font-body transition hover:bg-white/10">
                  <span className="h-4 w-4 rounded-full border border-white/25"
                    style={{ background: light ? "#f2f2f7" : "#0b0b0f" }} />
                  Theme default
                  {!bgColor && <Check size={12} className="ml-auto text-amber" />}
                </button>
                {vfxColors.map((c) => (
                  <button key={c.id} onClick={() => saveMarkers({ bgColor: c.hex })}
                    className="flex w-full items-center gap-2.5 rounded-lg px-2 py-1.5 text-[11px] font-body transition hover:bg-white/10">
                    <span className="h-4 w-4 rounded-full border border-white/25" style={{ background: c.hex }} />
                    {c.label}
                    {bgColor === c.hex && <Check size={12} className="ml-auto text-amber" />}
                  </button>
                ))}
                <label className="flex w-full items-center gap-2.5 rounded-lg px-2 py-1.5 text-[11px] font-body transition hover:bg-white/10 cursor-pointer">
                  <input type="color" value={bgColor || "#00A651"}
                    onChange={(e) => saveMarkers({ bgColor: e.target.value })}
                    className="h-4 w-4 shrink-0 cursor-pointer rounded-full border border-white/25 bg-transparent p-0" />
                  Custom colour
                </label>
              </PopoverContent>
            </Popover>
            <Popover>
              <PopoverTrigger asChild>
                <button title="Tracking marks"
                  className={cn("flex items-center gap-1 rounded-full border px-2.5 py-1 text-[10px] font-body transition", light ? "border-black/10 text-black/50 hover:text-black" : "border-white/10 text-white/50 hover:text-white")}>
                  <Shapes size={11} /> Marks
                </button>
              </PopoverTrigger>
              <PopoverContent side="bottom" align="end" className="w-44 p-1.5 border-white/15 bg-black/80 text-white backdrop-blur-xl shadow-2xl">
                <button onClick={() => saveMarkers({ markStyle: "none" })}
                  className="flex w-full items-center justify-between rounded-lg px-2.5 py-1.5 text-[10px] font-body uppercase tracking-wider transition hover:bg-white/10">
                  None
                  {markStyle === "none" && <Check size={12} className="text-amber" />}
                </button>
                {MARK_STYLES.map((s) => (
                  <button key={s.id} onClick={() => saveMarkers({ markStyle: s.id })}
                    className="flex w-full items-center justify-between rounded-lg px-2.5 py-1.5 text-[10px] font-body uppercase tracking-wider transition hover:bg-white/10">
                    {s.label}
                    {markStyle === s.id && <Check size={12} className="text-amber" />}
                  </button>
                ))}
                <MarkAdjust size={markers.markSize} thickness={markers.markThick} rot={markers.markRot}
                  onChange={(p) => saveMarkers({
                    ...(p.size !== undefined && { markSize: p.size }),
                    ...(p.thickness !== undefined && { markThick: p.thickness }),
                    ...(p.rot !== undefined && { markRot: p.rot }),
                  })} />
              </PopoverContent>
            </Popover>
            <button onClick={saveLayout}
              className={cn("flex items-center gap-1 rounded-full border px-2.5 py-1 text-[10px] font-body transition", light ? "border-black/10 text-black/50 hover:text-black" : "border-white/10 text-white/50 hover:text-white")}>
              <Save size={11} /> Save
            </button>
            <button onClick={resetNumbers}
              className={cn("flex items-center gap-1 rounded-full border px-2.5 py-1 text-[10px] font-body transition", light ? "border-black/10 text-black/50 hover:text-black" : "border-white/10 text-white/50 hover:text-white")}>
              <RotateCcw size={11} /> Reset
            </button>
            <button onClick={lock}
              className={cn("flex items-center gap-1 rounded-full border px-2.5 py-1 text-[10px] font-body transition", light ? "border-black/10 text-black/50 hover:text-black" : "border-white/10 text-white/50 hover:text-white")}>
              <Lock size={11} /> Lock
            </button>
          </div>
        </div>
      )}
      {/* edit-mode instructions - bottom, out of the way of the nav buttons */}
      {!locked && (
        <div className="absolute inset-x-0 bottom-3 z-10 flex justify-center pointer-events-none">
          <span className={cn("px-2.5 py-0.5 rounded-full text-[9px] font-body backdrop-blur", light ? "text-black/40 bg-black/5" : "text-white/40 bg-white/10")}>
            Tap to number · hold &amp; drag to rearrange
          </span>
        </div>
      )}
      {/* fixed full-screen grid - button size & position never change between modes */}
      <div ref={containerRef} className="absolute inset-0 grid p-1"
        style={{ gridTemplateColumns: colTemplate.join(" "), gridTemplateRows: rowTemplate.join(" "), gap: "4px" }}>
        {Array.from({ length: ROWS * COLS }, (_, i) => markerButton(Math.floor(i / COLS), i % COLS))}
        {horizontalBar}
        {verticalBar}
        {columnFillers}
      </div>
      {/* tracking marks overlay - follows the chosen background */}
      {markStyle !== "none" && (
        <>
          <TrackingMarks type={markStyle} color={markColor} opacity={0.85}
            size={markers.markSize ?? 1.1} thickness={markers.markThick ?? 0.6}
            markers={markers.markRot ? markLayout.map((m) => ({ ...m, rot: (m.rot || 0) + markers.markRot })) : markLayout}
            dragId={dragMark}
            onMarkerDown={!locked ? onMarkDown : undefined} />
          {/* temporary snap grid - lines sit in the button gaps */}
          {dragMark && (() => {
            const rect = containerRef.current?.getBoundingClientRect();
            if (!rect) return null;
            const { xs, ys } = snapLines(rect);
            return (
              <svg className="absolute inset-0 z-10 pointer-events-none" width={rect.width} height={rect.height}>
                {xs.map((x, i) => (
                  <line key={`x${i}`} x1={x} y1={0} x2={x} y2={rect.height} stroke={markColor} strokeWidth={1} strokeDasharray="4 4" opacity={0.45} />
                ))}
                {ys.map((y, i) => (
                  <line key={`y${i}`} x1={0} y1={y} x2={rect.width} y2={y} stroke={markColor} strokeWidth={1} strokeDasharray="4 4" opacity={0.45} />
                ))}
                <circle cx={rect.width / 2} cy={rect.height / 2} r={3} fill={markColor} opacity={0.9} />
              </svg>
            );
          })()}
        </>
      )}
      {locked && hint && (
        <div className="absolute inset-x-0 bottom-3 flex justify-center pointer-events-none">
          <span className={cn("px-3 py-1 rounded-full text-[10px] font-body backdrop-blur", light ? "text-black/50 bg-black/5" : "text-white/50 bg-white/10")}>
            3-finger tap to unlock
          </span>
        </div>
      )}
      {saveOpen && (
        <SaveTargetSheet title="Save marker layout" defaultName={`Markers ${new Date().toLocaleDateString()}`}
          build={(n) => ({ kind: "markers", name: n, uiMarkers: markers })}
          onClose={() => setSaveOpen(false)} />
      )}
    </div>
  );
}