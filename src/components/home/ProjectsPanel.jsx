import React, { useState, useEffect, useCallback } from "react";
import { base44 } from "@/api/base44Client";
import { FolderKanban, Plus, Trash2, Loader2 } from "lucide-react";

export default function ProjectsPanel() {
  const [projects, setProjects] = useState(null);
  const [name, setName] = useState("");
  const [busy, setBusy] = useState(false);

  const refresh = useCallback(() => {
    base44.entities.Project.list("-created_date", 100)
      .then((d) => setProjects(d))
      .catch(() => setProjects([]));
  }, []);

  useEffect(() => {
    refresh();
    const unsub = base44.entities.Project.subscribe(() => refresh());
    return () => unsub();
  }, [refresh]);

  const add = async (e) => {
    e.preventDefault();
    if (!name.trim() || busy) return;
    setBusy(true);
    try {
      await base44.entities.Project.create({ name: name.trim() });
      setName("");
      refresh();
    } finally {
      setBusy(false);
    }
  };

  const remove = async (p) => {
    try {
      await base44.entities.Project.delete(p.id);
    } catch {} // already deleted elsewhere — just refresh
    refresh();
  };

  return (
    <div className="rounded-2xl border border-border bg-surface p-5">
      <div className="flex items-center gap-2.5 mb-4">
        <span className="h-9 w-9 rounded-lg bg-amber/15 text-amber flex items-center justify-center">
          <FolderKanban size={18} />
        </span>
        <div className="flex-1">
          <h3 className="font-display font-bold text-base leading-none">Projects</h3>
          <p className="text-[11px] text-muted-foreground font-body mt-1">{projects ? `${projects.length} active` : "loading…"}</p>
        </div>
      </div>

      <form onSubmit={add} className="flex gap-2 mb-4">
        <input
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="New project name"
          className="flex-1 rounded-lg bg-muted/40 border border-border px-3 py-2 text-sm font-body outline-none focus:border-amber/50"
        />
        <button type="submit" disabled={busy || !name.trim()}
          className="rounded-lg bg-amber text-background px-3 flex items-center gap-1 text-sm font-display font-semibold disabled:opacity-40">
          {busy ? <Loader2 size={15} className="animate-spin" /> : <Plus size={15} />}
        </button>
      </form>

      {projects === null ? (
        <div className="py-10 flex justify-center text-muted-foreground"><Loader2 className="animate-spin" size={20} /></div>
      ) : projects.length === 0 ? (
        <p className="py-8 text-center text-xs text-muted-foreground font-body">No projects yet — add one above.</p>
      ) : (
        <ul className="flex flex-col gap-1.5">
          {projects.map((p) => (
            <li key={p.id} className="group flex items-center gap-3 rounded-lg border border-border bg-muted/30 px-3 py-2.5">
              <span className="h-2 w-2 rounded-full bg-amber/70 shrink-0" />
              <span className="flex-1 text-sm font-body truncate">{p.name}</span>
              <button onClick={() => remove(p)} className="text-muted-foreground hover:text-alert transition opacity-60 group-hover:opacity-100">
                <Trash2 size={15} />
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}