import React, { useState, useEffect, useRef } from "react";
import { AlarmClock, Timer, Watch, Play, Pause, RotateCcw, Plus, Flag } from "lucide-react";
import { cn } from "@/lib/utils";

const tabs = [
  { id: "alarm", label: "Alarm", icon: AlarmClock },
  { id: "stopwatch", label: "Stopwatch", icon: Watch },
  { id: "timer", label: "Timer", icon: Timer },
];

function fmt(ms) {
  const total = Math.floor(ms / 1000);
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  const cs = Math.floor((ms % 1000) / 10);
  if (h > 0) return `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}.${String(cs).padStart(2, "0")}`;
}

function AlarmTab() {
  const [alarms, setAlarms] = useState([
    { id: 1, time: "06:30", label: "Call time", on: true },
    { id: 2, time: "18:00", label: "Night shoot", on: false },
  ]);
  const [adding, setAdding] = useState(false);
  const [newTime, setNewTime] = useState("07:00");
  const [newLabel, setNewLabel] = useState("");

  return (
    <div className="px-4 py-3 text-white">
      <div className="flex items-center justify-between mb-4">
        <h2 className="font-display text-xl font-bold">Alarms</h2>
        <button onClick={() => setAdding((v) => !v)} className="h-8 w-8 rounded-full bg-[#FF9F0A] flex items-center justify-center">
          <Plus size={18} className="text-black" />
        </button>
      </div>
      {adding && (
        <div className="mb-4 rounded-xl bg-white/5 p-3 border border-white/10">
          <div className="flex items-center gap-2">
            <input type="time" value={newTime} onChange={(e) => setNewTime(e.target.value)} className="bg-transparent text-2xl font-display text-white outline-none" />
            <input value={newLabel} onChange={(e) => setNewLabel(e.target.value)} placeholder="Label" className="flex-1 bg-white/5 rounded-lg px-2 py-1.5 text-sm text-white outline-none" />
            <button
              onClick={() => {
                setAlarms((a) => [...a, { id: Date.now(), time: newTime, label: newLabel || "Alarm", on: true }]);
                setAdding(false); setNewLabel("");
              }}
              className="rounded-lg bg-[#FF9F0A] px-3 py-1.5 text-sm font-semibold text-black"
            >Save</button>
          </div>
        </div>
      )}
      <div className="space-y-2">
        {alarms.map((a) => (
          <div key={a.id} className="flex items-center justify-between rounded-xl bg-white/5 px-4 py-3 border border-white/10">
            <div>
              <div className={cn("font-display text-2xl font-semibold", !a.on && "text-white/40")}>{a.time}</div>
              <div className="text-xs text-white/50">{a.label}</div>
            </div>
            <button
              onClick={() => setAlarms((arr) => arr.map((x) => x.id === a.id ? { ...x, on: !x.on } : x))}
              className={cn("relative h-7 w-12 rounded-full transition", a.on ? "bg-[#34C759]" : "bg-white/15")}
            >
              <span className={cn("absolute top-0.5 h-6 w-6 rounded-full bg-white transition-all", a.on ? "left-[22px]" : "left-0.5")} />
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}

function StopwatchTab() {
  const [elapsed, setElapsed] = useState(0);
  const [running, setRunning] = useState(false);
  const [laps, setLaps] = useState([]);
  const ref = useRef(null);
  const startRef = useRef(0);

  useEffect(() => {
    if (running) {
      startRef.current = Date.now() - elapsed;
      ref.current = setInterval(() => setElapsed(Date.now() - startRef.current), 31);
    } else if (ref.current) {
      clearInterval(ref.current);
    }
    return () => clearInterval(ref.current);
  }, [running]);

  return (
    <div className="px-4 py-3 text-white flex flex-col h-full">
      <h2 className="font-display text-xl font-bold mb-4">Stopwatch</h2>
      <div className="flex flex-col items-center justify-center flex-1">
        <div className="font-display text-6xl font-bold tabular-nums tracking-tight">{fmt(elapsed)}</div>
      </div>
      <div className="flex items-center justify-center gap-6 mb-4">
        <button
          onClick={() => { setRunning(false); setElapsed(0); setLaps([]); }}
          className="h-16 w-16 rounded-full bg-white/10 flex items-center justify-center"
        ><RotateCcw size={22} /></button>
        <button
          onClick={() => setRunning((r) => !r)}
          className={cn("h-16 w-16 rounded-full flex items-center justify-center", running ? "bg-[#FF3B30]" : "bg-[#34C759]")}
        >{running ? <Pause size={26} className="text-black" /> : <Play size={26} className="text-black ml-1" />}</button>
        <button
          onClick={() => running && setLaps((l) => [fmt(elapsed), ...l])}
          disabled={!running}
          className="h-16 w-16 rounded-full bg-white/10 flex items-center justify-center disabled:opacity-40"
        ><Flag size={20} /></button>
      </div>
      {laps.length > 0 && (
        <div className="max-h-32 overflow-auto no-scrollbar space-y-1">
          {laps.map((l, i) => (
            <div key={i} className="flex justify-between text-sm border-b border-white/10 py-1.5">
              <span className="text-white/50">Lap {laps.length - i}</span>
              <span className="tabular-nums">{l}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function TimerTab() {
  const [hours, setHours] = useState(0);
  const [mins, setMins] = useState(5);
  const [secs, setSecs] = useState(0);
  const [remaining, setRemaining] = useState(null);
  const [running, setRunning] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    if (running && remaining !== null) {
      ref.current = setInterval(() => {
        setRemaining((r) => {
          if (r <= 1) {
            clearInterval(ref.current); setRunning(false);
            return 0;
          }
          return r - 1;
        });
      }, 1000);
    } else if (ref.current) clearInterval(ref.current);
    return () => clearInterval(ref.current);
  }, [running]);

  const total = (remaining ?? hours * 3600 + mins * 60 + secs);
  const displayH = Math.floor(total / 3600);
  const displayM = Math.floor((total % 3600) / 60);
  const displayS = total % 60;
  const done = remaining === 0;

  return (
    <div className="px-4 py-3 text-white flex flex-col h-full">
      <h2 className="font-display text-xl font-bold mb-4">Timer</h2>
      {remaining === null || !running ? (
        <div className="flex items-center justify-center gap-2 my-8">
          {[["Hrs", hours, setHours, 23], ["Min", mins, setMins, 59], ["Sec", secs, setSecs, 59]].map(([lbl, val, set, max]) => (
            <div key={lbl} className="flex flex-col items-center">
              <input type="number" value={val} min={0} max={max}
                onChange={(e) => set(Math.min(max, Math.max(0, +e.target.value || 0)))}
                className="w-16 bg-white/5 rounded-lg py-2 text-center font-display text-3xl text-white outline-none border border-white/10" />
              <span className="text-[10px] text-white/40 mt-1 uppercase tracking-wider">{lbl}</span>
            </div>
          ))}
        </div>
      ) : (
        <div className="flex flex-col items-center justify-center flex-1">
          <div className={cn("font-display text-6xl font-bold tabular-nums", done && "text-[#FF3B30] animate-pulse")}>
            {String(displayH).padStart(2, "0")}:{String(displayM).padStart(2, "0")}:{String(displayS).padStart(2, "0")}
          </div>
          {done && <div className="mt-2 text-[#FF3B30] font-semibold">Timer finished</div>}
        </div>
      )}
      <div className="flex items-center justify-center gap-6 mb-4">
        <button
          onClick={() => { setRunning(false); setRemaining(null); }}
          className="h-16 w-16 rounded-full bg-white/10 flex items-center justify-center"
        ><RotateCcw size={22} /></button>
        <button
          onClick={() => {
            if (remaining === null || done) {
              const t = hours * 3600 + mins * 60 + secs;
              if (t <= 0) return;
              setRemaining(t);
            }
            setRunning((r) => !r);
          }}
          className={cn("h-16 w-16 rounded-full flex items-center justify-center", running ? "bg-[#FF3B30]" : "bg-[#34C759]")}
        >{running ? <Pause size={26} className="text-black" /> : <Play size={26} className="text-black ml-1" />}</button>
      </div>
    </div>
  );
}

export default function ClockApp() {
  const [tab, setTab] = useState("alarm");
  return (
    <div className="h-full flex flex-col bg-black text-white">
      <div className="flex border-b border-white/10">
        {tabs.map((t) => (
          <button key={t.id} onClick={() => setTab(t.id)}
            className={cn("flex-1 flex items-center justify-center gap-1.5 py-3 text-sm font-medium",
              tab === t.id ? "text-[#FF9F0A] border-b-2 border-[#FF9F0A]" : "text-white/50")}>
            <t.icon size={16} /> {t.label}
          </button>
        ))}
      </div>
      <div className="flex-1 overflow-auto no-scrollbar">
        {tab === "alarm" && <AlarmTab />}
        {tab === "stopwatch" && <StopwatchTab />}
        {tab === "timer" && <TimerTab />}
      </div>
    </div>
  );
}