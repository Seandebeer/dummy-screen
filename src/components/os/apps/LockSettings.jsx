import React, { useState, useRef } from "react";
import { Hash, Grid3x3, ScanFace, Fingerprint, Upload, Trash2, Loader2, Check, Sparkles, ChevronsRight, CircleDot, ChevronUp } from "lucide-react";
import { bgPresets } from "@/hooks/useOsConfig";
import { base44 } from "@/api/base44Client";
import { skinUi } from "@/lib/osSkins";
import { cn } from "@/lib/utils";

const METHODS = [
  { id: "none", label: "Skin Default", hint: "era-accurate for this skin", Icon: Sparkles },
  { id: "slide", label: "Slide to Unlock", hint: "drag the slider right", Icon: ChevronsRight },
  { id: "ring", label: "Unlock Ring", hint: "drag the lock into the ring", Icon: CircleDot },
  { id: "passcode", label: "Passcode", hint: "4-digit keypad", Icon: Hash },
  { id: "pattern", label: "Pattern", hint: "connect-the-dots", Icon: Grid3x3 },
  { id: "face", label: "Face Scan", hint: "scan animation", Icon: ScanFace },
  { id: "fingerprint", label: "Fingerprint", hint: "press & hold sensor", Icon: Fingerprint },
  { id: "swipe", label: "Swipe Up", hint: "always swipe up", Icon: ChevronUp },
];

const DEFAULT_LOCK = { type: "none", background: { type: "preset", preset: "default", url: "" } };

export default function LockSettings({ config, update, onLock, bare = false }) {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState(false);
  const fileRef = useRef(null);

  const lock = config.lockscreen || DEFAULT_LOCK;
  const lb = lock.background || DEFAULT_LOCK.background;
  const hasImage = lb.type === "image" && lb.url;

  const setLock = (patch) => update({ lockscreen: { ...lock, ...patch } });
  const setBg = (background) => setLock({ background });

  const onFile = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setUploading(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
      setBg({ type: "image", preset: lb.preset || "default", url: file_url });
      setError(false);
    } catch {
      setError(true);
    } finally {
      setUploading(false);
    }
  };

  const needsSetup =
    (lock.type === "passcode" && !config.passcode) ||
    (lock.type === "pattern" && !config.pattern);

  // what "Skin Default" opens with on the active skin - the modern skins
  // (and other flat skins) resolve to swipe up
  const skinMethod = (skinUi(config.skin).lock || {}).method || "none";
  const defaultLabel = METHODS.find((m) => m.id === (skinMethod === "none" ? "swipe" : skinMethod))?.label || "Swipe Up";

  return (
    <div className={bare ? "" : "px-5 pt-2"}>
      <div className="text-[11px] uppercase tracking-wider text-white/40 font-body mb-2">Lock Screen</div>
      <div className="rounded-xl bg-white/5 border border-white/10 px-4 py-3.5">
        <div className="grid grid-cols-4 gap-2 mb-3">
          {bgPresets.map((p) => (
            <button key={p.id} onClick={() => setBg({ type: "preset", preset: p.id, url: "" })}
              className={cn("rounded-lg border-2 p-1 transition",
                !hasImage && (lb.preset || "default") === p.id ? "border-amber" : "border-white/10 hover:border-white/30")}>
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
            <button onClick={() => setBg({ type: "preset", preset: lb.preset || "default", url: "" })}
              className="rounded-lg bg-white/10 text-white/80 text-xs px-3 py-2 flex items-center gap-1.5">
              <Trash2 size={14} /> Remove
            </button>
          )}
        </div>
        {error && <p className="text-[11px] text-[#FF453A] font-body mt-2">image upload failed - try again</p>}
      </div>

      <div className="text-[11px] uppercase tracking-wider text-white/40 font-body mb-2 mt-4">Lock Screen Method</div>
      <div className="rounded-xl bg-white/5 border border-white/10 px-4 py-3">
        {METHODS.map(({ id, label, hint, Icon }) => (
          <button key={id} onClick={() => setLock({ type: id })} className="flex w-full items-center gap-3 py-1.5">
            <Icon size={18} className={lock.type === id ? "text-[#0A84FF]" : "text-white/50"} />
            <span className="flex-1 text-left">
              <span className="block text-sm">{label}</span>
              <span className="block text-[10px] text-white/35 font-body">
                {id === "none" ? `${defaultLabel} by default` : hint}
              </span>
            </span>
            {lock.type === id && <Check size={16} className="text-[#0A84FF]" />}
          </button>
        ))}
        <div className="flex items-center justify-between border-t border-white/10 mt-1 pt-2">
          {lock.type === "passcode" ? (
            <button onClick={() => { update({ passcode: "" }); onLock?.(); }} className="text-xs text-[#FF453A]">Reset Passcode</button>
          ) : lock.type === "pattern" ? (
            <button onClick={() => { update({ pattern: "" }); onLock?.(); }} className="text-xs text-[#FF453A]">Reset Pattern</button>
          ) : (
            <span />
          )}
          {needsSetup && <span className="text-[10px] text-[#FF9F0A] font-body uppercase tracking-wider">set on next lock</span>}
        </div>
      </div>
    </div>
  );
}