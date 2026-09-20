import React, { useState, useEffect, useCallback } from "react";
import { base44 } from "@/api/base44Client";
import { FolderKanban, Plus, Trash2, Loader2, Users } from "lucide-react";
import { cn } from "@/lib/utils";
import ProjectTeam from "@/components/home/ProjectTeam";

export default function ProjectsPanel({ selected, onSelect }) {
  const [projects, setProjects] = useState(null);
  const [name, setName] = useState("");
  const [busy, setBusy] = useState(false);
  const [teamOpen, setTeamOpen] = useState(null);
  const [user, setUser] = useState(null);

  useEffect(() => {
    base44.auth.me().then(setUser).catch(() => {});
  }, []);

  // this user's role on a project: owner (account holder), editor or viewer.
  // access is membership-based - being an app admin doesn't list projects you're not on
  const myAccess = (p) => {
    if (!user) return "loading";
    const me = (user.email || "").toLowerCase();
    if (p.created_by_id === user.id) return "owner";
    if ((p.editors || []).includes(me)) return "editor";
    if ((p.viewers || []).includes(me)) return "viewer";
    return "none";
  };

  // the project owner or an app admin can still manage any project
  const canManage = (p) => Boolean(user) && (user.role === "admin" || myAccess(p) === "owner");

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

  // only projects this user has access to - their own or shared with them
  const visibleProjects = (projects || []).filter((p) => myAccess(p) === "owner" || myAccess(p) === "editor" || myAccess(p) === "viewer");

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
    } catch {} // already deleted elsewhere - just refresh
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
          <p className="text-[11px] text-muted-foreground font-body mt-1">{projects ? `${visibleProjects.length} active` : "loading…"}</p>
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

      {projects === null || !user ? (
        <div className="py-10 flex justify-center text-muted-foreground"><Loader2 className="animate-spin" size={20} /></div>
      ) : visibleProjects.length === 0 ? (
        <p className="py-8 text-center text-xs text-muted-foreground font-body">No projects you have access to - add one above or ask to join a team.</p>
      ) : (
        <ul className="flex flex-col gap-1.5">
          {visibleProjects.map((p) => (
            <li key={p.id} className="group rounded-lg border border-border bg-muted/30 px-3 py-2.5">
              <div className="flex items-center gap-3">
                <button onClick={() => onSelect(selected === p.id ? null : p)}
                  className={cn("flex flex-1 min-w-0 items-center gap-3 rounded text-left transition",
                    selected === p.id ? "bg-amber/10 px-1.5 py-0.5 -mx-1.5" : "hover:bg-muted/40 px-1.5 py-0.5 -mx-1.5")}>
                  <span className={cn("h-2 w-2 rounded-full shrink-0", selected === p.id ? "bg-amber" : "bg-amber/70")} />
                  <span className="flex-1 text-sm font-body truncate">{p.name}</span>
                </button>
                {(myAccess(p) === "editor" || myAccess(p) === "viewer") && (
                  <span className={cn("shrink-0 rounded-full px-2 py-0.5 text-[9px] font-body uppercase tracking-wider",
                    myAccess(p) === "editor" ? "bg-signal/15 text-signal" : "bg-muted text-muted-foreground")}>
                    {myAccess(p) === "editor" ? "Editor" : "View only"}
                  </span>
                )}
                {canManage(p) && (
                  <button onClick={() => setTeamOpen(teamOpen === p.id ? null : p.id)} title="Manage team"
                    className="text-muted-foreground hover:text-foreground transition opacity-60 group-hover:opacity-100">
                    <Users size={15} />
                  </button>
                )}
                {canManage(p) && (
                  <button onClick={() => remove(p)} className="text-muted-foreground hover:text-alert transition opacity-60 group-hover:opacity-100">
                    <Trash2 size={15} />
                  </button>
                )}
              </div>
              {teamOpen === p.id && (
                <div className="mt-2 pt-2 border-t border-border/60">
                  <ProjectTeam project={p} user={user} onChange={refresh} />
                </div>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}