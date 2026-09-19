import React, { useState } from "react";
import { Search, Plus, Phone, MessageSquare, Mail, Trash2 } from "lucide-react";
import { cn } from "@/lib/utils";
import { uiFor } from "@/lib/osLanguages";

const inputCls = "w-full rounded-xl bg-white/10 px-4 py-2.5 text-sm outline-none border border-white/10 focus:border-[#0A84FF] placeholder:text-white/30";

export default function ContactsApp({ contacts = [], dialCode = "026", language = "en", update, onCall, onMessage, onEmail }) {
  const t = uiFor(language);
  const [query, setQuery] = useState("");
  const [selectedId, setSelectedId] = useState(null);
  const [editing, setEditing] = useState(null);

  const filtered = contacts.filter((c) =>
    (c.name || "").toLowerCase().includes(query.toLowerCase()) || (c.number || "").includes(query)
  );
  const selected = contacts.find((c) => c.id === selectedId);

  const startAdd = () => setEditing({ name: "", number: `${dialCode} `, email: "" });
  const startEdit = (c) => setEditing({ ...c });

  const save = () => {
    if (!editing.name.trim()) return;
    const record = {
      ...editing,
      name: editing.name.trim(),
      custom: true,
      initials: editing.name.trim().split(/\s+/).map((w) => w[0]).join("").slice(0, 2).toUpperCase(),
      color: editing.color || "#8A92A6",
    };
    update((c) => {
      const list = [...(c.contacts || [])];
      const i = list.findIndex((x) => x.id === editing.id);
      if (i !== -1) list[i] = record; else list.push({ ...record, id: `c${Date.now()}` });
      return { contacts: list };
    });
    if (editing.id) setSelectedId(editing.id);
    setEditing(null);
  };

  const remove = (id) => {
    update((c) => ({ contacts: (c.contacts || []).filter((x) => x.id !== id) }));
    setEditing(null);
    setSelectedId(null);
  };

  if (editing) {
    return (
      <div className="h-full bg-black text-white flex flex-col">
        <div className="flex items-center justify-between px-4 py-2 border-b border-white/10">
          <button onClick={() => setEditing(null)} className="text-sm text-[#0A84FF]">{t.cancel}</button>
          <span className="text-sm font-medium">{editing.id ? t.editContact : t.newContact}</span>
          <button onClick={save} disabled={!editing.name.trim()} className="text-sm font-semibold text-[#0A84FF] disabled:text-white/25">{t.save}</button>
        </div>
        <div className="flex-1 overflow-auto no-scrollbar px-5 py-5 space-y-4">
          <div className="flex flex-col items-center pb-2">
            <div className="h-20 w-20 rounded-full flex items-center justify-center font-display text-2xl font-bold mb-3"
              style={{ background: editing.color || "#8A92A6", color: "#000" }}>
              {(editing.name || "?").trim().split(/\s+/).map((w) => w[0]).join("").slice(0, 2).toUpperCase()}
            </div>
          </div>
          <div>
            <div className="text-[11px] uppercase tracking-wider text-white/40 font-body mb-1.5">Name</div>
            <input value={editing.name} onChange={(e) => setEditing({ ...editing, name: e.target.value })} placeholder="Full name" className={inputCls} />
          </div>
          <div>
            <div className="text-[11px] uppercase tracking-wider text-white/40 font-body mb-1.5">Mobile</div>
            <input value={editing.number} onChange={(e) => setEditing({ ...editing, number: e.target.value })} placeholder={`${dialCode} …`} className={cn(inputCls, "font-body")} />
          </div>
          <div>
            <div className="text-[11px] uppercase tracking-wider text-white/40 font-body mb-1.5">Email</div>
            <input value={editing.email || ""} onChange={(e) => setEditing({ ...editing, email: e.target.value })} placeholder="name@setmail.co" className={inputCls} />
          </div>
          {editing.id && (
            <button onClick={() => remove(editing.id)}
              className="w-full rounded-xl bg-[#FF453A]/15 text-[#FF453A] text-sm font-semibold py-3 flex items-center justify-center gap-2">
              <Trash2 size={16} /> Delete Contact
            </button>
          )}
        </div>
      </div>
    );
  }

  if (selected) {
    return (
      <div className="h-full bg-black text-white flex flex-col">
        <div className="flex items-center justify-between px-4 py-2 border-b border-white/10">
          <button onClick={() => setSelectedId(null)} className="flex items-center gap-1 text-sm text-[#0A84FF]">{t.contacts}</button>
          <span className="text-sm font-medium truncate max-w-[45%]">{selected.name}</span>
          <button onClick={() => startEdit(selected)} className="text-sm text-[#0A84FF]">{t.edit}</button>
        </div>
        <div className="flex flex-col items-center py-8 border-b border-white/10">
          <div className="h-24 w-24 rounded-full flex items-center justify-center font-display text-3xl font-bold mb-3"
            style={{ background: selected.color, color: "#000" }}>{selected.initials}</div>
          <div className="font-display text-2xl font-semibold">{selected.name}</div>
          <div className="text-white/50 text-sm font-body">{selected.number}</div>
        </div>
        <div className="flex justify-center gap-6 py-5">
          <button onClick={() => onCall?.(selected)} className="flex flex-col items-center gap-1.5">
            <span className="h-14 w-14 rounded-full bg-[#34C759] flex items-center justify-center"><Phone size={22} className="text-black" /></span>
            <span className="text-xs text-[#34C759]">{t.call}</span>
          </button>
          <button onClick={() => onMessage?.(selected)} className="flex flex-col items-center gap-1.5">
            <span className="h-14 w-14 rounded-full bg-[#34C759] flex items-center justify-center"><MessageSquare size={22} className="text-black" /></span>
            <span className="text-xs text-[#34C759]">{t.message}</span>
          </button>
          <button onClick={() => onEmail?.(selected)} disabled={!selected.email}
            className="flex flex-col items-center gap-1.5 disabled:opacity-35">
            <span className="h-14 w-14 rounded-full bg-[#0A84FF] flex items-center justify-center"><Mail size={22} className="text-black" /></span>
            <span className="text-xs text-[#0A84FF]">{t.email}</span>
          </button>
        </div>
        <div className="px-6 space-y-3 text-sm flex-1 overflow-auto no-scrollbar">
          <div className="flex justify-between border-b border-white/10 pb-2"><span className="text-white/40">mobile</span><span className="font-body">{selected.number}</span></div>
          {selected.email && <div className="flex justify-between border-b border-white/10 pb-2"><span className="text-white/40">email</span><span className="font-body">{selected.email}</span></div>}
          <div className="flex justify-between border-b border-white/10 pb-2"><span className="text-white/40">notes</span><span className="text-white/70">Prop dept - primary</span></div>
        </div>
        <button onClick={() => setSelectedId(null)} className="py-4 text-[#0A84FF] font-medium border-t border-white/10">{t.done}</button>
      </div>
    );
  }

  return (
    <div className="h-full bg-black text-white flex flex-col">
      <div className="px-4 pt-2 pb-3">
        <div className="flex items-center justify-between mb-3">
          <h2 className="font-display text-2xl font-bold">{t.contacts}</h2>
          <button onClick={startAdd} className="flex items-center gap-1 rounded-full bg-[#0A84FF] px-3 py-1.5 text-xs font-semibold">
            <Plus size={14} /> {t.add}
          </button>
        </div>
        <div className="flex items-center gap-2 rounded-xl bg-white/10 px-3 py-2">
          <Search size={16} className="text-white/40" />
          <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder={t.search} className="bg-transparent outline-none text-sm flex-1 placeholder:text-white/30" />
        </div>
      </div>
      <div className="flex-1 overflow-auto no-scrollbar px-4">
        <div className="space-y-1">
          {filtered.map((c) => (
            <button key={c.id} onClick={() => setSelectedId(c.id)}
              className="w-full flex items-center gap-3 py-2.5 border-b border-white/5 text-left">
              <span className="h-10 w-10 rounded-full flex items-center justify-center font-semibold text-sm shrink-0" style={{ background: c.color, color: "#000" }}>{c.initials}</span>
              <div className="min-w-0">
                <div className="font-medium truncate">{c.name}</div>
                <div className="text-xs text-white/40 font-body">{c.number}</div>
              </div>
            </button>
          ))}
          {filtered.length === 0 && <div className="text-center text-white/40 py-10 text-sm">{t.noContacts}</div>}
        </div>
      </div>
    </div>
  );
}