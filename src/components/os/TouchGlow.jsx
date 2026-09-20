import React from "react";

// touch feedback for the locked marker screen: a fading glow where the
// screen was touched, plus a quickly fading line when a long bar is swiped
export default function TouchGlow({ ripples, trail, light }) {
  const stroke = light ? "rgba(0,0,0,0.5)" : "rgba(255,255,255,0.55)";
  return (
    <div className="absolute inset-0 z-20 pointer-events-none overflow-hidden">
      {trail && trail.points.length > 1 && (
        <svg className={trail.fading ? "touch-glow-trail" : undefined} width="100%" height="100%">
          <polyline points={trail.points.map((p) => `${p.x},${p.y}`).join(" ")}
            fill="none" stroke={stroke} strokeWidth="9" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      )}
      {ripples.map((r) => (
        <span key={r.id} className="touch-glow-ripple"
          style={{
            left: r.x,
            top: r.y,
            background: light
              ? "radial-gradient(circle, rgba(0,0,0,0.4) 0%, rgba(0,0,0,0) 70%)"
              : "radial-gradient(circle, rgba(255,255,255,0.5) 0%, rgba(255,255,255,0) 70%)",
          }} />
      ))}
    </div>
  );
}