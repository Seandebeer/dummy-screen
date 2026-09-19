import React from "react";
import { X, Upload, Trash2, Loader2 } from "lucide-react";
import { bgPresets } from "@/hooks/useOsConfig";
import { cn } from "@/lib/utils";

export default function BackgroundPanel({ background, uploading, onPickPreset, onUpload, onRemoveImage, onClose }) {
  const isImage = background.type === "image" && background.url;
  return (
    <div className="absolute inset-0 z-30 bg-black/75 backdrop-blur-sm flex flex-col" onClick={(e) => e.stopPropagation()}>
      <div className="flex items-center justify-between px-5 pt-4 pb-1">
        <div className="text-white font-display font-bold">Background</div>
        <button onClick={onClose} className="text-white/70 hover:text-white"><X size={18} /></button>
      </div>
      <p className="px-5 pb-3 text-[10px] text-white/40 font-body uppercase tracking-wider">Presets adapt to the theme</p>
      <div className="grid grid-cols-2 gap-2 px-4">
        {bgPresets.map((p) => (
          <button key={p.id} onClick={() => onPickPreset(p.id)}
            className={cn("rounded-xl border-2 p-1.5 flex flex-col gap-1.5 transition",
              !isImage && (background.preset || "default") === p.id ? "border-amber" : "border-white/15 hover:border-white/40")}>
            <span className="h-10 rounded-lg" style={{ background: p.dark }} />
            <span className="text-[10px] text-white/80 font-body text-center">{p.name}</span>
          </button>
        ))}
      </div>
      <div className="px-4 pt-3 flex flex-col gap-2">
        <button onClick={onUpload} disabled={uploading}
          className="rounded-lg bg-white/85 text-black text-xs font-semibold py-2 flex items-center justify-center gap-2 disabled:opacity-60">
          {uploading ? <Loader2 size={14} className="animate-spin" /> : <Upload size={14} />} Upload image
        </button>
        {isImage && (
          <button onClick={onRemoveImage} className="rounded-lg bg-white/10 text-white/80 text-xs py-2 flex items-center justify-center gap-2">
            <Trash2 size={14} /> Remove image
          </button>
        )}
      </div>
    </div>
  );
}