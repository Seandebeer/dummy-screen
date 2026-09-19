import React from "react";
import { Link } from "react-router-dom";
import { ArrowLeft, Check, Palette, Plus, RotateCcw, Save, Shapes, SlidersHorizontal } from "lucide-react";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Slider } from "@/components/ui/slider";
import { trackingMarks, vfxColors } from "@/lib/vfxData";
import { cn } from "@/lib/utils";

const glass = "bg-black/55 text-white border-white/15 shadow-2xl backdrop-blur-xl";
const btn = "flex h-9 w-9 items-center justify-center rounded-full transition hover:bg-white/15";
const divider = "h-5 w-px bg-white/15 mx-0.5";
const panel = "border-white/15 bg-black/80 text-white backdrop-blur-xl shadow-2xl";

export default function StageToolbar({
  colorId, marksId, isPoint, marks,
  onSelectColor, onSelectMarks, onScale, onThick, onAdd, onSave, onReset,
}) {
  return (
    <div className="absolute inset-x-0 bottom-6 z-40 flex flex-col items-center gap-3 px-4">
      {/* lock hint */}
      <div className={cn("pointer-events-none flex items-center gap-2 rounded-full px-4 py-1.5 text-[11px] font-body tracking-wide", glass)}>
        <span className="h-1.5 w-1.5 rounded-full bg-amber amber-pulse" />
        3-Finger Tap to Lock / Unlock
      </div>

      {/* single consolidated tool bar */}
      <div className={cn("flex flex-wrap items-center justify-center gap-0.5 rounded-full border p-1.5 max-w-[92vw]", glass)}>
        <Link to="/" title="Exit stage" className={btn}><ArrowLeft size={16} /></Link>
        <span className={divider} />

        <Popover>
          <PopoverTrigger asChild>
            <button title="Colour" className={btn}><Palette size={16} /></button>
          </PopoverTrigger>
          <PopoverContent side="top" align="start" className={cn("w-44 p-2", panel)}>
            {marksId === "checkerboard" ? (
              <p className="px-2 py-1 text-[10px] font-body text-white/60">Black &amp; white only</p>
            ) : vfxColors.map((c) => (
              <button key={c.id} onClick={() => onSelectColor(c.id)}
                className="flex w-full items-center gap-2.5 rounded-lg px-2 py-1.5 text-[11px] font-body transition hover:bg-white/10">
                <span className="h-4 w-4 rounded-full border border-white/25" style={{ background: c.hex }} />
                {c.label}
                {colorId === c.id && <Check size={12} className="ml-auto text-amber" />}
              </button>
            ))}
          </PopoverContent>
        </Popover>

        <Popover>
          <PopoverTrigger asChild>
            <button title="Tracking marks" className={btn}><Shapes size={16} /></button>
          </PopoverTrigger>
          <PopoverContent side="top" className={cn("w-36 p-1.5", panel)}>
            {trackingMarks.map((m) => (
              <button key={m.id} onClick={() => onSelectMarks(m.id)}
                className="flex w-full items-center justify-between rounded-lg px-2.5 py-1.5 text-[10px] font-body uppercase tracking-wider transition hover:bg-white/10">
                {m.name}
                {marksId === m.id && <Check size={12} className="text-amber" />}
              </button>
            ))}
          </PopoverContent>
        </Popover>

        {marksId !== "none" && (
          <Popover>
            <PopoverTrigger asChild>
              <button title="Size & thickness" className={btn}><SlidersHorizontal size={16} /></button>
            </PopoverTrigger>
            <PopoverContent side="top" align="end" className={cn("w-56 p-4", panel)}>
              <div className="mb-1 flex items-center justify-between text-[9px] font-body uppercase tracking-[0.2em]">
                <span>Size</span>
                <span className="text-white/60">{Number(marks.scale.toFixed(2))}×</span>
              </div>
              <Slider value={[marks.scale]} min={0.5} max={3} step={0.25} onValueChange={([v]) => onScale(v)} />
              {marksId !== "checkerboard" && (
                <div className="mt-4">
                  <div className="mb-1 flex items-center justify-between text-[9px] font-body uppercase tracking-[0.2em]">
                    <span>Thickness</span>
                    <span className="text-white/60">{Number(marks.thickness.toFixed(2))}×</span>
                  </div>
                  <Slider value={[marks.thickness]} min={0.5} max={3} step={0.25} onValueChange={([v]) => onThick(v)} />
                </div>
              )}
            </PopoverContent>
          </Popover>
        )}
        <span className={divider} />

        {isPoint && (
          <button title="Add marker" onClick={onAdd} className={btn}><Plus size={16} /></button>
        )}
        <button title="Save screen" onClick={onSave} className={btn}><Save size={16} /></button>
        {marksId !== "none" && (
          <button title="Reset" onClick={onReset} className={btn}><RotateCcw size={16} /></button>
        )}
      </div>
    </div>
  );
}