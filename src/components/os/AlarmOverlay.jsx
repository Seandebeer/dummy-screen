import React, { useState, useEffect, useRef } from "react";
import { AlarmClock } from "lucide-react";

export default function AlarmOverlay({ onDismiss }) {
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(t);
  }, []);

  // ringing beep loop — browsers may block audio without a prior gesture; fail silently
  useEffect(() => {
    let ctx, timer;
    try {
      const AC = window.AudioContext || window.webkitAudioContext;
      if (AC) {
        ctx = new AC();
        const beep = () => {
          const o = ctx.createOscillator();
          const g = ctx.createGain();
          o.frequency.value = 880;
          g.gain.value = 0.06;
          o.connect(g);
          g.connect(ctx.destination);
          o.start();
          g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.45);
          o.stop(ctx.currentTime + 0.5);
        };
        beep();
        timer = setInterval(beep, 1000);
      }
    } catch {}
    return () => {
      clearInterval(timer);
      try { ctx?.close?.(); } catch {}
    };
  }, []);

  const time = new Date(now).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });

  return (
    <div className="absolute inset-0 z-50 flex flex-col items-center justify-center gap-5 text-white"
      style={{ background: "linear-gradient(180deg, #1a1d2e 0%, #0a0b14 100%)" }}>
      <AlarmClock size={56} className="text-amber marker-pulse" />
      <div className="text-[11px] uppercase tracking-[0.35em] text-white/50 font-body">Alarm</div>
      <div className="font-display text-6xl font-bold tracking-tight">{time}</div>
      <button onClick={onDismiss}
        className="mt-8 rounded-full bg-white/15 border border-white/20 px-10 py-3 text-sm font-body tracking-wide active:scale-95 transition">
        Stop
      </button>
    </div>
  );
}