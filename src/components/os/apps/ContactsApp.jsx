import React, { useState } from "react";
import { Search, Plus, Phone, MessageSquare } from "lucide-react";
import { mockContacts } from "@/lib/osData";
import { cn } from "@/lib/utils";

export default function ContactsApp({ onCall, onMessage }) {
  const [query, setQuery] = useState("");
  const [selected, setSelected] = useState(null);

  const filtered = mockContacts.filter((c) =>
    c.name.toLowerCase().includes(query.toLowerCase()) || c.number.includes(query)
  );

  if (selected) {
    return (
      <div className="h-full bg-black text-white flex flex-col">
        <div className="flex flex-col items-center py-8 border-b border-white/10">
          <div className="h-24 w-24 rounded-full flex items-center justify-center font-display text-3xl font-bold mb-3"
            style={{ background: selected.color, color: "#000" }}>{selected.initials}</div>
          <div className="font-display text-2xl font-semibold">{selected.name}</div>
          <div className="text-white/50 text-sm font-body">{selected.number}</div>
        </div>
        <div className="flex justify-center gap-8 py-6">
          <button onClick={() => onCall?.(selected)} className="flex flex-col items-center gap-1.5">
            <span className="h-14 w-14 rounded-full bg-[#34C759] flex items-center justify-center"><Phone size={22} className="text-black" /></span>
            <span className="text-xs text-[#34C759]">call</span>
          </button>
          <button onClick={() => onMessage?.(selected)} className="flex flex-col items-center gap-1.5">
            <span className="h-14 w-14 rounded-full bg-[#34C759] flex items-center justify-center"><MessageSquare size={22} className="text-black" /></span>
            <span className="text-xs text-[#34C759]">message</span>
          </button>
        </div>
        <div className="px-6 space-y-3 text-sm">
          <div className="flex justify-between border-b border-white/10 pb-2"><span className="text-white/40">mobile</span><span className="font-body">{selected.number}</span></div>
          <div className="flex justify-between border-b border-white/10 pb-2"><span className="text-white/40">notes</span><span className="text-white/70">Prop dept — primary</span></div>
        </div>
        <button onClick={() => setSelected(null)} className="mt-auto py-4 text-[#0A84FF] font-medium">Done</button>
      </div>
    );
  }

  return (
    <div className="h-full bg-black text-white flex flex-col">
      <div className="px-4 pt-2 pb-3">
        <h2 className="font-display text-2xl font-bold mb-3">Contacts</h2>
        <div className="flex items-center gap-2 rounded-xl bg-white/10 px-3 py-2">
          <Search size={16} className="text-white/40" />
          <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search" className="bg-transparent outline-none text-sm flex-1 placeholder:text-white/30" />
        </div>
      </div>
      <div className="flex-1 overflow-auto no-scrollbar px-4">
        <div className="space-y-1">
          {filtered.map((c) => (
            <button key={c.id} onClick={() => setSelected(c)}
              className="w-full flex items-center gap-3 py-2.5 border-b border-white/5 text-left">
              <span className="h-10 w-10 rounded-full flex items-center justify-center font-semibold text-sm shrink-0" style={{ background: c.color, color: "#000" }}>{c.initials}</span>
              <div className="min-w-0">
                <div className="font-medium truncate">{c.name}</div>
                <div className="text-xs text-white/40 font-body">{c.number}</div>
              </div>
            </button>
          ))}
          {filtered.length === 0 && <div className="text-center text-white/40 py-10 text-sm">No contacts</div>}
        </div>
      </div>
    </div>
  );
}