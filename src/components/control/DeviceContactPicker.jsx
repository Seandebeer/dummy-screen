import React, { useEffect, useState } from "react";
import { ChevronLeft, Loader2, Search, Smartphone, X } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { DIAL_CODES, makeDefaultContacts } from "@/lib/osData";
import { Image } from "@/components/ui/image";

// opens a prop device's own contact book - its OS defaults plus every
// newly added / customised contact it synced to the cloud - so the control
// deck can pick who to be on screen for calls, messages and video calls
export default function DeviceContactPicker({ onPick, onClose }) {
  const [step, setStep] = useState("device");
  const [devices, setDevices] = useState(null);
  const [device, setDevice] = useState(null);
  const [contacts, setContacts] = useState(null);
  const [query, setQuery] = useState("");

  useEffect(() => {
    base44.entities.Device.list("-updated_date", 100)
      .then((ds) => setDevices(ds.filter((d) => !d.kind || d.kind === "phone" || d.kind === "tablet")))
      .catch(() => setDevices([]));
  }, []);

  const openDevice = (d) => {
    setDevice(d);
    setStep("contact");
    setContacts(null);
    let cfg = {};
    try { cfg = JSON.parse(d.config || "{}") || {}; } catch {}
    const custom = Array.isArray(cfg.contacts) ? cfg.contacts : [];
    const defaults = makeDefaultContacts(DIAL_CODES, cfg.language || "en");
    const byId = new Map(defaults.map((c) => [c.id, c]));
    custom.forEach((c) => byId.set(c.id, c));
    setContacts([...byId.values()]);
  };

  const list = (contacts || []).filter((c) =>
    !query.trim()
    || (c.name || "").toLowerCase().includes(query.trim().toLowerCase())
    || (c.number || "").includes(query.trim()));

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4" onClick={onClose}>
      <div onClick={(e) => e.stopPropagation()}
        className="flex max-h-[80vh] w-full max-w-md flex-col overflow-hidden rounded-2xl border border-border bg-surface shadow-2xl">
        <div className="flex items-center gap-2 border-b border-border px-4 py-3">
          {step === "contact" && (
            <button onClick={() => { setStep("device"); setQuery(""); }} aria-label="Back"
              className="rounded-lg p-1 text-muted-foreground hover:text-foreground"><ChevronLeft size={16} /></button>
          )}
          <span className="flex-1 font-display text-sm font-semibold">
            {step === "device" ? "Pick a prop device" : `Contacts on ${device?.name || "device"}`}
          </span>
          <button onClick={onClose} aria-label="Close"
            className="rounded-lg p-1 text-muted-foreground hover:text-foreground"><X size={16} /></button>
        </div>

        {step === "device" && (
          <div className="flex-1 overflow-y-auto p-3">
            {devices === null ? (
              <div className="flex justify-center py-8 text-muted-foreground"><Loader2 size={18} className="animate-spin" /></div>
            ) : devices.length === 0 ? (
              <p className="py-6 text-center text-[11px] font-body text-muted-foreground">
                No devices yet - save one from the Home screen first.
              </p>
            ) : devices.map((d) => (
              <button key={d.id} onClick={() => openDevice(d)}
                className="mb-1.5 flex w-full items-center gap-3 rounded-lg border border-border bg-muted/30 px-3 py-2.5 text-left transition hover:bg-muted/60">
                <Smartphone size={15} className="shrink-0 text-muted-foreground" />
                <span className="min-w-0 flex-1">
                  <span className="block truncate text-[13px] font-body font-medium">{d.name}</span>
                  <span className="block text-[10px] font-body text-muted-foreground">
                    {d.config ? "Contact book synced" : "No synced layout yet - showing OS defaults"}
                  </span>
                </span>
              </button>
            ))}
          </div>
        )}

        {step === "contact" && (
          <>
            <div className="flex items-center gap-2 border-b border-border px-3 py-2">
              <Search size={13} className="text-muted-foreground" />
              <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search name or number…"
                className="flex-1 bg-transparent text-[12px] font-body outline-none placeholder:text-muted-foreground" />
            </div>
            <div className="flex-1 overflow-y-auto p-2">
              {contacts === null ? (
                <div className="flex justify-center py-8 text-muted-foreground"><Loader2 size={18} className="animate-spin" /></div>
              ) : list.length === 0 ? (
                <p className="py-6 text-center text-[11px] font-body text-muted-foreground">No matching contacts</p>
              ) : list.map((c) => (
                <button key={c.id}
                  onClick={() => onPick({ name: c.name || "", number: c.number || "", email: c.email || "", image: c.image || "" })}
                  className="mb-1 flex w-full items-center gap-3 rounded-lg px-2 py-2 text-left transition hover:bg-muted/50">
                  {c.image
                    ? <Image src={c.image} alt="" className="h-9 w-9 rounded-full" fittingType="fill" />
                    : <span className="flex h-9 w-9 items-center justify-center rounded-full font-display text-[12px] font-semibold text-white"
                        style={{ background: c.color || "#8A92A6" }}>{c.initials || (c.name || "?")[0]}</span>}
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-[13px] font-body">{c.name || "Unknown"}</span>
                    <span className="block truncate text-[10px] font-body text-muted-foreground">
                      {c.number || c.suffix || ""}{c.custom ? " · custom" : ""}
                    </span>
                  </span>
                </button>
              ))}
            </div>
          </>
        )}
      </div>
    </div>
  );
}