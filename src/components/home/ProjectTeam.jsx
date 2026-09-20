import React, { useState } from "react";
import { Eye, Loader2, Pencil, Plus, Trash2 } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { cn } from "@/lib/utils";

const MAX_TEAM = 5;

// Per-project team management for the account holder (project owner or app
// admin). Members need their own account - an invite is sent for any email
// that doesn't have one yet. Editing vs viewing is set per member, per project.
export default function ProjectTeam({ project, user, onChange }) {
  const editors = (project.editors || []).map((e) => e.toLowerCase());
  const viewers = (project.viewers || []).map((e) => e.toLowerCase());
  const members = [
    ...editors.map((email) => ({ email, perm: "editor" })),
    ...viewers.map((email) => ({ email, perm: "viewer" })),
  ];
  const ownerEmail = (project.created_by || "").toLowerCase();

  const [email, setEmail] = useState("");
  const [perm, setPerm] = useState("editor");
  const [sendInvite, setSendInvite] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  const save = async (nextEditors, nextViewers) => {
    await base44.entities.Project.update(project.id, { editors: nextEditors, viewers: nextViewers });
    onChange();
  };

  const addMember = async () => {
    const e = email.trim().toLowerCase();
    if (!e || busy) return;
    if (members.length >= MAX_TEAM) { setError(`Team is full - max ${MAX_TEAM} members`); return; }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e)) { setError("Enter a valid email address"); return; }
    if (e === ownerEmail) { setError("You already own this project"); return; }
    if (members.some((m) => m.email === e)) { setError("Already on this team"); return; }
    setBusy(true);
    setError("");
    try {
      // invite gives them their own account; if they already have one this is a no-op
      if (sendInvite) { try { await base44.users.inviteUser(e, "user"); } catch {} }
      await save(
        perm === "editor" ? [...editors, e] : editors,
        perm === "viewer" ? [...viewers, e] : viewers
      );
      setEmail("");
    } catch {
      setError("Could not add member - try again");
    } finally {
      setBusy(false);
    }
  };

  const setPermission = (m) =>
    save(
      m.perm === "editor" ? editors.filter((x) => x !== m.email) : [...editors, m.email],
      m.perm === "editor" ? [...viewers, m.email] : viewers.filter((x) => x !== m.email)
    );

  const removeMember = (m) =>
    save(editors.filter((x) => x !== m.email), viewers.filter((x) => x !== m.email));

  return (
    <div className="flex flex-col gap-2">
      <span className="text-[10px] uppercase tracking-wider text-muted-foreground font-body">
        Team · {members.length}/{MAX_TEAM} members
      </span>

      {members.map((m) => (
        <div key={m.email} className="flex items-center gap-2 rounded-lg bg-muted/40 border border-border px-2.5 py-1.5">
          <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-amber/15 text-amber text-[10px] font-semibold uppercase">
            {m.email.charAt(0)}
          </span>
          <div className="min-w-0 flex-1">
            <div className="truncate text-xs font-body">{m.email}</div>
            <div className="text-[9px] text-muted-foreground font-body uppercase tracking-wider">
              {m.perm === "editor" ? "Editing" : "Viewing"}
            </div>
          </div>
          <div className="flex shrink-0 rounded-md border border-border overflow-hidden">
            <button onClick={() => setPermission(m)} disabled={busy}
              className={cn("flex items-center gap-1 px-1.5 py-1 text-[9px] font-body uppercase tracking-wider transition disabled:opacity-40",
                m.perm === "editor" ? "bg-amber text-black" : "text-muted-foreground hover:text-foreground")}>
              <Pencil size={10} /> Edit
            </button>
            <button onClick={() => setPermission(m)} disabled={busy}
              className={cn("flex items-center gap-1 px-1.5 py-1 text-[9px] font-body uppercase tracking-wider transition disabled:opacity-40",
                m.perm === "viewer" ? "bg-amber text-black" : "text-muted-foreground hover:text-foreground")}>
              <Eye size={10} /> View
            </button>
          </div>
          <button onClick={() => removeMember(m)} disabled={busy}
            className="text-muted-foreground hover:text-alert transition shrink-0 disabled:opacity-40">
            <Trash2 size={13} />
          </button>
        </div>
      ))}

      {members.length === 0 && (
        <p className="text-[11px] text-muted-foreground font-body">
          Only you can open this project - add team members to share it with them.
        </p>
      )}

      {members.length < MAX_TEAM && (
        <div className="flex flex-col gap-1.5">
          <div className="flex gap-1.5">
            <input value={email} onChange={(ev) => { setEmail(ev.target.value); setError(""); }}
              onKeyDown={(ev) => ev.key === "Enter" && addMember()}
              placeholder="member@email.com" type="email"
              className="flex-1 min-w-0 rounded-lg bg-muted/40 border border-border px-2.5 py-1.5 text-xs font-body outline-none focus:border-amber/50" />
            <button onClick={addMember} disabled={busy || !email.trim()}
              className="rounded-lg bg-amber text-black px-2.5 flex items-center text-xs font-semibold disabled:opacity-40">
              {busy ? <Loader2 size={13} className="animate-spin" /> : <Plus size={13} />}
            </button>
          </div>
          <div className="flex items-center justify-between gap-2">
            <div className="flex rounded-md border border-border overflow-hidden">
              <button onClick={() => setPerm("editor")}
                className={cn("px-2 py-1 text-[9px] font-body uppercase tracking-wider transition", perm === "editor" ? "bg-amber text-black" : "text-muted-foreground")}>
                Editing
              </button>
              <button onClick={() => setPerm("viewer")}
                className={cn("px-2 py-1 text-[9px] font-body uppercase tracking-wider transition", perm === "viewer" ? "bg-amber text-black" : "text-muted-foreground")}>
                Viewing
              </button>
            </div>
            <label className="flex items-center gap-1.5 text-[9px] font-body text-muted-foreground cursor-pointer">
              <input type="checkbox" checked={sendInvite} onChange={(ev) => setSendInvite(ev.target.checked)} className="accent-amber" />
              Send account invite
            </label>
          </div>
          {error && <p className="text-[10px] font-body text-alert">{error}</p>}
        </div>
      )}

      <p className="text-[9px] text-muted-foreground/70 font-body">
        Members need their own account to open this project. Editing access is free for the launch period - it will move to a paid plan once billing launches.
      </p>
    </div>
  );
}