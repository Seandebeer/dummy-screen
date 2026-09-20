import React, { useState, useEffect, useRef } from "react";
import { cn } from "@/lib/utils";
import { compositeMarks } from "@/lib/vfxData";
import CompositeGlyph from "@/components/vfx/CompositeMarks";

const COMPOSITE_IDS = new Set(compositeMarks.map((m) => m.id));

// tracking marker overlays for the key screens stage.
// point styles (cross / circles / squares / brackets) render individually
// positioned markers that can be moved, added and removed in edit mode.
// patterns (dots / checkerboard) fill the screen - checkerboard is always black & white.
export function TrackingMarks({ type, color = "#FFFFFF", opacity = 0.85, size = 1, thickness = 1, markers = [], onMarkerDown, dragId }) {
  const fill = color;

  // snap markers to whole pixels so every edge stays razor sharp
  const wrapRef = useRef(null);
  const [box, setBox] = useState(null);
  useEffect(() => {
    const el = wrapRef.current;
    if (!el) return;
    const read = () => {
      const r = el.getBoundingClientRect();
      setBox((b) => (b && b.w === r.width && b.h === r.height ? b : { w: r.width, h: r.height }));
    };
    read();
    const ro = new ResizeObserver(read);
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  if (type === "none") return null;

  const pattern = (style) => (
    <div ref={wrapRef} className="absolute inset-0 pointer-events-none" style={{ opacity, ...style }} />
  );

  // checkerboard - alternating black & white squares (black & white only)
  if (type === "checkerboard") {
    const s = Math.max(2, Math.round(128 * size));
    return pattern({
      backgroundColor: "#FFFFFF",
      backgroundImage: `linear-gradient(45deg, #000000 25%, transparent 25%, transparent 75%, #000000 75%), linear-gradient(45deg, #000000 25%, transparent 25%, transparent 75%, #000000 75%)`,
      backgroundSize: `${s}px ${s}px`,
      backgroundPosition: `0 0, ${s / 2}px ${s / 2}px`,
    });
  }

  // dot pattern - hard-edged dots across the whole screen (no gradient fuzz)
  if (type === "dots") {
    const cell = Math.max(4, Math.round(40 * size));
    const r = Math.max(1, Math.round(3 * thickness));
    const c = Math.round(cell / 2);
    const dot = `data:image/svg+xml,${encodeURIComponent(
      `<svg xmlns='http://www.w3.org/2000/svg' width='${cell}' height='${cell}'><circle cx='${c}' cy='${c}' r='${r}' fill='${fill}' shape-rendering='crispEdges'/></svg>`
    )}`;
    return pattern({
      backgroundImage: `url("${dot}")`,
      backgroundSize: `${cell}px ${cell}px`,
      backgroundPosition: `${c}px ${c}px`,
    });
  }

  if (!markers.length) return null;

  // each glyph renders inside a zero-size "spin" wrapper anchored at the marker
  // point, so rotation (per-marker, snapped to 45°) pivots around that point
  const glyph = (m) => {
    const kind = m.kind || type;
    const rot = m.rot || 0;
    const spin = (baseRot, children) => (
      <div className="absolute" style={{ transform: `rotate(${baseRot + rot}deg)` }}>{children}</div>
    );

    if (kind === "cross") {
      const arm = Math.round(48 * size);
      const th = Math.max(1, Math.round(10 * thickness));
      return spin(0, <>
        <div className="absolute" style={{ width: arm, height: th, background: fill, transform: "translate(-50%, -50%)" }} />
        <div className="absolute" style={{ width: th, height: arm, background: fill, transform: "translate(-50%, -50%)" }} />
      </>);
    }
    if (kind === "circles") {
      const d = Math.round(48 * size);
      const bw = Math.max(1, Math.round(10 * thickness));
      return spin(0,
        <div className="absolute rounded-full flex items-center justify-center"
          style={{ width: d, height: d, border: `${bw}px solid ${fill}`, transform: "translate(-50%, -50%)" }}>
          <span style={{ width: Math.max(1, Math.round(10 * size)), height: Math.max(1, Math.round(10 * size)), borderRadius: "50%", background: fill }} />
        </div>
      );
    }
    if (kind === "squares") {
      const d = Math.round(48 * size);
      const bw = Math.max(1, Math.round(10 * thickness));
      return spin(0, <div className="absolute" style={{ width: d, height: d, border: `${bw}px solid ${fill}`, transform: "translate(-50%, -50%)" }} />);
    }
    if (kind === "diamond") {
      const d = Math.round(48 * size);
      const bw = Math.max(1, Math.round(10 * thickness));
      return spin(0, <div className="absolute" style={{ width: d, height: d, border: `${bw}px solid ${fill}`, transform: "translate(-50%, -50%) rotate(45deg)" }} />);
    }
    if (kind === "triangle") {
      const s = Math.round(48 * size);
      return spin(0, <svg className="absolute" width={s} height={s} viewBox="0 0 24 24" shapeRendering="crispEdges"
        fill="none" style={{ transform: "translate(-50%, -50%)" }}>
        <path d="M12 2.5 L22 21 H2 Z" stroke={fill} strokeWidth={5 * thickness} strokeLinejoin="miter" />
      </svg>);
    }
    if (COMPOSITE_IDS.has(kind)) {
      return spin(0, <CompositeGlyph kind={kind} fill={fill} size={size} thickness={thickness} />);
    }
    if (kind === "brackets") {
      const L = Math.round(48 * size);
      const th = Math.max(1, Math.round(10 * thickness));
      // canonical corner opens toward the bottom-right; orient per quadrant
      const dx = m.x <= 50 ? 1 : -1;
      const dy = m.y <= 50 ? 1 : -1;
      const baseRot = dx > 0 ? (dy > 0 ? 0 : 270) : (dy > 0 ? 90 : 180);
      return spin(baseRot, <>
        <div className="absolute" style={{ width: L, height: th, background: fill }} />
        <div className="absolute" style={{ width: th, height: L, background: fill }} />
      </>);
    }
    return null;
  };

  return (
    <div ref={wrapRef} className="absolute inset-0 pointer-events-none" style={{ opacity }}>
      {markers.map((m) => (
        <div key={m.id}
          className={cn("absolute touch-none select-none",
            onMarkerDown && "pointer-events-auto cursor-grab",
            dragId === m.id && "cursor-grabbing")}
          style={{
            left: box ? `${Math.round((m.x / 100) * box.w)}px` : `${m.x}%`,
            top: box ? `${Math.round((m.y / 100) * box.h)}px` : `${m.y}%`,
          }}
          onPointerDown={onMarkerDown ? (e) => onMarkerDown(m.id, e) : undefined}
          onContextMenu={(e) => e.preventDefault()}>
          {onMarkerDown && (
            <span className="absolute rounded-lg" style={{ width: 44, height: 44, transform: "translate(-50%, -50%)" }} />
          )}
          {glyph(m)}
        </div>
      ))}
    </div>
  );
}