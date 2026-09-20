import React, { useRef, useState } from "react";
import { Eye, EyeOff, Loader2, Upload, X } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { Image } from "@/components/ui/image";
import { Slider } from "@/components/ui/slider";
import { cn } from "@/lib/utils";

// shared image overlay for the VFX stage and the UI markers screen: upload a
// reference image, set its opacity and quickly show/hide it.
export const DEFAULT_OVERLAY = { url: null, opacity: 100, hidden: false };

// the rendered overlay itself - drawn above the screen content, never interactive
export function OverlayLayer({ overlay }) {
  const o = { ...DEFAULT_OVERLAY, ...(overlay || {}) };
  if (!o.url || o.hidden) return null;
  return (
    <div className="absolute inset-0 z-[5] pointer-events-none" style={{ opacity: o.opacity / 100 }}>
      <Image src={o.url} alt="Overlay reference" fittingType="fit"
        className="h-full w-full object-contain" />
    </div>
  );
}

// popover body: upload/replace/remove, opacity slider and show/hide toggle
export function OverlayControl({ overlay, onChange }) {
  const o = { ...DEFAULT_OVERLAY, ...(overlay || {}) };
  const fileRef = useRef(null);
  const [uploading, setUploading] = useState(false);

  const handleUpload = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setUploading(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
      onChange({ url: file_url, hidden: false });
    } catch {}
    setUploading(false);
  };

  return (
    <div>
      <p className="mb-1 px-2 text-[9px] font-body uppercase tracking-[0.2em] text-white/50">Image overlay</p>
      <button disabled={uploading} onClick={() => fileRef.current?.click()}
        className="flex w-full items-center gap-2.5 rounded-lg px-2 py-1.5 text-[11px] font-body transition hover:bg-white/10 disabled:opacity-50">
        {uploading ? <Loader2 size={14} className="animate-spin" /> : <Upload size={14} />}
        {uploading ? "Uploading…" : o.url ? "Replace image" : "Upload image"}
      </button>
      <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={handleUpload} />

      {o.url && (
        <>
          <div className="mt-3 px-2">
            <div className="mb-1 flex items-center justify-between text-[9px] font-body uppercase tracking-[0.2em]">
              <span>Opacity</span>
              <span className="text-white/60">{o.opacity}%</span>
            </div>
            <Slider value={[o.opacity]} min={0} max={100} step={5}
              onValueChange={([v]) => onChange({ opacity: v })} />
          </div>
          <div className="mt-3 border-t border-white/10 pt-1.5">
            <button onClick={() => onChange({ hidden: !o.hidden })}
              className="flex w-full items-center gap-2.5 rounded-lg px-2 py-1.5 text-[11px] font-body transition hover:bg-white/10">
              {o.hidden ? <EyeOff size={14} /> : <Eye size={14} />}
              {o.hidden ? "Hidden - show on screen" : "Visible - hide it"}
            </button>
            <button onClick={() => onChange({ url: null, opacity: 100, hidden: false })}
              className="flex w-full items-center gap-2.5 rounded-lg px-2 py-1.5 text-[11px] font-body transition hover:bg-white/10">
              <X size={14} /> Remove image
            </button>
          </div>
        </>
      )}
    </div>
  );
}