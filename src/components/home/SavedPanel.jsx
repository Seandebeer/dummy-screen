import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Trash2, Crosshair, Monitor, ChevronDown, Globe, Users, LayoutGrid } from "lucide-react";
import { listSaved, deleteConfig, mergeCloudEntries } from "@/lib/savedConfigs";
import { syncNow, SYNC_EVENT } from "@/lib/cloudSync";
import SyncBadge from "@/components/home/SyncBadge";
import { applyPage } from "@/lib/savedPages";

const CATEGORIES = ["All", "UI Markers", "Key Screens", "Socials", "Websites", "Apps"];

const categoryOf = (s) =>
  s.kind === "markers" ? "UI Markers"
  : s.kind === "screen" ? "Key Screens"
  : s.category || "Pages";

const iconFor = (s) =>
  s.kind === "markers" ? <Crosshair size={15} />
  : s.kind === "screen" ? <Monitor size={15} />
  : s.category === "Websites" ? <Globe size={15} />
  : s.category === "Apps" ? <LayoutGrid size={15} />
  : <Users size={15} />;

export default function SavedPanel() {
  const [saved, setSaved] = useState(listSaved);
  const [cat, setCat] = useState("All");
  const navigate = useNavigate();

  // load the shared cloud library (falls back to the local copy with no
  // signal), and refresh whenever a sync lands or the queue changes
  useEffect(() => {
    let alive = true;
    syncNow().then((entries) => {
      if (alive && entries) setSaved(mergeCloudEntries(entries));
    });
    const onSync = (e) => {
      if (e.detail?.entries) setSaved(mergeCloudEntries(e.detail.entries));
      else setSaved(listSaved());
    };
    window.addEventListener(SYNC_EVENT, onSync);
    return () => {
      alive = false;
      window.removeEventListener(SYNC_EVENT, onSync);
    };
  }, []);

  const open = (s) => {
    if (s.kind === "markers") {
      try {
        const cfg = JSON.parse(localStorage.getItem("takeover-os-config")) || {};
        cfg.uiMarkers = s.uiMarkers;
        localStorage.setItem("takeover-os-config", JSON.stringify(cfg));
      } catch {}
      navigate("/uimarkers");
    } else if (s.kind === "page") {
      applyPage(s);
      navigate("/os");
    } else {
      try {
        localStorage.setItem("takeover-screen-marks", JSON.stringify(s.marks));
      } catch {}
      navigate(`/vfx?color=${s.colorId}&marks=${s.marksId}`);
    }
  };

  const remove = (id) => setSaved(deleteConfig(id));

  const visible = saved.filter((s) => cat === "All" || categoryOf(s) === cat);

  return (
    <div className="pt-1">
      {/* category dropdown */}
      <div className="flex items-center justify-between pb-1 pt-2">
        <div className="flex items-center gap-2">
          <span className="text-[10px] uppercase tracking-wider text-muted-foreground font-body">Category</span>
          <SyncBadge />
        </div>
        <div className="relative">
          <select
            value={cat}
            onChange={(e) => setCat(e.target.value)}
            className="cursor-pointer appearance-none rounded-lg border border-border bg-muted/40 py-1.5 pl-3 pr-8 text-xs font-body outline-none transition hover:border-amber/40"
          >
            {CATEGORIES.map((c) => (
              <option key={c} value={c}>{c}</option>
            ))}
          </select>
          <ChevronDown size={13} className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
        </div>
      </div>

      {saved.length === 0 ? (
        <div className="py-6 text-center text-muted-foreground text-xs font-body">
          Nothing saved yet - save marker setups, key screens, social pages or websites.
        </div>
      ) : visible.length === 0 ? (
        <div className="py-6 text-center text-muted-foreground text-xs font-body">
          Nothing in this category yet.
        </div>
      ) : (
        <div className="divide-y divide-border">
          {visible.map((s) => (
            <div key={s.id} className="flex items-center gap-3 py-3">
              <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-muted/60 text-muted-foreground">
                {iconFor(s)}
              </span>
              <div className="min-w-0 flex-1">
                <div className="truncate text-sm font-body">{s.name}</div>
                <div className="text-[10px] uppercase tracking-wider text-muted-foreground font-body">
                  {categoryOf(s)}
                </div>
              </div>
              <button onClick={() => open(s)}
                className="rounded-lg border border-amber/30 bg-amber/15 px-3 py-1.5 text-xs font-body text-amber transition hover:bg-amber/25">
                Open
              </button>
              <button onClick={() => remove(s.id)}
                className="flex h-8 w-8 items-center justify-center rounded-lg border border-border text-muted-foreground transition hover:border-alert/40 hover:text-alert">
                <Trash2 size={14} />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}