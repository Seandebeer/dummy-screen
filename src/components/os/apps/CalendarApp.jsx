import React, { useState } from "react";
import { ChevronLeft, ChevronRight, Plus, Trash2 } from "lucide-react";
import { cn } from "@/lib/utils";

const KEY = "takeover-os-calendar";
const DOW = ["S", "M", "T", "W", "T", "F", "S"];

const loadEvents = () => {
  try {
    const ev = JSON.parse(localStorage.getItem(KEY));
    return ev && typeof ev === "object" ? ev : {};
  } catch {
    return {};
  }
};
const saveEvents = (ev) => {
  try { localStorage.setItem(KEY, JSON.stringify(ev)); } catch {}
};
const key = (y, m, d) => `${y}-${String(m + 1).padStart(2, "0")}-${String(d).padStart(2, "0")}`;

export default function CalendarApp() {
  const today = new Date();
  const [cursor, setCursor] = useState({ y: today.getFullYear(), m: today.getMonth() });
  const [selected, setSelected] = useState(null);
  const [events, setEvents] = useState(loadEvents);
  const [draft, setDraft] = useState("");

  const persist = (next) => { setEvents(next); saveEvents(next); };
  const first = new Date(cursor.y, cursor.m, 1).getDay();
  const days = new Date(cursor.y, cursor.m + 1, 0).getDate();
  const cells = [...Array(first).fill(null), ...Array.from({ length: days }, (_, i) => i + 1)];
  const todayKey = key(today.getFullYear(), today.getMonth(), today.getDate());
  const dayEvents = selected ? (events[selected] || []) : [];

  const move = (dir) =>
    setCursor(({ y, m }) => { const d = new Date(y, m + dir, 1); return { y: d.getFullYear(), m: d.getMonth() }; });

  const addEvent = () => {
    if (!draft.trim() || !selected) return;
    persist({
      ...events,
      [selected]: [...dayEvents, { id: `e-${Date.now()}`, title: draft.trim() }].sort((a, b) => a.title.localeCompare(b.title)),
    });
    setDraft("");
  };
  const removeEvent = (id) =>
    persist({ ...events, [selected]: dayEvents.filter((e) => e.id !== id) });

  return (
    <div className="h-full flex flex-col bg-background text-foreground p-3 gap-3 overflow-y-auto no-scrollbar">
      <div className="flex items-center justify-between">
        <div className="font-display font-semibold text-lg">
          {new Date(cursor.y, cursor.m).toLocaleString([], { month: "long", year: "numeric" })}
        </div>
        <div className="flex gap-1">
          <button onClick={() => move(-1)} className="h-8 w-8 rounded-full bg-muted hover:bg-secondary flex items-center justify-center"><ChevronLeft size={16} /></button>
          <button onClick={() => move(1)} className="h-8 w-8 rounded-full bg-muted hover:bg-secondary flex items-center justify-center"><ChevronRight size={16} /></button>
        </div>
      </div>

      <div className="grid grid-cols-7 text-center text-[10px] text-muted-foreground font-body">
        {DOW.map((d, i) => <span key={i}>{d}</span>)}
      </div>

      <div className="grid grid-cols-7 gap-1">
        {cells.map((d, i) => {
          if (d == null) return <span key={i} />;
          const k = key(cursor.y, cursor.m, d);
          const has = (events[k] || []).length > 0;
          return (
            <button key={i} onClick={() => setSelected(k)}
              className={cn("relative h-9 rounded-xl text-sm font-body flex items-center justify-center",
                selected === k ? "bg-amber text-black font-semibold" : "bg-muted hover:bg-secondary",
                k === todayKey && selected !== k && "ring-1 ring-amber/60")}>
              {d}
              {has && <span className={cn("absolute bottom-1 h-1 w-1 rounded-full", selected === k ? "bg-black" : "bg-amber")} />}
            </button>
          );
        })}
      </div>

      {selected && (
        <div className="rounded-2xl border border-border p-3 flex flex-col gap-2">
          <div className="text-[11px] font-body text-muted-foreground">
            {new Date(selected + "T00:00:00").toLocaleDateString([], { weekday: "long", day: "numeric", month: "long" })}
          </div>
          {dayEvents.map((e) => (
            <div key={e.id} className="flex items-center justify-between rounded-xl bg-muted px-3 py-2">
              <span className="text-sm font-body truncate">{e.title}</span>
              <button onClick={() => removeEvent(e.id)} className="text-muted-foreground hover:text-alert shrink-0"><Trash2 size={14} /></button>
            </div>
          ))}
          <div className="flex gap-2">
            <input value={draft} onChange={(e) => setDraft(e.target.value)} onKeyDown={(e) => e.key === "Enter" && addEvent()}
              placeholder="New event…"
              className="flex-1 min-w-0 rounded-xl bg-muted px-3 py-2 text-sm font-body outline-none focus:ring-1 ring-amber/60" />
            <button onClick={addEvent} className="rounded-xl bg-amber text-black px-3 flex items-center"><Plus size={16} /></button>
          </div>
        </div>
      )}
    </div>
  );
}