import React, { useState, useRef } from "react";
import { allApps } from "@/lib/osApps";
import { cn } from "@/lib/utils";

const ORDER_KEY = "takeover-homescreen-order";
const defaultOrder = allApps.map((a) => a.id);

function loadOrder() {
  try {
    const saved = JSON.parse(localStorage.getItem(ORDER_KEY));
    if (Array.isArray(saved) && saved.length === allApps.length && allApps.every((a) => saved.includes(a.id))) {
      return saved;
    }
  } catch {}
  return defaultOrder;
}

export default function Homescreen({ onOpen }) {
  const now = new Date();
  const time = now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  const date = now.toLocaleDateString([], { weekday: "long", month: "long", day: "numeric" });

  const [order, setOrder] = useState(loadOrder);
  const dragIndex = useRef(null);
  const [draggingId, setDraggingId] = useState(null);

  const commit = (next) => {
    setOrder(next);
    localStorage.setItem(ORDER_KEY, JSON.stringify(next));
  };

  const handleDragEnter = (id) => {
    const from = dragIndex.current;
    if (from === null) return;
    const to = order.indexOf(id);
    if (from === to) return;
    const next = [...order];
    const [moved] = next.splice(from, 1);
    next.splice(to, 0, moved);
    dragIndex.current = to;
    commit(next);
  };

  const endDrag = () => {
    dragIndex.current = null;
    setDraggingId(null);
  };

  const apps = order.map((id) => allApps.find((a) => a.id === id));

  return (
    <div className="h-full flex flex-col text-white relative overflow-hidden"
      style={{ background: "linear-gradient(160deg, #1a1d2e 0%, #0a0b14 60%, #000 100%)" }}>
      <div className="grid-backdrop absolute inset-0 opacity-30" />
      <div className="relative flex flex-col items-center pt-10 pb-2">
        <div className="font-display text-6xl font-bold tracking-tight">{time}</div>
        <div className="text-sm text-white/60 mt-1">{date}</div>
      </div>
      <div className="relative flex-1 overflow-y-auto no-scrollbar" onDragOver={(e) => e.preventDefault()}>
        <div className="grid grid-cols-4 gap-y-5 gap-x-3 px-5 content-start pt-3 pb-4">
          {apps.map((a) => (
            <button key={a.id}
              draggable
              onDragStart={() => { dragIndex.current = order.indexOf(a.id); setDraggingId(a.id); }}
              onDragEnter={() => handleDragEnter(a.id)}
              onDragOver={(e) => e.preventDefault()}
              onDragEnd={endDrag}
              onClick={() => onOpen(a.id)}
              className={cn("flex flex-col items-center gap-1.5 active:scale-95 transition select-none",
                draggingId === a.id && "opacity-40")}>
              <span className="h-14 w-14 rounded-2xl flex items-center justify-center shadow-lg" style={{ background: a.bg }}>
                <a.Icon size={26} className="text-white" />
              </span>
              <span className="text-[11px] text-white/80">{a.label}</span>
            </button>
          ))}
        </div>
      </div>
      <div className="relative flex justify-center pb-5">
        <div className="text-[10px] text-white/30 font-body tracking-widest uppercase">drag apps to rearrange</div>
      </div>
    </div>
  );
}