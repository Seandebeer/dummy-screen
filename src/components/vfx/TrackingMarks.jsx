import React from "react";

// tracking marker overlays — the six standard VFX screen-replacement styles.
// markers follow the active mark color — except checkerboard, which is always black & white.
export function TrackingMarks({ type, color = "#FFFFFF", opacity = 0.85 }) {
  const fill = color;

  if (type === "none") return null;

  const CORNERS = [
    { left: 28, top: 28 },
    { right: 28, top: 28 },
    { left: 28, bottom: 28 },
    { right: 28, bottom: 28 },
  ];

  const overlay = (children) => (
    <div className="absolute inset-0 pointer-events-none" style={{ opacity }}>{children}</div>
  );

  // 1. cross markers — plus signs in the four corners + center
  if (type === "cross") {
    const pts = [...CORNERS, { left: "50%", top: "50%" }];
    return overlay(pts.map((p, i) => (
      <div key={i} className="absolute" style={p}>
        <div className="absolute" style={{ width: 24, height: 7, background: fill, transform: "translate(-50%, -50%)" }} />
        <div className="absolute" style={{ width: 7, height: 24, background: fill, transform: "translate(-50%, -50%)" }} />
      </div>
    )));
  }

  // 2. circular markers — outlined circle with a center dot, four corners + center
  if (type === "circles") {
    const pts = [...CORNERS, { left: "50%", top: "50%" }];
    return overlay(pts.map((p, i) => (
      <div key={i} className="absolute rounded-full flex items-center justify-center"
        style={{ ...p, width: 26, height: 26, border: `5px solid ${fill}`, transform: "translate(-50%, -50%)" }}>
        <span style={{ width: 10, height: 10, borderRadius: "50%", background: fill }} />
      </div>
    )));
  }

  // 3. checkerboard — alternating black & white squares (black & white only)
  if (type === "checkerboard") {
    const s = 128;
    return (
      <div className="absolute inset-0 pointer-events-none" style={{
        backgroundColor: "#FFFFFF",
        backgroundImage: `linear-gradient(45deg, #000000 25%, transparent 25%, transparent 75%, #000000 75%), linear-gradient(45deg, #000000 25%, transparent 25%, transparent 75%, #000000 75%)`,
        backgroundSize: `${s}px ${s}px`,
        backgroundPosition: `0 0, ${s / 2}px ${s / 2}px`,
      }} />
    );
  }

  // 4. square / QR markers — hollow square outlines in the four corners
  if (type === "squares") {
    return overlay(CORNERS.map((p, i) => (
      <div key={i} className="absolute"
        style={{ ...p, width: 30, height: 30, border: `5px solid ${fill}`, transform: "translate(-50%, -50%)" }} />
    )));
  }

  // 5. dot pattern — small dots across the whole screen
  if (type === "dots") {
    return (
      <div className="absolute inset-0 pointer-events-none" style={{
        opacity,
        backgroundImage: `radial-gradient(${fill} 3px, transparent 3px)`,
        backgroundSize: "40px 40px",
        backgroundPosition: "20px 20px",
      }} />
    );
  }

  // 6. bracket markers — L-shaped corner brackets + diamond in the center
  if (type === "brackets") {
    const L = 64;
    const m = 32;
    const corners = [
      { x: m, y: m, dx: 1, dy: 1 },
      { x: `calc(100% - ${m}px)`, y: m, dx: -1, dy: 1 },
      { x: m, y: `calc(100% - ${m}px)`, dx: 1, dy: -1 },
      { x: `calc(100% - ${m}px)`, y: `calc(100% - ${m}px)`, dx: -1, dy: -1 },
    ];
    return overlay([
      ...corners.map((c, i) => (
        <div key={i} className="absolute" style={{ left: c.x, top: c.y }}>
          <div style={{ width: c.dx * L, height: 7, background: fill, transform: `translateX(${c.dx > 0 ? 0 : -L}px)` }} />
          <div style={{ width: 7, height: c.dy * L, background: fill, transform: `translateY(${c.dy > 0 ? 0 : -L}px)` }} />
        </div>
      )),
      <div key="diamond" className="absolute"
        style={{ left: "50%", top: "50%", width: 22, height: 22, border: `5px solid ${fill}`, transform: "translate(-50%, -50%) rotate(45deg)" }} />,
    ]);
  }

  return null;
}