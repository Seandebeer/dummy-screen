import React, { useState, useEffect, useCallback } from "react";
import { base44 } from "@/api/base44Client";
import { FolderKanban, Plus, Trash2, Loader2, Users, ChevronDown } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { cn } from "@/lib/utils";
import { applyOsConfig } from "@/lib/osConfigStore";
import { linkDevice } from "@/lib/deviceLink";
import ProjectTeam from "@/components/home/ProjectTeam";

export default function ProjectsPanel() {
  const [projects, setProjects] = useState(null);
  const [devices, setDevices] = useState([]);
  const [name, setName] = useState("");
  const [busy, setBusy] = useState(false);
  const [teamOpen, setTeamOpen] = useState(null);
  const [selected, setSelected] = useState(null);
  const [user, setUser] = useState(null);
  const navigate = useNavigate();

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
    base44.entities.Device.list("-created_date", 200)
      .then((d) => setDevices(d))
      .catch(() => {});
  }, []);

  useEffect(() => {
    refresh();
    const unsub = base44.entities.Project.subscribe(() => refresh());
    const unsubDevices = base44.entities.Device.subscribe(() => refresh());
    return () => { unsub(); unsubDevices(); };
  }, [refresh]);

  const projectDevices = (p) => devices.filter((d) => d.project_id === p.id);

  // only projects this user has access to - their own or shared with them
  const visibleProjects = (projects || []).filter((p) => myAccess(p) === "owner" || myAccess(p) === "editor" || myAccess(p) === "viewer");

  // tap a device to bring up its OS - loads its saved layout if it has one
  const openDevice = (d) => {
    if (d.config) {
      try {
        applyOsConfig(JSON.parse(d.config));
        linkDevice(d.id, d.name);
      } catch {}
    }
    navigate("/os");
  };

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
                <button onClick={() => setSelected(selected === p.id ? null : p.id)}
                  className="flex min-w-0 flex-1 items-center gap-3 text-left">
                  <span className="h-2 w-2 rounded-full bg-amber/70 shrink-0" />
                  <span className="flex-1 text-sm font-body truncate">{p.name}</span>
                  <span className="shrink-0 text-[9px] uppercase tracking-wider text-muted-foreground font-body">
                    {projectDevices(p).length} {projectDevices(p).length === 1 ? "device" : "devices"}
                  </span>
                  <ChevronDown size={13} className={cn("shrink-0 text-muted-foreground transition-transform", selected === p.id && "rotate-180")} />
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
              {selected === p.id && (
                <div className="mt-1.5 pl-5 flex flex-col gap-1">
                  {projectDevices(p).length === 0 ? (
                    <span className="text-[10px] text-muted-foreground/70 font-body">No devices linked - assign devices to this project in Devices</span>
                  ) : projectDevices(p).map((d) => (
                    <button key={d.id} onClick={() => openDevice(d)} disabled={myAccess(p) === "viewer"}
                      title={myAccess(p) === "viewer" ? "View only - editing access required" : "Open this device's OS"}
                      className="w-full flex items-center gap-2 text-xs font-body text-left rounded-md py-0.5 px-1 -mx-1 hover:bg-muted/60 transition cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed">
                      <span className={cn("h-1.5 w-1.5 rounded-full shrink-0",
                        d.status === "online" ? "bg-signal led-pulse" : "bg-muted-foreground/40")} />
                      <span className="truncate text-foreground/80">{d.name}</span>
                      <span className="text-[9px] uppercase tracking-wider text-muted-foreground">{d.kind}</span>
                    </button>
                  ))}
                </div>
              )}
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