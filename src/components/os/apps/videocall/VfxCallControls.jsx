import React from "react";
import { Check, X } from "lucide-react";
import MarkAdjust from "@/components/os/MarkAdjust";
import { trackingMarks, vfxColors } from "@/lib/vfxData";
import { cn } from "@/lib/utils";

// bottom sheet: chroma background + tracking-mark options for the mock
// caller's screen during a video call
export default function VfxCallControls({ vfx, onChange, onClose }) {
  const label = "mb-1.5 text-[9px] font-body uppercase tracking-[0.2em] text-white/40";
  return (
    <div className="absolute inset-0 z-20 flex items-end bg-black/60" onClick={onClose}>
      <div onClick={(e) => e.stopPropagation()}
        className="max-h-[82%] w-full overflow-y-auto rounded-t-3xl bg-[#1c1c1e] px-4 pb-5 pt-3 text-white shadow-2xl">
        <div className="mx-auto mb-3 h-1 w-10 rounded-full bg-white/20" />
        <div className="mb-3 flex items-center justify-between">
          <span className="font-display text-[15px] font-semibold">Caller screen</span>
          <button onClick={onClose} aria-label="Close"
            className="rounded-full bg-white/10 p-1.5 text-white/70"><X size={14} /></button>
        </div>

        <p className={label}>Background</p>
        <div className="mb-3 flex flex-wrap gap-1.5">
          {vfxColors.map((c) => (
            <button key={c.id} onClick={() => onChange({ bgColor: c.hex })} title={c.label}
              className={cn("h-7 w-7 rounded-full border border-white/25",
                vfx.bgColor === c.hex && "ring-1 ring-amber ring-offset-1 ring-offset-[#1c1c1e]")}
              style={{ background: c.hex }} />
          ))}
          <label title="Custom colour" className="cursor-pointer">
            <input type="color" value={vfx.bgColor || "#00B140"}
              onChange={(e) => onChange({ bgColor: e.target.value })}
              className="h-7 w-7 cursor-pointer rounded-full border border-white/25 bg-transparent p-0" />
          </label>
        </div>

        <p className={label}>Tracking marks</p>
        <div className="mb-3 flex flex-wrap gap-1.5">
          {trackingMarks.map((m) => (
            <button key={m.id} onClick={() => onChange({ markStyle: m.id })}
              className={cn("flex items-center gap-1 rounded-full border border-white/15 px-2.5 py-1 text-[10px] font-body transition hover:bg-white/10",
                vfx.markStyle === m.id ? "border-amber/60 bg-white/15 text-amber" : "text-white/70")}>
              {m.name}
              {vfx.markStyle === m.id && <Check size={10} />}
            </button>
          ))}
        </div>

        <p className={label}>Mark colour</p>
        <div className="mb-3 flex flex-wrap gap-1.5">
          <button onClick={() => onChange({ markColor: null })} title="Auto contrast"
            className={cn("h-7 w-7 rounded-full border border-white/25",
              !vfx.markColor && "ring-1 ring-amber ring-offset-1 ring-offset-[#1c1c1e]")}
            style={{ background: "linear-gradient(90deg, #000000 50%, #FFFFFF 50%)" }} />
          {vfxColors.map((c) => (
            <button key={c.id} onClick={() => onChange({ markColor: c.hex })} title={c.label}
              className={cn("h-7 w-7 rounded-full border border-white/25",
                vfx.markColor === c.hex && "ring-1 ring-amber ring-offset-1 ring-offset-[#1c1c1e]")}
              style={{ background: c.hex }} />
          ))}
          <label title="Custom colour" className="cursor-pointer">
            <input type="color" value={vfx.markColor || "#FFFFFF"}
              onChange={(e) => onChange({ markColor: e.target.value })}
              className="h-7 w-7 cursor-pointer rounded-full border border-white/25 bg-transparent p-0" />
          </label>
        </div>

        <MarkAdjust size={vfx.markSize} thickness={vfx.markThick} rot={vfx.markRot}
          onChange={(p) => onChange({
            ...(p.size !== undefined && { markSize: p.size }),
            ...(p.thickness !== undefined && { markThick: p.thickness }),
            ...(p.rot !== undefined && { markRot: p.rot }),
          })} />
      </div>
    </div>
  );
}