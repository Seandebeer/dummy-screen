import React, { useState } from "react";
import { X } from "lucide-react";

export default function ClockEditor({ clock, onSave, onClose }) {
  const [time, setTime] = useState(clock.mode === "custom" ? clock.time : "");
  const [date, setDate] = useState(clock.mode === "custom" ? clock.date : "");

  return (
    <div className="rounded-xl bg-black/75 backdrop-blur border border-white/15 p-3 flex flex-col gap-2" onClick={(e) => e.stopPropagation()}>
      <div className="flex items-center justify-between">
        <span className="text-white/80 text-[10px] font-body uppercase tracking-wider">Set clock display</span>
        <button onClick={onClose} className="text-white/50 hover:text-white"><X size={14} /></button>
      </div>
      <input value={time} onChange={(e) => setTime(e.target.value)} placeholder="Time — e.g. 9:41"
        className="rounded-lg bg-white/10 border border-white/15 px-2.5 py-1.5 text-sm text-white outline-none placeholder:text-white/25" />
      <input value={date} onChange={(e) => setDate(e.target.value)} placeholder="Date — e.g. Friday, June 6"
        className="rounded-lg bg-white/10 border border-white/15 px-2.5 py-1.5 text-xs text-white outline-none placeholder:text-white/25" />
      <div className="flex gap-2">
        <button onClick={() => onSave({ mode: "custom", time: time.trim(), date: date.trim() })}
          className="flex-1 rounded-lg bg-white/85 text-black text-xs font-semibold py-1.5">Set</button>
        <button onClick={() => onSave({ mode: "live", time: "", date: "" })}
          className="flex-1 rounded-lg bg-white/10 text-white/80 text-xs py-1.5">Live clock</button>
      </div>
    </div>
  );
}