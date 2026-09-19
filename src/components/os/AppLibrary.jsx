import React, { useState, useEffect, useMemo } from "react";
import { ChevronDown, Eye, EyeOff, Search, Star, X } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { allApps, coreApps } from "@/lib/osApps";
import { categories, mockApps } from "@/lib/mockAppCatalog";
import IconTile from "./IconTile";
import { cn } from "@/lib/utils";

const LOCAL_FAVS = "propscreen-favorites";

export default function AppLibrary({ order, onToggle, onClose }) {
  const [query, setQuery] = useState("");
  const [open, setOpen] = useState({});
  const [favs, setFavs] = useState(null);

  // favourites are remembered on the user profile (local fallback)
  useEffect(() => {
    (async () => {
      try {
        const me = await base44.auth.me();
        setFavs(me.app_favorites || []);
      } catch {
        try { setFavs(JSON.parse(localStorage.getItem(LOCAL_FAVS)) || []); } catch { setFavs([]); }
      }
    })();
  }, []);

  const toggleFav = async (id) => {
    if (!favs) return;
    const next = favs.includes(id) ? favs.filter((x) => x !== id) : [...favs, id];
    setFavs(next);
    try { await base44.auth.updateMe({ app_favorites: next }); return; } catch {}
    localStorage.setItem(LOCAL_FAVS, JSON.stringify(next));
  };

  const q = query.trim().toLowerCase();

  const sections = useMemo(() => {
    const list = [
      { id: "favourites", name: "Favourites", apps: allApps.filter((a) => favs?.includes(a.id)) },
      { id: "functional", name: "Functional", apps: coreApps.map((a) => ({ ...a, sub: "Fully working" })) },
      ...[...categories]
        .sort((a, b) => a.name.localeCompare(b.name))
        .map((c) => ({ id: c.id, name: c.name, apps: mockApps.filter((m) => m.category === c.id) })),
    ];
    return list.map((s) => ({
      ...s,
      apps: q ? s.apps.filter((a) => a.label.toLowerCase().includes(q)) : s.apps,
    }));
  }, [q, favs]);

  const row = (a) => {
    const visible = order.includes(a.id);
    const faved = favs?.includes(a.id);
    return (
      <div key={a.id}
        className={cn("flex items-center gap-2.5 rounded-xl px-2.5 py-2 border transition",
          visible ? "border-white/15 bg-white/10" : "border-white/5 bg-white/[0.03] opacity-50")}>
        <IconTile app={a} size="sm" />
        <div className="flex-1 min-w-0">
          <div className="text-[12px] text-white truncate font-body">{a.label}</div>
          <div className="text-[9px] text-white/40 truncate font-body">{a.sub || ""}</div>
        </div>
        <button onClick={() => toggleFav(a.id)} title="Favourite"
          className={cn("flex items-center justify-center h-7 w-7 rounded-full shrink-0 transition",
            faved ? "bg-amber/20 text-amber" : "bg-white/5 text-white/40 hover:text-white")}>
          <Star size={13} fill={faved ? "currentColor" : "none"} />
        </button>
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
      <p className="px-5 pb-2 text-[10px] text-white/40 font-body uppercase tracking-wider">Star favourites · toggle apps on the home screen</p>
      <div className="flex-1 overflow-y-auto no-scrollbar px-4 pb-4">
        {sections.map((s) => {
          if (q && !s.apps.length) return null;
          const expanded = q ? true : !!open[s.id];
          return (
            <div key={s.id} className="mb-2.5">
              <button onClick={() => setOpen((o) => ({ ...o, [s.id]: !o[s.id] }))}
                className="flex w-full items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-3 py-2 transition hover:bg-white/10">
                {s.id === "favourites" && <Star size={12} className="text-amber shrink-0" />}
                <span className="flex-1 text-left text-[11px] uppercase tracking-wider text-white/70 font-body">{s.name}</span>
                <span className="text-[10px] text-white/40 font-body">{s.apps.length}</span>
                <ChevronDown size={14} className={cn("text-white/50 transition-transform shrink-0", expanded && "rotate-180")} />
              </button>
              {expanded && (
                <div className="pt-2">
                  {s.id === "favourites" && !s.apps.length ? (
                    <p className="px-1 pb-1 text-[10px] text-white/35 font-body">Tap the star on any app to save it here</p>
                  ) : (
                    <div className="grid grid-cols-2 gap-2">
                      {s.apps.map(row)}
                    </div>
                  )}
                </div>
              )}
            </div>
          );
        })}
        {q && sections.every((s) => !s.apps.length) && (
          <p className="pt-10 text-center text-xs text-white/40 font-body">No apps match that search</p>
        )}
      </div>
    </div>
  );
}