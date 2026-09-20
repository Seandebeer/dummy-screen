import React, { useState } from "react";
import { Bookmark, Save, Smartphone, X } from "lucide-react";
import { saveConfig } from "@/lib/savedConfigs";
import { getLinkedDeviceId, getDeviceName } from "@/lib/deviceLink";
import { cn } from "@/lib/utils";

// SaveTargetSheet - whenever a screen or UI marker layout is saved, choose
// where it goes: the Saved card on Home (favourites) or the device this
// screen is running as. Device saves live in that device's folder on Home.
export default function SaveTargetSheet({ title, defaultName, build, onClose }) {
  const [name, setName] = useState(defaultName || "");
  const [target, setTarget] = useState("fav");
  const linkedId = getLinkedDeviceId();

  const save = () => {
    const n = name.trim() || defaultName || "Untitled";
    const entry = build(n);
    if (target === "device" && linkedId) entry.device_id = linkedId;
    saveConfig(entry);
    onClose();
  };

  const Row = ({ icon, label, sub, selected, onClick }) => (
    <button onClick={onClick}
      className={cn("flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left transition",
        selected ? "bg-white/20" : "bg-white/[0.08] active:bg-white/15")}>
      <span className="shrink-0 text-white/80">{icon}</span>
      <span className="min-w-0 flex-1">
        <span className="block truncate text-[13.5px] font-medium">{label}</span>
        {sub && <span className="block truncate text-[10.5px] text-white/40">{sub}</span>}
      </span>
      {selected && <span className="h-2.5 w-2.5 shrink-0 rounded-full bg-white" />}
    </button>
  );

  return (
    <div className="absolute inset-0 z-[70] flex items-end bg-black/60" onClick={onClose}>
      <div onClick={(e) => e.stopPropagation()}
        className="w-full rounded-t-3xl bg-[#1c1c1e] px-4 pb-5 pt-3 text-white shadow-2xl">
        <div className="mx-auto mb-3 h-1 w-10 rounded-full bg-white/20" />
        <div className="mb-3 flex items-center justify-between">
          <span className="font-display text-[16px] font-semibold">{title}</span>
          <button onClick={onClose} aria-label="Close"
            className="rounded-full bg-white/10 p-1.5 text-white/70"><X size={14} /></button>
        </div>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Name"
          className="mb-3 w-full rounded-xl bg-white/10 px-3.5 py-2.5 text-[14px] outline-none placeholder:text-white/30" />
        <div className="space-y-1.5">
          <Row icon={<Bookmark size={16} />} label="Favourites" sub="Saved card on Home"
            selected={target === "fav"} onClick={() => setTarget("fav")} />
          {linkedId && (
            <Row icon={<Smartphone size={16} />} label={`Current device — ${getDeviceName()}`}
              sub="Lives in this device's folder"
              selected={target === "device"} onClick={() => setTarget("device")} />
          )}
        </div>
        <button onClick={save}
          className="mt-4 flex w-full items-center justify-center gap-2 rounded-xl bg-[#0A84FF] py-3 text-[15px] font-semibold transition active:opacity-80">
          <Save size={15} /> Save
        </button>
      </div>
    </div>
  );
}