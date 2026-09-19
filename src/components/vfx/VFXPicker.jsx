import React from "react";
import { Maximize2, Check } from "lucide-react";
import { vfxColors, trackingMarks } from "@/lib/vfxData";
import { cn } from "@/lib/utils";

export default function VFXPicker({ color, setColor, marks, setMarks, onTakeover, compact }) {
  return (
    <div className={cn("flex flex-col gap-4", compact ? "" : "p-1")}>
      <div>
        <div className="text-[11px] uppercase tracking-wider text-muted-foreground font-body mb-2">Chroma Color</div>
        <div className="grid grid-cols-5 gap-2.5">
          {vfxColors.map((c) => (
            <button key={c.id} onClick={() => setColor(c.id)} title={c.label}
              className={cn("relative aspect-square rounded-xl border border-black/10 shadow-sm transition hover:scale-105 hover:shadow-md",
                color === c.id ? "ring-2 ring-amber ring-offset-2 ring-offset-background" : "hover:shadow-md")}
              style={{ background: c.hex }}>
              {color === c.id && (
                <span className="absolute inset-0 flex items-center justify-center">
                  <Check size={16} className={cn(c.id === "white" || c.id === "grey" ? "text-black" : "text-white")} />
                </span>
              )}
            </button>
          ))}
        </div>
      </div>

      <div>
        <div className="text-[11px] uppercase tracking-wider text-muted-foreground font-body mb-2">Tracking Marks</div>
        <div className="grid grid-cols-4 gap-2.5">
          {trackingMarks.map((m) => (
            <button key={m.id} onClick={() => setMarks(m.id)}
              className={cn("rounded-xl border px-2 py-2 text-[11px] font-body transition",
                marks === m.id ? "border-amber/60 bg-amber/10 text-amber font-semibold" : "border-border text-muted-foreground hover:text-foreground hover:border-muted-foreground/40")}>
              {m.name}
            </button>
          ))}
        </div>
      </div>

      <button onClick={onTakeover}
        className="w-full rounded-xl bg-amber text-background font-display font-semibold py-3 flex items-center justify-center gap-2 shadow-lg shadow-amber/25 hover:shadow-amber/40 hover:brightness-105 transition">
        <Maximize2 size={18} /> Takeover Stage
      </button>
    </div>
  );
}