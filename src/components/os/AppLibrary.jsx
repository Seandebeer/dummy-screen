import React, { useState, useMemo } from "react";
import { X, Eye, EyeOff, Search } from "lucide-react";
import { coreApps } from "@/lib/osApps";
import { categories, mockApps } from "@/lib/mockAppCatalog";
import IconTile from "./IconTile";
import { cn } from "@/lib/utils";

const CHIPS = [
  { id: "all", name: "All" },
  { id: "functional", name: "Functional" },
  ...categories.map((c) => ({ id: c.id, name: c.name })),
];

export default function AppLibrary({ order, onToggle, onClose }) {
  const [query, setQuery] = useState("");
  const [cat, setCat] = useState("all");
  const q = query.trim().toLowerCase();

  const sections = useMemo(() => {
    const all = [
      { id: "functional", name: "Functional", apps: coreApps.map((a) => ({ ...a, sub: "Fully working" })) },
      ...categories.map((c) => ({
        id: c.id, name: c.name,
        apps: mockApps.filter((m) => m.category === c.id),
      })),
    ];
    return all
      .filter((s) => cat === "all" || s.id === cat)
      .map((s) => ({ ...s, apps: q ? s.apps.filter((a) => a.label.toLowerCase().includes(q)) : s.apps }))
      .filter((s) => s.apps.length > 0);
  }, [cat, q]);

  const row = (a) => {
    const visible = order.includes(a.id);
    return (
      <div key={a.id}
        className={cn("flex items-center gap-2.5 rounded-xl px-2.5 py-2 border transition",
          visible ? "border-white/15 bg-white/10" : "border-white/5 bg-white/[0.03] opacity-50")}>
        <IconTile app={a} size="sm" />
        <div className="flex-1 min-w-0">
          <div className="text-[12px] text-white truncate font-body">{a.label}</div>
          <div className="text-[9px] text-white/40 truncate font-body">{a.sub || ""}</div>
        </div>
        <button onClick={() => onToggle(a.id)}
          className={cn("flex items-center justify-center h-7 w-7 rounded-full shrink-0",
            visible ? "bg-white/20 text-white" : "bg-white/5 text-white/50")}>
          {visible ? <Eye size={14} /> : <EyeOff size={14} />}
        </button>
      </div>
    );
  };

  return (
    <div className="absolute inset-0 z-30 bg-black/75 backdrop-blur-sm flex flex-col" onClick={(e) => e.stopPropagation()}>
      <div className="flex items-center justify-between px-5 pt-4 pb-2">
        <div className="text-white font-display font-bold">App Library</div>
        <button onClick={onClose} className="text-white/70 hover:text-white"><X size={18} /></button>
      </div>
      <div className="px-4 pb-2">
        <div className="flex items-center gap-2 rounded-full border border-white/15 bg-white/10 px-3 py-1.5">
          <Search size={13} className="text-white/50 shrink-0" />
          <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search apps"
            className="w-full bg-transparent text-[12px] text-white placeholder-white/40 outline-none font-body" />
        </div>
      </div>
      <div className="flex gap-1.5 overflow-x-auto no-scrollbar px-4 pb-3">
        {CHIPS.map((c) => (
          <button key={c.id} onClick={() => setCat(c.id)}
            className={cn("shrink-0 rounded-full border px-3 py-1 text-[10px] font-body uppercase tracking-wider transition",
              cat === c.id ? "border-amber/60 bg-amber/20 text-amber" : "border-white/15 bg-white/5 text-white/60 hover:text-white")}>
            {c.name}
          </button>
        ))}
      </div>
      <p className="px-5 pb-2 text-[10px] text-white/40 font-body uppercase tracking-wider">Toggle apps on the home screen · drag icons to rearrange</p>
      <div className="flex-1 overflow-y-auto no-scrollbar px-4 pb-4">
        {sections.map((s) => (
          <div key={s.id} className="mb-4">
            <div className="text-[10px] uppercase tracking-wider text-white/40 font-body px-1 pb-1.5">{s.name}</div>
            <div className="grid grid-cols-2 gap-2">
              {s.apps.map(row)}
            </div>
          </div>
        ))}
        {!sections.length && (
          <p className="pt-10 text-center text-xs text-white/40 font-body">No apps match that search</p>
        )}
      </div>
    </div>
  );
}