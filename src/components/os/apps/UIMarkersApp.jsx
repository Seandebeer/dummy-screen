import React, { useState, useRef, useEffect } from "react";
import { Check, Eye, EyeOff, ImagePlus, Lock, Palette, RotateCcw, Save, Shapes } from "lucide-react";
import SaveTargetSheet from "@/components/save/SaveTargetSheet";
import MarkAdjust from "@/components/os/MarkAdjust";
import { DEFAULT_OVERLAY, OverlayControl, OverlayLayer } from "@/components/vfx/OverlayImage";
import ThreeFingerHint from "@/components/os/ThreeFingerHint";
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
  const barNumsOf = (v) => (Array.isArray(v) ? v : v ? [Number(v)] : []);
  const barNumber = barNumsOf(markers.barNumber);
  const barVNumber = barNumsOf(markers.barVNumber);
  const bgColor = markers.bgColor ?? null;
  const markStyle = markers.markStyle ?? "none";
  const overlay = { ...DEFAULT_OVERLAY, ...(markers.overlay || {}) };

  // lines auto-contrast with the chosen background - always black by default
  const isLightHex = (hex) => {
    const m = /^#?([0-9a-f]{6})$/i.exec(hex || "");
    if (!m) return false;
    const n = parseInt(m[1], 16);
    return ((n >> 16) & 255) * 0.299 + ((n >> 8) & 255) * 0.587 + (n & 255) * 0.114 > 150;
  };
  const light = bgColor ? isLightHex(bgColor) : false;
  const line = light ? "border-black/10" : "border-white/10";
  const strongLine = light ? "border-black/50" : "border-white/50";
  const lineHover = light ? "hover:border-black/30" : "hover:border-white/30";
  const txt = light ? "text-black/90" : "text-white/90";
  // tool pills always render with a solid dark fill, whatever the background
  const pill = "flex items-center gap-1 rounded-full border border-white/15 bg-[#1c1c1e] px-2.5 py-1 text-[10px] font-body text-white/50 transition hover:text-white";
  // bottom tool pills sit lighter - half-opacity fill over the grid
  const toolPill = "flex items-center gap-1 rounded-full border border-white/15 bg-[#1c1c1e]/50 px-2.5 py-1 text-[10px] font-body text-white/50 transition hover:text-white";

  const [locked, setLocked] = useState(false);
  const [hint, setHint] = useState(false);
  const [saveOpen, setSaveOpen] = useState(false);
  const [pressedBtn, setPressedBtn] = useState(null);
  const [pressedBar, setPressedBar] = useState(null);
  const [dragBar, setDragBar] = useState(null); // "h" | "v"
  const barMoved = useRef(false);
  const barStart = useRef({ x: 0, y: 0 });
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

  // numbers on one button - older layouts store a single number, new ones arrays
  const numbersOn = (i) => {
    const v = assignments[i];
    return Array.isArray(v) ? v : v != null ? [v] : [];
  };

  // next free number across buttons, bars and fillers - never repeats
  const nextNumber = () => {
    const used = [
      ...Object.values(assignments).flatMap((v) => (Array.isArray(v) ? v : v != null ? [v] : [])),
      ...barNumber, ...barVNumber,
    ].filter((n) => Number.isInteger(n) && n > 0);
    return used.length ? Math.max(...used) + 1 : 1;
  };

  // tap → add another number to the button (multiple allowed)
  const addNumber = (i) => {
    saveMarkers({ assignments: { ...assignments, [i]: [...numbersOn(i), nextNumber()] } });
  };

  // deletion closes the gaps: every remaining number shifts down so the
  // sequence stays 1..N in the same press order (bars included)
  const renumber = (next) => {
    const entries = [];
    Object.entries(next.assignments).forEach(([key, v]) =>
      (Array.isArray(v) ? v : v != null ? [v] : []).forEach((n) => entries.push({ key, n })));
    [["barNumber", next.barNumber], ["barVNumber", next.barVNumber]].forEach(([key, v]) =>
      barNumsOf(v).forEach((n) => entries.push({ key, n })));
    entries.sort((a, b) => a.n - b.n);
    const out = { assignments: {} };
    entries.forEach((e, i) => {
      if (e.key === "barNumber" || e.key === "barVNumber") (out[e.key] ??= []).push(i + 1);
      else (out.assignments[e.key] ??= []).push(i + 1);
    });
    return out;
  };

  // hold → clear every number on the button; the rest renumber to close the gap
  const clearNumber = (i) => {
    if (numbersOn(i).length === 0) return;
    const next = { ...assignments };
    delete next[i];
    saveMarkers((m) => {
      const seq = renumber({ assignments: next, barNumber: m.barNumber || "", barVNumber: m.barVNumber || "" });
      return { assignments: seq.assignments, barNumber: seq.barNumber, barVNumber: seq.barVNumber };
    });
  };

  const resetNumbers = () => saveMarkers({ assignments: {}, barNumber: "", barVNumber: "" });

  const lock = () => {
    setLocked(true);
    setHint(true);
    setTimeout(() => setHint(false), 2400);
  };

  // saving offers a choice: the Saved card (favourites) or this device's folder
  const saveLayout = () => setSaveOpen(true);

  // tracking marks: chosen colour, or auto contrast against the background
  const markColor = markers.markColor || (bgColor ? (isLightHex(bgColor) ? "#000000" : "#FFFFFF") : "#FFFFFF");

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
    barStart.current = { x: e.clientX, y: e.clientY };
    barMoved.current = false;
    holdTimer.current = setTimeout(() => { suppressClick.current = true; setDragBar(which); }, 250);
  };

  const cancelDrag = () => {
    clearTimeout(holdTimer.current);
    const which = dragBar;
    setDragBar(null);
    // a hold that never moved clears the bar's numbers instead of dragging it
    if (which && !barMoved.current) clearBarNumber(which === "h" ? "barNumber" : "barVNumber");
  };

  useEffect(() => {
    if (!dragBar) return;
    const move = (e) => {
      const rect = containerRef.current?.getBoundingClientRect();
      if (!rect) return;
      if (Math.hypot(e.clientX - barStart.current.x, e.clientY - barStart.current.y) > 6) barMoved.current = true;
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
    const nums = numbersOn(key);
    const isPressed = pressedBtn === key;
    return (
      <button key={key} style={style}
        onPointerDown={locked ? () => setPressedBtn(key) : () => {
          if (nums.length === 0) return;
          clearTimeout(holdTimer.current);
          holdTimer.current = setTimeout(() => {
            suppressClick.current = true;
            clearNumber(key);
          }, 400);
        }}
        onPointerUp={locked ? () => setPressedBtn(null) : () => clearTimeout(holdTimer.current)}
        onPointerLeave={locked ? () => setPressedBtn(null) : () => clearTimeout(holdTimer.current)}
        onPointerCancel={locked ? () => setPressedBtn(null) : () => clearTimeout(holdTimer.current)}
        onClick={locked ? undefined : () => {
          if (suppressClick.current) { suppressClick.current = false; return; }
          addNumber(key);
        }}
        onContextMenu={(e) => e.preventDefault()}
        className={cn("rounded-xl border flex items-center justify-center font-display select-none touch-none transition-colors",
          nums.length > 1 ? "text-[11px] leading-tight" : "text-base",
          locked && nums.length === 0 ? "border-transparent" : isPressed ? `${strongLine} marker-pulse` : line,
          !locked && nums.length > 0 && txt,
          !locked && lineHover)}>
        {nums.length ? nums.join(" ") : ""}
      </button>
    );
  };

  const markerButton = (r, c) => cellButton(r * COLS + c, {
    gridColumn: c + (c >= barCol ? 1 : 0) + 1,
    gridRow: r + (r >= barRow ? 1 : 0) + 1,
  });

  // tap a bar → add another number (multiple allowed)
  const toggleBarNumber = (key) => {
    if (suppressClick.current) { suppressClick.current = false; return; }
    saveMarkers((m) => ({ [key]: [...barNumsOf(m[key]), nextNumber()] }));
  };

  // hold a bar without moving → clear its numbers; the rest renumber
  const clearBarNumber = (key) => {
    saveMarkers((m) => {
      if (!barNumsOf(m[key]).length) return {};
      const seq = renumber({
        assignments: m.assignments || {},
        barNumber: m.barNumber || "",
        barVNumber: m.barVNumber || "",
        [key]: [],
      });
      return { assignments: seq.assignments, barNumber: seq.barNumber, barVNumber: seq.barVNumber };
    });
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
      <div className={cn("w-full h-full rounded-xl border touch-none select-none transition-colors flex items-center justify-center font-display",
        barNumber.length ? (pressedBar === "h" ? `${strongLine} marker-pulse` : line) : "border-transparent",
        barNumber.length > 1 ? "text-[13px] leading-tight" : "text-base")}>
        {barNumber.join(" ")}
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
      <div className={cn("w-full h-full rounded-xl border touch-none select-none transition-colors flex items-center justify-center font-display",
        dragBar === "h" ? strongLine : line,
        barNumber.length > 1 ? "text-[13px] leading-tight" : "text-base")}>
        {barNumber.join(" ")}
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
      className={cn("rounded-xl border touch-none select-none transition-colors flex items-center justify-center font-display",
        barVNumber.length ? (pressedBar === "v" ? `${strongLine} marker-pulse` : line) : "border-transparent")}>
      {barVNumber.length > 1 ? (
        <div className="flex flex-col items-center leading-tight text-[13px]">
          {barVNumber.map((n) => <span key={n}>{n}</span>)}
        </div>
      ) : barVNumber[0] ?? ""}
    </div>
  ) : (
    <div style={{ gridColumn: barCol + 1, gridRow: `${vStart} / ${vStart + 6}` }}
      onPointerDown={(e) => onBarPointerDown(e, "v")}
      onPointerUp={cancelDrag}
      onPointerCancel={cancelDrag}
      onClick={() => toggleBarNumber("barVNumber")}
      onContextMenu={(e) => e.preventDefault()}
      className={cn("rounded-xl border touch-none select-none transition-colors flex items-center justify-center font-display",
        dragBar === "v" ? `${strongLine} cursor-grabbing` : `${line} cursor-grab`)}>
      {barVNumber.length > 1 ? (
        <div className="flex flex-col items-center leading-tight text-[13px]">
          {barVNumber.map((n) => <span key={n}>{n}</span>)}
        </div>
      ) : barVNumber[0] ?? ""}
    </div>
  );

  return (
    <div className={cn("relative h-full overflow-hidden", light ? "text-black" : "text-white")}
      style={bgColor ? { background: bgColor } : { background: "#0b0b0f" }}>
      {/* floating edit HUD - hidden when locked, never affects the grid layout */}
      {!locked && (
        <div className="absolute top-2 inset-x-0 z-10 flex justify-center pointer-events-none">
          <span className={cn("px-2.5 py-0.5 rounded-full text-[9px] font-body backdrop-blur", light ? "text-black/40 bg-black/5" : "text-white/40 bg-white/10")}>
            Tap to add numbers · hold to clear · drag to rearrange
          </span>
        </div>
      )}
      {!locked && (
        <div className="absolute top-2 inset-x-2 z-10 flex items-center justify-end pointer-events-none">
          <div className="flex items-center gap-2 pointer-events-auto">
            <button onClick={lock}
              className={pill}>
              <Lock size={11} /> Lock
            </button>
          </div>
        </div>
      )}
      {/* edit tools - bottom, out of the way of the grid */}
      {!locked && (
        <div className="absolute bottom-3 inset-x-2 z-10 flex items-center justify-center pointer-events-none">
          <div className="flex items-center gap-2 pointer-events-auto flex-wrap justify-center">
            <Popover>
              <PopoverTrigger asChild>
                <button title="Background colour"
                  className={toolPill}>
                  <Palette size={11} />
                  <span className="h-2.5 w-2.5 rounded-full border border-current"
                    style={bgColor ? { background: bgColor } : { background: "#0b0b0f" }} />
                </button>
              </PopoverTrigger>
              <PopoverContent side="top" align="end" className="w-44 p-2 border-white/15 bg-black/80 text-white backdrop-blur-xl shadow-2xl">
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
                  className={toolPill}>
                  <Shapes size={11} /> Marks
                </button>
              </PopoverTrigger>
              <PopoverContent side="top" align="end" className="w-44 p-1.5 border-white/15 bg-black/80 text-white backdrop-blur-xl shadow-2xl">
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
                <div className="mt-1 border-t border-white/10 px-2.5 pt-1.5">
                  <span className="block pb-1 text-[9px] font-body uppercase tracking-wider text-white/40">Mark colour</span>
                  <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar pb-1.5">
                    <button onClick={() => saveMarkers({ markColor: null })} title="Auto contrast"
                      className={cn("h-4 w-4 shrink-0 rounded-full border border-white/25",
                        !markers.markColor && "ring-1 ring-amber ring-offset-1 ring-offset-black")}
                      style={{ background: "linear-gradient(90deg, #000000 50%, #FFFFFF 50%)" }} />
                    {vfxColors.map((c) => (
                      <button key={c.id} onClick={() => saveMarkers({ markColor: c.hex })} title={c.label}
                        className={cn("h-4 w-4 shrink-0 rounded-full border border-white/25",
                          markers.markColor === c.hex && "ring-1 ring-amber ring-offset-1 ring-offset-black")}
                        style={{ background: c.hex }} />
                    ))}
                    <label title="Custom colour" className="cursor-pointer">
                      <input type="color" value={markers.markColor || "#FFFFFF"}
                        onChange={(e) => saveMarkers({ markColor: e.target.value })}
                        className="h-4 w-4 shrink-0 cursor-pointer rounded-full border border-white/25 bg-transparent p-0" />
                    </label>
                  </div>
                </div>
                <MarkAdjust size={markers.markSize} thickness={markers.markThick} rot={markers.markRot}
                  onChange={(p) => saveMarkers({
                    ...(p.size !== undefined && { markSize: p.size }),
                    ...(p.thickness !== undefined && { markThick: p.thickness }),
                    ...(p.rot !== undefined && { markRot: p.rot }),
                  })} />
              </PopoverContent>
            </Popover>
            <Popover>
              <PopoverTrigger asChild>
                <button title="Image overlay"
                  className={toolPill}>
                  <ImagePlus size={11} /> Overlay
                </button>
              </PopoverTrigger>
              <PopoverContent side="top" align="end" className="w-56 p-2 border-white/15 bg-black/80 text-white backdrop-blur-xl shadow-2xl">
                <OverlayControl overlay={markers.overlay}
                  onChange={(p) => saveMarkers((m) => ({ overlay: { ...DEFAULT_OVERLAY, ...m.overlay, ...p } }))} />
              </PopoverContent>
            </Popover>
            {overlay.url && (
              <button title={overlay.hidden ? "Show image" : "Hide image"}
                onClick={() => saveMarkers((m) => ({ overlay: { ...DEFAULT_OVERLAY, ...m.overlay, hidden: !m.overlay?.hidden } }))}
                className={toolPill}>
                {overlay.hidden ? <EyeOff size={11} /> : <Eye size={11} />}
              </button>
            )}
            <button onClick={saveLayout}
              className={toolPill}>
              <Save size={11} /> Save
            </button>
            <button onClick={resetNumbers}
              className={toolPill}>
              <RotateCcw size={11} /> Reset
            </button>
          </div>
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
      {/* image overlay - reference photo above the grid, never interactive */}
      <OverlayLayer overlay={markers.overlay} />
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
      {locked && hint && <ThreeFingerHint light={light} />}
      {saveOpen && (
        <SaveTargetSheet title="Save marker layout" defaultName={`Markers ${new Date().toLocaleDateString()}`}
          build={(n) => ({ kind: "markers", name: n, uiMarkers: markers })}
          onClose={() => setSaveOpen(false)} />
      )}
    </div>
  );
}