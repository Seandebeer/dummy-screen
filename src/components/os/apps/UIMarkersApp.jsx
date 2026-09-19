import React, { useState, useRef, useEffect } from "react";
import { Lock } from "lucide-react";
import { cn } from "@/lib/utils";

const COLS = 5;
const ROWS = 8;

export default function UIMarkersApp({ config, update }) {
  const markers = config.uiMarkers || {};
  const assignments = markers.assignments || {};
  const barRow = markers.barRow ?? 4;

  const [locked, setLocked] = useState(false);
  const [hint, setHint] = useState(false);
  const [pressedBtn, setPressedBtn] = useState(null);
  const [pressedBar, setPressedBar] = useState(false);
  const [barDragging, setBarDragging] = useState(false);
  const containerRef = useRef(null);
  const holdTimer = useRef(null);
  const dragStartY = useRef(null);

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

  // hold the bar (edit mode) → drag it to a new row position
  const onBarPointerDown = (e) => {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    dragStartY.current = e.clientY;
    clearTimeout(holdTimer.current);
    holdTimer.current = setTimeout(() => {
      dragStartY.current = null;
      setBarDragging(true);
    }, 250);
  };

  const cancelDrag = () => {
    clearTimeout(holdTimer.current);
    dragStartY.current = null;
    setBarDragging(false);
  };

  useEffect(() => {
    if (!barDragging) return;
    const move = (e) => {
      const rect = containerRef.current?.getBoundingClientRect();
      if (!rect) return;
      const band = rect.height / (ROWS + 1);
      const row = Math.max(0, Math.min(ROWS, Math.floor((e.clientY - rect.top) / band)));
      saveMarkers((m) => (m.barRow === row ? {} : { barRow: row }));
    };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", cancelDrag);
    window.addEventListener("pointercancel", cancelDrag);
    return () => {
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", cancelDrag);
      window.removeEventListener("pointercancel", cancelDrag);
    };
  }, [barDragging]);

  const rows = [];
  for (let r = 0; r < ROWS; r++) rows.push(Array.from({ length: COLS }, (_, c) => r * COLS + c));

  const markerButton = (i) => {
    const assigned = assignments[i];
    const isPressed = pressedBtn === i;
    return (
      <button key={i}
        onPointerDown={locked ? () => setPressedBtn(i) : undefined}
        onPointerUp={locked ? () => setPressedBtn(null) : undefined}
        onPointerLeave={locked ? () => setPressedBtn(null) : undefined}
        onPointerCancel={locked ? () => setPressedBtn(null) : undefined}
        onClick={locked ? undefined : () => toggleAssign(i)}
        onContextMenu={(e) => e.preventDefault()}
        className={cn("flex-1 rounded-xl border flex items-center justify-center text-base font-display select-none touch-none transition-colors",
          isPressed ? "bg-white/30 border-white/70 marker-pulse" : "bg-white/10 border-white/15",
          !locked && assigned != null && "border-amber/60 text-amber",
          !locked && "hover:border-white/40")}>
        {assigned != null ? assigned : ""}
      </button>
    );
  };

  const bar = locked ? (
    <button
      onPointerDown={() => setPressedBar(true)}
      onPointerUp={() => setPressedBar(false)}
      onPointerLeave={() => setPressedBar(false)}
      onPointerCancel={() => setPressedBar(false)}
      onContextMenu={(e) => e.preventDefault()}
      className={cn("w-full h-10 shrink-0 rounded-xl border touch-none select-none transition-colors",
        pressedBar ? "bg-white/30 border-white/70 marker-pulse" : "bg-white/10 border-white/15")} />
  ) : (
    <button
      onPointerDown={onBarPointerDown}
      onPointerUp={cancelDrag}
      onPointerCancel={cancelDrag}
      onContextMenu={(e) => e.preventDefault()}
      className={cn("w-full h-10 shrink-0 rounded-xl border touch-none select-none transition-colors",
        barDragging ? "bg-white/30 border-white/70" : "bg-amber/15 border-amber/50",
        barDragging ? "cursor-grabbing" : "cursor-grab")} />
  );

  return (
    <div className="relative h-full bg-[#0b0b0f] flex flex-col">
      {!locked && (
        <div className="flex items-center justify-between px-3 pt-1 pb-1 shrink-0">
          <span className="text-[10px] uppercase tracking-wider text-white/40 font-body">UI Markers · Edit</span>
          <button onClick={lock}
            className="flex items-center gap-1 rounded-full border border-white/20 px-2.5 py-1 text-[10px] font-body text-white/70">
            <Lock size={11} /> Lock
          </button>
        </div>
      )}
      <div ref={containerRef} className="flex-1 flex flex-col gap-1 p-1 min-h-0">
        {rows.map((row, r) => (
          <React.Fragment key={r}>
            {barRow === r && bar}
            <div className="flex-1 flex gap-1 min-h-0">{row.map(markerButton)}</div>
          </React.Fragment>
        ))}
        {barRow === ROWS && bar}
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