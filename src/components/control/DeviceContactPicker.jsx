import React, { useMemo, useState } from "react";
import { Search, X } from "lucide-react";
import { DIAL_CODES, makeDefaultContacts } from "@/lib/osData";
import { readCurrentOsConfig } from "@/lib/osConfigStore";
import { Image } from "@/components/ui/image";

// the control deck shares the logged-in user's profile, so the same contact
// book the OS uses is right here - defaults plus every newly added /
// customised contact. One tap picks who to be on screen.
export default function DeviceContactPicker({ onPick, onClose }) {
  const [query, setQuery] = useState("");

  const contacts = useMemo(() => {
    const cfg = readCurrentOsConfig() || {};
    const custom = (Array.isArray(cfg.contacts) ? cfg.contacts : []).filter((c) => c.custom);
    const byId = new Map(makeDefaultContacts(DIAL_CODES, cfg.language || "en").map((c) => [c.id, c]));
    custom.forEach((c) => byId.set(c.id, c));
    return [...byId.values()];
  }, []);

  const list = contacts.filter((c) =>
    !query.trim()
    || (c.name || "").toLowerCase().includes(query.trim().toLowerCase())
    || (c.number || "").includes(query.trim()));

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4" onClick={onClose}>
      <div onClick={(e) => e.stopPropagation()}
        className="flex max-h-[80vh] w-full max-w-md flex-col overflow-hidden rounded-2xl border border-border bg-surface shadow-2xl">
        <div className="flex items-center gap-2 border-b border-border px-4 py-3">
          <span className="flex-1 font-display text-sm font-semibold">Contacts</span>
          <button onClick={onClose} aria-label="Close"
            className="rounded-lg p-1 text-muted-foreground hover:text-foreground"><X size={16} /></button>
        </div>

        <div className="flex items-center gap-2 border-b border-border px-3 py-2">
          <Search size={13} className="text-muted-foreground" />
          <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search name or number…"
            className="flex-1 bg-transparent text-[12px] font-body outline-none placeholder:text-muted-foreground" />
        </div>
        <div className="flex-1 overflow-y-auto p-2">
          {list.length === 0 ? (
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
      </div>
    </div>
  );
}