import React, { useState, useRef } from "react";
import { Sun, Moon, Upload, Trash2, Loader2 } from "lucide-react";
import LockSettings from "./LockSettings";
import { bgPresets } from "@/hooks/useOsConfig";
import { base44 } from "@/api/base44Client";
import { cn } from "@/lib/utils";

function Section({ title, children }) {
  return (
    <div className="px-5 pt-2">
      <div className="text-[11px] uppercase tracking-wider text-white/40 font-body mb-2">{title}</div>
      <div className="rounded-xl bg-white/5 border border-white/10 px-4 py-3.5">{children}</div>
    </div>
  );
}

export default function SettingsApp({ config, update, onLock }) {
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState(false);
  const fileRef = useRef(null);

  const light = config.theme === "light";
  const bg = config.background || {};
  const hasImage = bg.type === "image" && bg.url;

  const onFile = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setUploading(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
      update({ background: { type: "image", preset: bg.preset || "default", url: file_url } });
      setUploadError(false);
    } catch {
      setUploadError(true);
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="h-full bg-[#0b0b0f] text-white overflow-y-auto no-scrollbar">
      <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={onFile} />

      <div className="px-5 pt-6 pb-2">
        <h2 className="font-display font-bold text-2xl">Settings</h2>
      </div>

      <Section title="Appearance">
        <button onClick={() => update({ theme: light ? "dark" : "light" })} className="flex w-full items-center gap-3">
          {light ? <Sun size={18} className="text-[#FF9F0A]" /> : <Moon size={18} className="text-[#5E5CE6]" />}
          <span className="flex-1 text-left text-sm">Light Mode</span>
          <span className={cn("relative h-6 w-11 rounded-full transition shrink-0", light ? "bg-[#34C759]" : "bg-white/20")}>
            <span className={cn("absolute top-0.5 h-5 w-5 rounded-full bg-white transition-all", light ? "left-[22px]" : "left-0.5")} />
          </span>
        </button>
      </Section>

      <Section title="Background">
        <div className="grid grid-cols-4 gap-2 mb-3">
          {bgPresets.map((p) => (
            <button key={p.id} onClick={() => update({ background: { type: "preset", preset: p.id, url: "" } })}
              className={cn("rounded-lg border-2 p-1 transition",
                !hasImage && (bg.preset || "default") === p.id ? "border-amber" : "border-white/10 hover:border-white/30")}>
              <span className="block h-8 rounded" style={{ background: p.dark }} />
            </button>
          ))}
        </div>
        <div className="flex gap-2">
          <button onClick={() => fileRef.current?.click()} disabled={uploading}
            className="flex-1 rounded-lg bg-[#0A84FF] text-white text-xs font-semibold py-2 flex items-center justify-center gap-1.5 disabled:opacity-60">
            {uploading ? <Loader2 size={14} className="animate-spin" /> : <Upload size={14} />} Upload Image
          </button>
          {hasImage && (
            <button onClick={() => update({ background: { type: "preset", preset: bg.preset || "default", url: "" } })}
              className="rounded-lg bg-white/10 text-white/80 text-xs px-3 py-2 flex items-center gap-1.5">
              <Trash2 size={14} /> Remove
            </button>
          )}
        </div>
        {uploadError && <p className="text-[11px] text-[#FF453A] font-body mt-2">image upload failed — try again</p>}
      </Section>

      <LockSettings config={config} update={update} onLock={onLock} />

      <p className="text-center text-[10px] text-white/25 font-body uppercase tracking-widest pt-6 pb-8">Takeover OS · prop build 1.0</p>
    </div>
  );
}