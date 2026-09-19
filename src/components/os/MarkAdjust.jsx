import { Minus, Plus, RotateCw } from "lucide-react";

const step = (v, delta, min, max) =>
  Math.max(min, Math.min(max, Math.round(((v ?? 1) + delta) * 10) / 10));

// marker size / thickness / rotate-all adjuster, shared by the video, OS and
// UI marker popovers - all render on a dark popover surface
export default function MarkAdjust({ size, thickness, rot = 0, onChange }) {
  const btn = "rounded-md p-1 text-white/60 transition hover:bg-white/10 hover:text-white";
  const row = (label, value, min, max, key, fmt) => (
    <div className="flex items-center justify-between py-0.5">
      <span className="text-[9px] font-body uppercase tracking-wider text-white/45">{label}</span>
      <div className="flex items-center gap-1">
        <button onClick={() => onChange({ [key]: step(value, -0.1, min, max) })} className={btn} aria-label={`Smaller ${label}`}>
          <Minus size={11} />
        </button>
        <span className="w-9 text-center text-[10px] font-body text-white/80">{fmt}</span>
        <button onClick={() => onChange({ [key]: step(value, 0.1, min, max) })} className={btn} aria-label={`Larger ${label}`}>
          <Plus size={11} />
        </button>
      </div>
    </div>
  );
  return (
    <div className="mt-1 border-t border-white/10 px-2 pt-1.5">
      {row("Size", size, 0.4, 2.5, "size", `${Math.round((size ?? 1.1) * 100)}%`)}
      {row("Thickness", thickness, 0.2, 2, "thickness", `${Math.round((thickness ?? 0.6) * 100)}%`)}
      <div className="flex items-center justify-between py-0.5">
        <span className="text-[9px] font-body uppercase tracking-wider text-white/45">Rotate</span>
        <button onClick={() => onChange({ rot: (rot + 45) % 360 })}
          className="flex items-center gap-1 rounded-md px-1.5 py-1 text-[10px] font-body text-white/60 transition hover:bg-white/10 hover:text-white">
          <RotateCw size={11} /> {rot}°
        </button>
      </div>
    </div>
  );
}