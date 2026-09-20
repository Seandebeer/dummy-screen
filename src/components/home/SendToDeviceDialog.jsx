import React, { useState, useEffect } from "react";
import { Loader2 } from "lucide-react";
import { base44 } from "@/api/base44Client";
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription,
} from "@/components/ui/dialog";
import { applyConfigToDevice, createDeviceInProject, createProjectWithDevice } from "@/lib/osDeviceSave";

// SendToDeviceDialog - put a saved OS layout onto a device: apply it to an
// existing device, create a new device inside an existing project, or create
// a brand-new project with a device carrying this layout.
export default function SendToDeviceDialog({ entry, onClose }) {
  const open = Boolean(entry);
  const [devices, setDevices] = useState(null);
  const [projects, setProjects] = useState(null);
  const [name, setName] = useState("");
  const [projectTarget, setProjectTarget] = useState("");
  const [projectName, setProjectName] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!open) return;
    setDevices(null); setProjects(null); setName(""); setProjectTarget(""); setProjectName("");
    base44.entities.Device.list("-created_date", 100).then(setDevices).catch(() => setDevices([]));
    base44.entities.Project.list("-created_date", 100).then(setProjects).catch(() => setProjects([]));
  }, [open, entry?.id]);

  const addToDevice = async (d) => {
    if (busy) return;
    setBusy(true);
    try {
      await applyConfigToDevice(d.id, entry.data);
      onClose();
    } catch {}
    setBusy(false);
  };

  const createDevice = async () => {
    if (!name.trim() || busy) return;
    setBusy(true);
    try {
      if (projectTarget === "new") await createProjectWithDevice(projectName, name, entry.data);
      else await createDeviceInProject(projectTarget, name, entry.data);
      onClose();
    } catch {}
    setBusy(false);
  };

  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-w-sm">
        <DialogHeader>
          <DialogTitle className="font-display text-left">{entry?.name}</DialogTitle>
          <DialogDescription className="text-left">Add this OS layout to a device</DialogDescription>
        </DialogHeader>

        <div>
          <div className="mb-1.5 font-body text-[10px] uppercase tracking-wider text-muted-foreground">Add to existing device</div>
          {devices === null || projects === null ? (
            <div className="flex justify-center py-3 text-muted-foreground"><Loader2 className="animate-spin" size={16} /></div>
          ) : devices.filter((d) => (projects || []).some((p) => p.id === d.project_id)).length === 0 ? (
            <p className="py-2 text-xs font-body text-muted-foreground">No existing devices yet - create one below.</p>
          ) : (
            <div className="flex max-h-36 flex-col gap-1.5 overflow-y-auto pr-1">
              {devices.filter((d) => (projects || []).some((p) => p.id === d.project_id)).map((d) => (
                <button key={d.id} onClick={() => addToDevice(d)} disabled={busy}
                  className="flex items-center justify-between rounded-lg border border-border bg-muted/30 px-3 py-2 text-left transition hover:border-signal/40 disabled:opacity-50">
                  <span className="truncate text-sm font-body">{d.name}</span>
                  <span className="font-body text-[10px] uppercase tracking-wider text-muted-foreground">{d.kind}</span>
                </button>
              ))}
            </div>
          )}
        </div>

        <div>
          <div className="mb-1.5 font-body text-[10px] uppercase tracking-wider text-muted-foreground">Or create a new device</div>
          <div className="flex flex-col gap-2">
            <input value={name} onChange={(e) => setName(e.target.value)} placeholder="New device name"
              className="rounded-lg border border-border bg-muted/40 px-3 py-2 text-xs font-body outline-none focus:border-signal/50" />
            <select value={projectTarget} onChange={(e) => setProjectTarget(e.target.value)}
              className="rounded-lg border border-border bg-muted/40 px-3 py-2 text-xs font-body outline-none">
              <option value="">Choose a project…</option>
              {(projects || []).map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
              <option value="new">New project…</option>
            </select>
            {projectTarget === "new" && (
              <input value={projectName} onChange={(e) => setProjectName(e.target.value)} placeholder="New project name"
                className="rounded-lg border border-border bg-muted/40 px-3 py-2 text-xs font-body outline-none focus:border-signal/50" />
            )}
            <button onClick={createDevice}
              disabled={!name.trim() || !projectTarget || (projectTarget === "new" && !projectName.trim()) || busy}
              className="flex items-center justify-center gap-1.5 rounded-lg bg-signal px-3 py-2 text-xs font-display font-semibold text-background disabled:opacity-40">
              {busy ? <Loader2 size={13} className="animate-spin" /> : null} Create device
            </button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}