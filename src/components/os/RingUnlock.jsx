import React, { useRef, useState } from "react";
import { Lock } from "lucide-react";

// Android 4 ICS-style unlock ring: drag the lock chip outward into the
// glowing ring to unlock; release inside and it springs back.
const RADIUS = 74;

export default function RingUnlock({ onUnlock }) {
  const [pos, setPos] = useState({ x: 0, y: 0 });
  const [drag, setDrag] = useState(false);
  const start = useRef(null);

  const onDown = (e) => {
    start.current = { x: e.clientX, y: e.clientY };
    setDrag(true);
    e.currentTarget.setPointerCapture(e.pointerId);
  };
  const onMove = (e) => {
    if (!start.current) return;
    setPos({ x: e.clientX - start.current.x, y: e.clientY - start.current.y });
  };
  const onUp = () => {
    const done = Math.hypot(pos.x, pos.y) >= RADIUS;
    start.current = null;
    setDrag(false);
    if (done) onUnlock?.();
    setPos({ x: 0, y: 0 });
  };

  const progress = Math.min(1, Math.hypot(pos.x, pos.y) / RADIUS);

  return (
    <div className="relative h-44 w-44 select-none touch-none">
      {/* the ring */}
      <div className="absolute inset-0 rounded-full border-2"
        style={{
          borderColor: `rgba(51,181,229,${0.35 + progress * 0.5})`,
          boxShadow: `0 0 ${6 + progress * 24}px rgba(51,181,229,${0.2 + progress * 0.5})`,
        }} />
      {/* hint */}
      <span className="absolute inset-0 flex items-center justify-center text-white/35 text-[9px] font-body uppercase tracking-widest pointer-events-none text-center px-6"
        style={{ opacity: drag ? 0 : 0.9 }}>
        drag to unlock
      </span>
      {/* the lock chip */}
      <div
        onPointerDown={onDown}
        onPointerMove={onMove}
        onPointerUp={onUp}
        onPointerCancel={onUp}
        className="absolute left-1/2 top-1/2 flex h-14 w-14 cursor-pointer items-center justify-center rounded-full border"
        style={{
          transform: `translate(calc(-50% + ${pos.x}px), calc(-50% + ${pos.y}px))`,
          transition: drag ? "none" : "transform 250ms ease-out",
          background: "linear-gradient(180deg, #33B5E5 0%, #17536e 100%)",
          borderColor: "rgba(51,181,229,0.6)",
          boxShadow: drag
            ? `0 0 ${10 + progress * 20}px rgba(51,181,229,0.7)`
            : "0 0 8px rgba(51,181,229,0.35)",
        }}
      >
        <Lock size={22} className="text-white" />
      </div>
    </div>
  );
}