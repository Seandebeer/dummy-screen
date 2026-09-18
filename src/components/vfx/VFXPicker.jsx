import React from "react";
import { Maximize2, Check } from "lucide-react";
import { vfxColors, trackingMarks } from "@/lib/vfxData";
import { cn } from "@/lib/utils";

export default function VFXPicker({ color, setColor, marks, setMarks, onTakeover, compact }) {
  return (
    <div className={cn("flex flex-col gap-4", compact ? "" : "p-1")}>
      <div>
        <div className="text-[11px] uppercase tracking-wider text-muted-foreground font-body mb-2">Chroma Color</div>
        <div className="grid grid-cols-5 gap-2">
          {vfxColors.map((c) => (
            <button key={c.id} onClick={() => setColor(c.id)}
              className={cn("relative aspect-square rounded-lg border transition group", color === c.id ? "border-amber amber-pulse" : "border-border hover:border-muted-foreground")}
              style={{ background: c.hex }}>
              {color === c.id && (
                <span className="absolute inset-0 flex items-center justify-center">
                  <Check size={16} className={cn(c.id === "white" || c.id === "green" ? "text-black" : "text-white")} />
                </span>
              )}
              <span className={cn("absolute -bottom-5 left-1/2 -translate-x-1/2 text-[9px] font-body whitespace-nowrap",
                c.id === "white" ? "text-black" : "text-white/70")} />
            </button>
          ))}
        </div>
      </div>

      <div>
        <div className="text-[11px] uppercase tracking-wider text-muted-foreground font-body mb-2">Tracking Marks</div>
        <div className="grid grid-cols-4 gap-2">
          {trackingMarks.map((m) => (
            <button key={m.id} onClick={() => setMarks(m.id)}
              className={cn("rounded-lg border px-2 py-2 text-[11px] font-body transition",
                marks === m.id ? "border-amber bg-amber/10 text-amber" : "border-border text-muted-foreground hover:text-foreground")}>
              {m.name}
            </button>
          ))}
        </div>
      </div>

      <button onClick={onTakeover}
        className="w-full rounded-lg bg-amber text-background font-display font-bold py-3 flex items-center justify-center gap-2 hover:brightness-110 transition">
        <Maximize2 size={18} /> Takeover Stage
      </button>
    </div>
  );
}