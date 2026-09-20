import React, { useEffect, useState } from "react";
import { Eye, KeyRound, Loader2, Pencil } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { myAccess } from "@/lib/projectAccess";
import { cn } from "@/lib/utils";

const ROLE = {
  owner: {
    label: "Owner",
    Icon: KeyRound,
    badge: "bg-amber/15 text-amber",
    blurb: "Full control - manage the team, edit and delete this project.",
  },
  editor: {
    label: "Editor",
    Icon: Pencil,
    badge: "bg-signal/15 text-signal",
    blurb: "Open and edit this project's devices and layouts.",
  },
  viewer: {
    label: "Viewer",
    Icon: Eye,
    badge: "bg-muted text-muted-foreground",
    blurb: "View only - devices can't be opened for editing.",
  },
  none: {
    label: "No access",
    Icon: Eye,
    badge: "bg-muted text-muted-foreground",
    blurb: "You can't open this project.",
  },
};

// team member overview: every project this member can access and the exact
// editing permission they hold on each one
export default function MyAccess() {
  const [user, setUser] = useState(null);
  const [projects, setProjects] = useState(null);

  useEffect(() => {
    base44.auth.me().then(setUser).catch(() => setUser(false));
    base44.entities.Project.list("-created_date", 200)
      .then(setProjects)
      .catch(() => setProjects([]));
  }, []);

  if (projects === null || user === null) {
    return (
      <div className="h-dvh flex items-center justify-center text-muted-foreground">
        <Loader2 className="animate-spin" size={22} />
      </div>
    );
  }

  const entries = projects.map((p) => ({ project: p, access: myAccess(p, user) }));
  const count = (role) => entries.filter((e) => e.access === role).length;

  return (
    <div className="max-w-2xl mx-auto px-6 py-10">
      <div className="flex items-center gap-3">
        <span className="h-10 w-10 rounded-xl bg-amber/15 text-amber flex items-center justify-center">
          <KeyRound size={20} />
        </span>
        <div>
          <h1 className="font-display font-bold text-xl leading-none">My Access</h1>
          <p className="text-[11px] text-muted-foreground font-body mt-1">
            {entries.length} project{entries.length === 1 ? "" : "s"} you can access
            {count("owner") ? ` · ${count("owner")} owned` : ""}
            {count("editor") ? ` · ${count("editor")} editing` : ""}
            {count("viewer") ? ` · ${count("viewer")} viewing` : ""}
          </p>
        </div>
      </div>

      {entries.length === 0 ? (
        <p className="mt-16 text-center text-xs text-muted-foreground font-body">
          No projects shared with you yet - ask an account holder to add you to their team.
        </p>
      ) : (
        <ul className="mt-6 flex flex-col gap-2">
          {entries.map(({ project, access }) => {
            const role = ROLE[access] || ROLE.none;
            return (
              <li key={project.id} className="rounded-2xl border border-border bg-surface px-4 py-3.5">
                <div className="flex items-center gap-3">
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-body font-semibold truncate">{project.name}</div>
                    <div className="text-[10px] text-muted-foreground font-body truncate">
                      Owner: {project.created_by || "unknown"}
                    </div>
                  </div>
                  <span className={cn("shrink-0 flex items-center gap-1 rounded-full px-2.5 py-1 text-[10px] font-body uppercase tracking-wider", role.badge)}>
                    <role.Icon size={11} /> {role.label}
                  </span>
                </div>
                <p className="mt-2 text-[11px] text-muted-foreground font-body">{role.blurb}</p>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}