import React, { useState, useEffect } from "react";
import { Loader2, Save, X } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { saveConfig } from "@/lib/savedConfigs";
import { categoryOf, mergePageIntoConfig } from "@/lib/savedPages";
import { cn } from "@/lib/utils";

// SaveSheet - save an edited page to the general Saved card on Home, or
// straight into a character's device (pages saved to a device load whenever
// that device's layout is loaded).

export default function SaveSheet({ app, defaultName, data, onClose }) {
  const [name, setName] = useState(defaultName);
  const [devices, setDevices] = useState(null);
  const [target, setTarget] = useState("general");
  const [newName, setNewName] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    base44.entities.Device.list("-created_date", 50)
      .then(setDevices)
      .catch(() => setDevices([]));
  }, []);

  const save = async () => {
    const n = (name || "").trim();
    if (!n || busy) return;
    setBusy(true);
    try {
      if (target === "general") {
        saveConfig({ kind: "page", app, category: categoryOf(app), name: n, data });
      } else if (target === "new") {
        if (!newName.trim()) { setBusy(false); return; }
        await base44.entities.Device.create({
          name: newName.trim(), kind: "phone", status: "offline",
          config: JSON.stringify(mergePageIntoConfig({}, app, data)),
        });
      } else {
        const d = (devices || []).find((x) => x.id === target);
        let cfg = {};
        try { cfg = d?.config ? JSON.parse(d.config) : {}; } catch {}
        await base44.entities.Device.update(target, {
          config: JSON.stringify(mergePageIntoConfig(cfg, app, data)),
        });
      }
      onClose();
    } catch {
      setBusy(false);
    }
  };

  const Row = ({ label, sub, selected, onClick }) => (
    <button onClick={onClick}
      className={cn("flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left transition",
        selected ? "bg-[#0A84FF]/25" : "bg-white/[0.06] active:bg-white/10")}>
      <span className="min-w-0 flex-1">
        <span className="block truncate text-[13.5px] font-medium">{label}</span>
        {sub && <span className="block truncate text-[10.5px] text-white/40">{sub}</span>}
      </span>
      {selected && <span className="h-2.5 w-2.5 shrink-0 rounded-full bg-[#0A84FF]" />}
    </button>
  );

  return (
    <div className="absolute inset-0 z-40 flex items-end bg-black/60" onClick={() => !busy && onClose()}>
      <div onClick={(e) => e.stopPropagation()}
        className="w-full rounded-t-3xl bg-[#1c1c1e] px-4 pb-5 pt-3 text-white shadow-2xl">
        <div className="mx-auto mb-3 h-1 w-10 rounded-full bg-white/20" />
        <div className="mb-3 flex items-center justify-between">
          <span className="font-display text-[16px] font-semibold">Save page</span>
          <button onClick={onClose} aria-label="Close"
            className="rounded-full bg-white/10 p-1.5 text-white/70"><X size={14} /></button>
        </div>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Page name"
          className="w-full rounded-xl bg-white/10 px-3.5 py-2.5 text-[14px] outline-none placeholder:text-white/30" />
        <div className="mt-3 space-y-1.5">
          <div className="px-1 pb-1 text-[10px] font-semibold uppercase tracking-widest text-white/35">Save to</div>
          <Row label="General — Saved card" sub="Home · saved items" selected={target === "general"} onClick={() => setTarget("general")} />
          {devices === null ? (
            <div className="flex justify-center py-2 text-white/40"><Loader2 size={16} className="animate-spin" /></div>
          ) : devices.map((d) => (
            <Row key={d.id} label={d.name} sub="Character's device · loads with the device"
              selected={target === d.id} onClick={() => setTarget(d.id)} />
          ))}
          <Row label="New device…" sub="Create a character's device with this page"
            selected={target === "new"} onClick={() => setTarget("new")} />
          {target === "new" && (
            <input autoFocus value={newName} onChange={(e) => setNewName(e.target.value)}
              placeholder="Device name (e.g. Maya's phone)"
              className="w-full rounded-xl bg-white/10 px-3.5 py-2.5 text-[13px] outline-none placeholder:text-white/30" />
          )}
        </div>
        <button onClick={save} disabled={!name.trim() || busy}
          className="mt-4 flex w-full items-center justify-center gap-2 rounded-xl bg-[#0A84FF] py-3 text-[15px] font-semibold transition active:opacity-80 disabled:opacity-40">
          {busy ? <Loader2 size={16} className="animate-spin" /> : <Save size={15} />}
          {busy ? "Saving…" : "Save"}
        </button>
      </div>
    </div>
  );
}