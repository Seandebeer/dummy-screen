import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Trash2, Crosshair, Monitor } from "lucide-react";
import { listSaved, deleteConfig } from "@/lib/savedConfigs";

export default function SavedPanel() {
  const [saved, setSaved] = useState(listSaved);
  const navigate = useNavigate();

  const open = (s) => {
    if (s.kind === "markers") {
      try {
        const cfg = JSON.parse(localStorage.getItem("takeover-os-config")) || {};
        cfg.uiMarkers = s.uiMarkers;
        localStorage.setItem("takeover-os-config", JSON.stringify(cfg));
      } catch {}
      navigate("/uimarkers");
    } else {
      try {
        localStorage.setItem("takeover-screen-marks", JSON.stringify(s.marks));
      } catch {}
      navigate(`/vfx?color=${s.colorId}&marks=${s.marksId}`);
    }
  };

  const remove = (id) => setSaved(deleteConfig(id));

  if (saved.length === 0) {
    return (
      <div className="py-6 text-center text-muted-foreground text-xs font-body">
        Nothing saved yet - save a marker configuration or a key screen.
      </div>
    );
  }

  return (
    <div className="divide-y divide-border">
      {saved.map((s) => (
        <div key={s.id} className="flex items-center gap-3 py-3">
          <span className="h-8 w-8 rounded-lg bg-muted/60 text-muted-foreground flex items-center justify-center shrink-0">
            {s.kind === "markers" ? <Crosshair size={15} /> : <Monitor size={15} />}
          </span>
          <div className="flex-1 min-w-0">
            <div className="text-sm font-body truncate">{s.name}</div>
            <div className="text-[10px] uppercase tracking-wider text-muted-foreground font-body">
              {s.kind === "markers" ? "UI Markers" : "Key Screen"}
            </div>
          </div>
          <button onClick={() => open(s)}
            className="rounded-lg bg-amber/15 border border-amber/30 text-amber text-xs font-body px-3 py-1.5 hover:bg-amber/25 transition">
            Open
          </button>
          <button onClick={() => remove(s.id)}
            className="h-8 w-8 rounded-lg border border-border text-muted-foreground hover:text-alert hover:border-alert/40 flex items-center justify-center transition">
            <Trash2 size={14} />
          </button>
        </div>
      ))}
    </div>
  );
}