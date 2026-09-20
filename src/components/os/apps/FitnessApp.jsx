import React, { useState, useEffect } from "react";
import { Droplets, Footprints, HeartPulse, Plus, Minus, X } from "lucide-react";
import { cn } from "@/lib/utils";

// Pulse - a semi-functional fitness app: steps accumulate live while open,
// water and workouts are tappable and persist, goals are adjustable.

const KEY = "takeover-os-fitness";
const todayStr = () => new Date().toISOString().slice(0, 10);

const DEFAULT = { day: todayStr(), steps: 4820, stepGoal: 10000, water: 3, waterGoal: 8, workouts: [] };

const load = () => {
  try {
    const s = JSON.parse(localStorage.getItem(KEY));
    return { ...DEFAULT, ...(s || {}) };
  } catch {
    return { ...DEFAULT };
  }
};

const QUICK_WORKOUTS = [
  { kind: "Run", mins: 20 },
  { kind: "Walk", mins: 15 },
  { kind: "Cycle", mins: 30 },
  { kind: "Gym", mins: 45 },
];

const EXERCISE_GOAL = 30;

function Ring({ pct, color, value, label, sub }) {
  const R = 40;
  const C = 2 * Math.PI * R;
  const p = Math.max(0, Math.min(1, pct));
  return (
    <div className="flex flex-col items-center gap-1.5">
      <div className="relative h-[92px] w-[92px]">
        <svg viewBox="0 0 92 92" className="h-full w-full -rotate-90">
          <circle cx="46" cy="46" r={R} fill="none" stroke="rgba(255,255,255,0.09)" strokeWidth="9" />
          <circle cx="46" cy="46" r={R} fill="none" stroke={color} strokeWidth="9" strokeLinecap="round"
            strokeDasharray={`${C * p} ${C}`} className="transition-all duration-500" />
        </svg>
        <span className="absolute inset-0 flex flex-col items-center justify-center">
          <span className="font-display text-[17px] font-bold leading-none">{value}</span>
          <span className="mt-0.5 text-[8px] uppercase tracking-widest text-white/40">{sub}</span>
        </span>
      </div>
      <span className="text-[10px] font-medium text-white/55">{label}</span>
    </div>
  );
}

const Stepper = ({ onMinus, onPlus, children }) => (
  <span className="flex items-center gap-2">
    <button onClick={onMinus} aria-label="Decrease" className="flex h-7 w-7 items-center justify-center rounded-full bg-white/10 text-white/70 active:bg-white/20"><Minus size={13} /></button>
    <span className="min-w-[52px] text-center text-[13px] font-semibold">{children}</span>
    <button onClick={onPlus} aria-label="Increase" className="flex h-7 w-7 items-center justify-center rounded-full bg-white/10 text-white/70 active:bg-white/20"><Plus size={13} /></button>
  </span>
);

export default function FitnessApp() {
  const [s, setS] = useState(load);
  const [hr, setHr] = useState(72);
  const day = todayStr();

  const persist = (next) => { setS(next); try { localStorage.setItem(KEY, JSON.stringify(next)); } catch {} };
  const upd = (patch) => persist({ ...s, ...patch });

  // roll over to a fresh day (goals survive, activity resets)
  useEffect(() => { if (s.day !== day) persist({ ...s, day, steps: 0, water: 0, workouts: [] }); }, []);

  // simulated live walking + heart rate while the app is open
  useEffect(() => {
    const t = setInterval(() => {
      setS((cur) => {
        const next = { ...cur, steps: cur.steps + 3 + Math.floor(Math.random() * 12) };
        try { localStorage.setItem(KEY, JSON.stringify(next)); } catch {}
        return next;
      });
      setHr(66 + Math.floor(Math.random() * 11));
    }, 2400);
    return () => clearInterval(t);
  }, []);

  const exercise = (s.workouts || []).reduce((n, w) => n + w.mins, 0);

  const addWorkout = (w) => upd({ workouts: [{ id: `w-${Date.now()}`, ...w }, ...(s.workouts || [])] });
  const removeWorkout = (id) => upd({ workouts: (s.workouts || []).filter((w) => w.id !== id) });

  return (
    <div className="h-full overflow-y-auto no-scrollbar bg-black text-white">
      <div className="px-4 pb-1 pt-3">
        <div className="font-display text-2xl font-bold">Fitness</div>
        <div className="text-[10px] uppercase tracking-widest text-white/35">
          {new Date().toLocaleDateString([], { weekday: "long", day: "numeric", month: "short" })} · today
        </div>
      </div>

      {/* activity rings */}
      <div className="flex items-center justify-around px-2 py-4">
        <Ring pct={s.steps / (s.stepGoal || 1)} color="#32D74B" value={s.steps.toLocaleString()} label="Steps" sub={s.stepGoal ? `of ${(s.stepGoal / 1000).toFixed(0)}k` : ""} />
        <Ring pct={s.water / (s.waterGoal || 1)} color="#0A84FF" value={s.water} label="Water" sub={`of ${s.waterGoal}`} />
        <Ring pct={exercise / EXERCISE_GOAL} color="#FF9F0A" value={`${exercise}m`} label="Exercise" sub={`of ${EXERCISE_GOAL}m`} />
      </div>

      {/* heart rate */}
      <div className="mx-4 flex items-center gap-3 rounded-2xl bg-white/[0.06] px-4 py-3">
        <span className="flex h-9 w-9 items-center justify-center rounded-full bg-[#FF375F]/20 text-[#FF375F]">
          <HeartPulse size={18} className="animate-pulse" />
        </span>
        <div className="flex-1">
          <div className="text-[10px] uppercase tracking-widest text-white/40">Heart rate</div>
          <div className="text-[13px] text-white/70">Resting walk</div>
        </div>
        <span className="font-display text-2xl font-bold tabular-nums">{hr}<span className="ml-1 text-[11px] font-medium text-white/40">bpm</span></span>
      </div>

      {/* goals */}
      <div className="mx-4 mt-3 space-y-2 rounded-2xl bg-white/[0.06] px-4 py-3">
        <div className="flex items-center justify-between">
          <span className="flex items-center gap-2 text-[13px] text-white/80"><Footprints size={15} className="text-[#32D74B]" />Step goal</span>
          <Stepper onMinus={() => upd({ stepGoal: Math.max(2000, s.stepGoal - 1000) })} onPlus={() => upd({ stepGoal: Math.min(20000, s.stepGoal + 1000) })}>
            {(s.stepGoal / 1000).toFixed(0)}k
          </Stepper>
        </div>
        <div className="flex items-center justify-between border-t border-white/10 pt-2">
          <span className="flex items-center gap-2 text-[13px] text-white/80"><Droplets size={15} className="text-[#0A84FF]" />Water goal</span>
          <Stepper onMinus={() => upd({ waterGoal: Math.max(2, s.waterGoal - 1) })} onPlus={() => upd({ waterGoal: Math.min(15, s.waterGoal + 1) })}>
            {s.waterGoal} glasses
          </Stepper>
        </div>
      </div>

      {/* water tracker */}
      <div className="mx-4 mt-3 rounded-2xl bg-white/[0.06] px-4 py-3">
        <div className="flex items-center justify-between">
          <span className="text-[13px] text-white/80">Water today</span>
          <span className="text-[12px] tabular-nums text-white/50">{s.water} / {s.waterGoal}</span>
        </div>
        <div className="mt-2.5 flex flex-wrap gap-1.5">
          {Array.from({ length: Math.max(s.waterGoal, s.water) }, (_, i) => (
            <span key={i} className={cn("h-6 w-4 rounded-sm transition-colors",
              i < s.water ? "bg-[#0A84FF]" : "bg-white/10")} />
          ))}
        </div>
        <div className="mt-3 flex gap-2">
          <button onClick={() => upd({ water: Math.max(0, s.water - 1) })}
            className="flex-1 rounded-xl bg-white/10 py-2.5 text-[13px] font-semibold text-white/70 active:bg-white/20">− Glass</button>
          <button onClick={() => upd({ water: s.water + 1 })}
            className="flex-1 rounded-xl bg-[#0A84FF] py-2.5 text-[13px] font-semibold active:opacity-80">+ Glass</button>
        </div>
      </div>

      {/* workouts */}
      <div className="mx-4 mt-3 mb-6 rounded-2xl bg-white/[0.06] px-4 py-3">
        <div className="flex items-center justify-between">
          <span className="text-[13px] text-white/80">Workouts</span>
          <span className="text-[12px] text-white/50">{s.workouts.length} logged</span>
        </div>
        <div className="mt-2.5 flex flex-wrap gap-2">
          {QUICK_WORKOUTS.map((w) => (
            <button key={w.kind} onClick={() => addWorkout(w)}
              className="rounded-full bg-[#FF9F0A]/15 px-3.5 py-1.5 text-[12px] font-semibold text-[#FF9F0A] active:bg-[#FF9F0A]/30">
              + {w.kind} {w.mins}m
            </button>
          ))}
        </div>
        <div className="mt-3 space-y-1.5">
          {(s.workouts || []).map((w) => (
            <div key={w.id} className="flex items-center justify-between rounded-xl bg-white/[0.05] px-3 py-2">
              <span className="text-[13px]">{w.kind}</span>
              <span className="flex items-center gap-2 text-[12px] text-white/50">
                {w.mins} min
                <button onClick={() => removeWorkout(w.id)} aria-label="Remove workout" className="text-white/30"><X size={13} /></button>
              </span>
            </div>
          ))}
          {!(s.workouts || []).length && (
            <div className="py-2 text-center text-[12px] text-white/30">Tap a quick workout to log it</div>
          )}
        </div>
      </div>
    </div>
  );
}