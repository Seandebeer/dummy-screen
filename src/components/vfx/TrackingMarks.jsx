import React from "react";

export function TrackingMarks({ type, color = "#FFFFFF", opacity = 0.85 }) {
  const stroke = color;
  const fill = color;

  if (type === "none") return null;

  if (type === "crosshair") {
    return (
      <div className="absolute inset-0 pointer-events-none" style={{ opacity }}>
        {/* center crosshair */}
        <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2">
          <div className="absolute left-1/2 -translate-x-1/2 -top-5 h-4 w-px" style={{ background: fill }} />
          <div className="absolute left-1/2 -translate-x-1/2 top-1 h-4 w-px" style={{ background: fill }} />
          <div className="absolute top-1/2 -translate-y-1/2 -left-5 w-4 h-px" style={{ background: fill }} />
          <div className="absolute top-1/2 -translate-y-1/2 left-1 w-4 h-px" style={{ background: fill }} />
          <div className="h-2 w-2 rounded-full border" style={{ borderColor: fill }} />
        </div>
        {/* corner crop marks */}
        {[[8, 8, 1, 1], [null, 8, -1, 1], [8, null, 1, -1], [null, null, -1, -1]].map(([l, t, dx, dy], i) => (
          <div key={i} className="absolute" style={{ left: l ?? "auto", right: l === null ? 8 : "auto", top: t ?? "auto", bottom: t === null ? 8 : "auto" }}>
            <div style={{ width: dx * 22, height: 2, background: fill, transform: `translateX(${dx > 0 ? 0 : -22}px)` }} />
            <div style={{ width: 2, height: dy * 22, background: fill, transform: `translateY(${dy > 0 ? 0 : -22}px)` }} />
          </div>
        ))}
      </div>
    );
  }

  if (type === "lbar") {
    const L = 64;
    const m = 32;
    const corners = [
      { x: m, y: m, dx: 1, dy: 1 },
      { x: `calc(100% - ${m}px)`, y: m, dx: -1, dy: 1 },
      { x: m, y: `calc(100% - ${m}px)`, dx: 1, dy: -1 },
      { x: `calc(100% - ${m}px)`, y: `calc(100% - ${m}px)`, dx: -1, dy: -1 },
    ];
    return (
      <div className="absolute inset-0 pointer-events-none" style={{ opacity }}>
        {corners.map((c, i) => (
          <div key={i} className="absolute" style={{ left: c.x, top: c.y }}>
            <div style={{ width: c.dx * L, height: 2, background: fill, transform: `translateX(${c.dx > 0 ? 0 : -L}px)` }} />
            <div style={{ width: 2, height: c.dy * L, background: fill, transform: `translateY(${c.dy > 0 ? 0 : -L}px)` }} />
          </div>
        ))}
      </div>
    );
  }

  if (type === "dotgrid") {
    return (
      <div className="absolute inset-0 pointer-events-none" style={{ opacity }}
        dangerouslySetInnerHTML={{
          __html: `<div style="width:100%;height:100%;background-image:radial-gradient(${fill} 1.5px, transparent 1.5px);background-size:40px 40px;background-position:20px 20px;"></div>`
        }}
      />
    );
  }

  return null;
}