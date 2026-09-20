import React from "react";

// touch feedback for the locked marker screen: a fading glow where the
// screen was touched, plus a quickly fading soft glow line when one of the
// long bars is swiped. The colour auto-contrasts with the chosen
// background - black on light, white on dark - like the square outlines.
export default function TouchGlow({ ripples, trail, light }) {
  const glow = light
    ? "radial-gradient(circle, rgba(0,0,0,0.45) 0%, rgba(0,0,0,0) 70%)"
    : "radial-gradient(circle, rgba(255,255,255,0.5) 0%, rgba(255,255,255,0) 70%)";
  return (
    <div className="absolute inset-0 z-20 pointer-events-none overflow-hidden">
      {trail && (
        <div className={"absolute inset-0" + (trail.fading ? " touch-glow-trail" : "")}>
          {trail.points.map((p, i) => (
            <span key={i} className="touch-glow-dot" style={{ left: p.x, top: p.y, background: glow }} />
          ))}
        </div>
      )}
      {ripples.map((r) => (
        <span key={r.id} className="touch-glow-ripple" style={{ left: r.x, top: r.y, background: glow }} />
      ))}
    </div>
  );
}