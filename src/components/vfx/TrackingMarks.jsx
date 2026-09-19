import React from "react";
import { cn } from "@/lib/utils";

// tracking marker overlays for the key screens stage.
// point styles (cross / circles / squares / brackets) render individually
// positioned markers that can be moved, added and removed in edit mode.
// patterns (dots / checkerboard) fill the screen - checkerboard is always black & white.
export function TrackingMarks({ type, color = "#FFFFFF", opacity = 0.85, size = 1, thickness = 1, markers = [], onMarkerDown, dragId }) {
  const fill = color;

  if (type === "none") return null;

  const pattern = (style) => (
    <div className="absolute inset-0 pointer-events-none" style={{ opacity, ...style }} />
  );

  // checkerboard - alternating black & white squares (black & white only)
  if (type === "checkerboard") {
    const s = 128 * size;
    return pattern({
      backgroundColor: "#FFFFFF",
      backgroundImage: `linear-gradient(45deg, #000000 25%, transparent 25%, transparent 75%, #000000 75%), linear-gradient(45deg, #000000 25%, transparent 25%, transparent 75%, #000000 75%)`,
      backgroundSize: `${s}px ${s}px`,
      backgroundPosition: `0 0, ${s / 2}px ${s / 2}px`,
    });
  }

  // dot pattern - small dots across the whole screen
  if (type === "dots") {
    return pattern({
      backgroundImage: `radial-gradient(${fill} ${3 * thickness}px, transparent ${3 * thickness}px)`,
      backgroundSize: `${40 * size}px ${40 * size}px`,
      backgroundPosition: `${20 * size}px ${20 * size}px`,
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
      const arm = 48 * size;
      const th = 14 * thickness;
      return spin(0, <>
        <div className="absolute" style={{ width: arm, height: th, background: fill, transform: "translate(-50%, -50%)" }} />
        <div className="absolute" style={{ width: th, height: arm, background: fill, transform: "translate(-50%, -50%)" }} />
      </>);
    }
    if (kind === "circles") {
      const d = 46 * size;
      return spin(0,
        <div className="absolute rounded-full flex items-center justify-center"
          style={{ width: d, height: d, border: `${10 * thickness}px solid ${fill}`, transform: "translate(-50%, -50%)" }}>
          <span style={{ width: 10 * size, height: 10 * size, borderRadius: "50%", background: fill }} />
        </div>
      );
    }
    if (kind === "squares") {
      const d = 48 * size;
      return spin(0, <div className="absolute" style={{ width: d, height: d, border: `${10 * thickness}px solid ${fill}`, transform: "translate(-50%, -50%)" }} />);
    }
    if (kind === "diamond") {
      const d = 44 * size;
      return spin(0, <div className="absolute" style={{ width: d, height: d, border: `${10 * thickness}px solid ${fill}`, transform: "translate(-50%, -50%) rotate(45deg)" }} />);
    }
    if (kind === "brackets") {
      const L = 40 * size;
      const th = Math.max(3, 14 * thickness);
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
    <div className="absolute inset-0 pointer-events-none" style={{ opacity }}>
      {markers.map((m) => (
        <div key={m.id}
          className={cn("absolute touch-none select-none",
            onMarkerDown && "pointer-events-auto cursor-grab",
            dragId === m.id && "cursor-grabbing")}
          style={{ left: `${m.x}%`, top: `${m.y}%` }}
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