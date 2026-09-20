import React, { useRef, useState } from "react";
import { Pencil, Check, Plus, X, Save } from "lucide-react";
import { Image } from "@/components/ui/image";
import { base44 } from "@/api/base44Client";
import SaveSheet from "../SaveSheet";
import { cn } from "@/lib/utils";

// compact count formatting: 1200 -> 1.2K, 4500000 -> 4.5M
export const fmtNum = (n) => {
  const v = Number(n) || 0;
  if (v >= 1e6) return `${(v / 1e6).toFixed(v >= 1e7 ? 0 : 1).replace(/\.0$/, "")}M`;
  if (v >= 1e3) return `${(v / 1e3).toFixed(v >= 1e4 ? 0 : 1).replace(/\.0$/, "")}K`;
  return v.toLocaleString();
};

// coloured initials avatar - no external images needed on set
export function Avatar({ name = "?", hue = "#8a8a8e", size = 36, className }) {
  const initials = String(name).trim().split(/\s+/).map((w) => w[0]).slice(0, 2).join("").toUpperCase() || "?";
  return (
    <span
      className={cn("flex shrink-0 select-none items-center justify-center rounded-full font-semibold text-white", className)}
      style={{ width: size, height: size, fontSize: Math.max(10, size * 0.38), background: `linear-gradient(145deg, ${hue}, ${hue}bb)` }}
    >
      {initials}
    </span>
  );
}

// editable value: plain text when viewing, input when the app is in edit mode
export function Editable({ editing, value, onChange, className, type = "text", placeholder, inputClass }) {
  if (!editing) {
    return <span className={className}>{type === "number" ? fmtNum(value) : value}</span>;
  }
  return (
    <input
      value={value == null ? "" : value}
      placeholder={placeholder}
      onChange={(e) => onChange(type === "number" ? (parseInt(e.target.value.replace(/\D/g, ""), 10) || 0) : e.target.value)}
      className={cn("w-full rounded border border-dashed border-black/25 bg-black/5 px-1 outline-none", className, inputClass)}
    />
  );
}

// pencil / check toggle shared by all four social apps
export function EditToggle({ editing, onToggle, className }) {
  return (
    <button
      onClick={onToggle}
      title={editing ? "Done editing" : "Edit this app"}
      className={cn(
        "flex h-8 w-8 shrink-0 items-center justify-center rounded-full transition",
        editing ? "bg-[#FF9F0A] text-black" : "bg-black/10 text-current hover:bg-black/20",
        className
      )}
    >
      {editing ? <Check size={16} /> : <Pencil size={14} />}
    </button>
  );
}

// save toggle shared by all editable apps - opens the save sheet so the page
// can go to the general Saved card or into a character's device
export function SaveToggle({ app, defaultName, data, className }) {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button onClick={() => setOpen(true)} title="Save"
        className={cn("flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-black/10 transition hover:bg-black/20", className)}>
        <Save size={14} />
      </button>
      {open && <SaveSheet app={app} defaultName={defaultName} data={data} onClose={() => setOpen(false)} />}
    </>
  );
}

// upload button: picks a file, uploads it and hands back the URL + file type
export function UploadButton({ onFile, accept = "image/*", label = "Upload", className }) {
  const ref = useRef(null);
  const [busy, setBusy] = useState(false);
  const pick = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setBusy(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
      onFile(file_url, file.type);
    } catch {}
    setBusy(false);
  };
  return (
    <>
      <input ref={ref} type="file" accept={accept} className="hidden" onChange={pick} />
      <button onClick={(e) => { e.stopPropagation(); ref.current?.click(); }} disabled={busy}
        className={cn("rounded-full bg-black/60 px-2.5 py-1 text-[10px] font-semibold text-white backdrop-blur disabled:opacity-60", className)}>
        {busy ? "Uploading…" : label}
      </button>
    </>
  );
}

// content photo with edit-mode controls (swap / upload / delete / add)
export function Photo({ src, alt = "", className, editing, onSwap, onUpload, onDelete, onAdd, addLabel }) {
  if (!src) {
    if (!onAdd) return null;
    return (
      <button onClick={(e) => { e.stopPropagation(); onAdd(); }} className={cn("flex items-center justify-center gap-1.5 bg-black/5 text-[12px] font-medium text-black/40", className)}>
        <Plus size={14} /> {addLabel || "Add photo"}
      </button>
    );
  }
  return (
    <span className="relative block">
      <Image src={src} alt={alt} className={className} />
      {editing && (
        <span className="absolute right-2 top-2 flex gap-1.5">
          {onSwap && (
            <button onClick={(e) => { e.stopPropagation(); onSwap(); }}
              className="rounded-full bg-black/60 px-2.5 py-1 text-[10px] font-semibold text-white backdrop-blur">
              Swap
            </button>
          )}
          {onUpload && <UploadButton label="Upload" onFile={(url) => onUpload(url)} />}
          {onDelete && (
            <button onClick={(e) => { e.stopPropagation(); onDelete(); }} aria-label="Remove photo"
              className="flex h-6 w-6 items-center justify-center rounded-full bg-black/60 text-white">
              <X size={12} />
            </button>
          )}
        </span>
      )}
    </span>
  );
}