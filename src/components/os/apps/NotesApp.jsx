import React, { useState } from "react";
import { ChevronLeft, Plus, Trash2 } from "lucide-react";
import { scheduleDeviceSync } from "@/lib/cloudSync";

const KEY = "takeover-os-notes";

const loadNotes = () => {
  try {
    const notes = JSON.parse(localStorage.getItem(KEY));
    return Array.isArray(notes) ? notes : [];
  } catch {
    return [];
  }
};
const saveNotes = (notes) => {
  try { localStorage.setItem(KEY, JSON.stringify(notes)); } catch {}
};

export default function NotesApp() {
  const [notes, setNotes] = useState(loadNotes);
  const [activeId, setActiveId] = useState(null);
  const active = notes.find((n) => n.id === activeId) || null;

  const persist = (next) => { setNotes(next); saveNotes(next); scheduleDeviceSync(); };
  const newNote = () => {
    const note = { id: `n-${Date.now()}`, body: "", updated: Date.now() };
    persist([note, ...notes]);
    setActiveId(note.id);
  };
  const edit = (body) =>
    persist(notes.map((n) => (n.id === activeId ? { ...n, body, updated: Date.now() } : n)));
  const remove = () => {
    persist(notes.filter((n) => n.id !== activeId));
    setActiveId(null);
  };

  const title = (body) => (body || "").split("\n")[0].trim() || "New note";

  if (active) {
    return (
      <div className="h-full flex flex-col bg-background text-foreground">
        <div className="flex items-center justify-between px-3 py-2 border-b border-border">
          <button onClick={() => setActiveId(null)} className="flex items-center gap-1 text-amber text-sm font-body">
            <ChevronLeft size={16} /> Notes
          </button>
          <div className="flex items-center gap-3">
            <button onClick={newNote} title="New note"><Plus size={18} /></button>
            <button onClick={remove} title="Delete note" className="text-muted-foreground hover:text-alert"><Trash2 size={16} /></button>
          </div>
        </div>
        <textarea value={active.body} onChange={(e) => edit(e.target.value)} autoFocus placeholder="Start typing…"
          className="flex-1 w-full resize-none bg-transparent p-4 text-sm font-body leading-relaxed outline-none" />
        <div className="px-4 pb-2 text-[10px] text-muted-foreground font-body">
          Edited {new Date(active.updated).toLocaleString([], { hour: "numeric", minute: "2-digit", month: "short", day: "numeric" })}
        </div>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col bg-background text-foreground">
      <div className="flex items-center justify-between px-4 pt-4 pb-2">
        <div className="font-display font-semibold text-lg">Notes</div>
        <button onClick={newNote} title="New note" className="text-amber"><Plus size={20} /></button>
      </div>
      <div className="flex-1 overflow-y-auto no-scrollbar px-3 pb-3 flex flex-col gap-2">
        {notes.map((n) => (
          <button key={n.id} onClick={() => setActiveId(n.id)}
            className="text-left rounded-2xl border border-border bg-muted px-4 py-3">
            <div className="text-sm font-body font-medium truncate">{title(n.body)}</div>
            <div className="text-[11px] text-muted-foreground font-body mt-0.5 truncate">
              {new Date(n.updated).toLocaleDateString([], { month: "short", day: "numeric" })}
              {n.body.trim() ? " · " + n.body.split("\n").slice(1).join(" ").trim().slice(0, 40) : ""}
            </div>
          </button>
        ))}
        {!notes.length && (
          <div className="flex-1 flex items-center justify-center text-xs text-muted-foreground font-body">No notes yet</div>
        )}
      </div>
    </div>
  );
}