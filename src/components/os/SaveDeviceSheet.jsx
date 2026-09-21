import React, { useState, useEffect } from "react";
import { ChevronDown, Loader2, Plus, Save, X } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { saveConfig } from "@/lib/savedConfigs";
import { slimConfig } from "@/lib/osConfigStore";
import { getDeviceName, getLinkedDeviceId, linkDevice } from "@/lib/deviceLink";
import { createDeviceInProject, applyConfigToDevice } from "@/lib/osDeviceSave";
import { cn } from "@/lib/utils";

// SaveDeviceSheet - save this screen's OS layout as a new device inside a
// project, onto an existing device, or to favourites (the Saved card on Home).

export default function SaveDeviceSheet({ config, onClose, onSaved }) {
  // a screen with a linked device saves straight onto itself - the full
  // "new project / existing device" options are only for a sandbox screen
  const linkedId = getLinkedDeviceId();
  const [name, setName] = useState("");
  const [projects, setProjects] = useState(null);
  const [target, setTarget] = useState(linkedId ? "this" : "project");
  const [error, setError] = useState(null);
  const [projectId, setProjectId] = useState(null);
  const [projectOpen, setProjectOpen] = useState(false);
  const [newProjectOpen, setNewProjectOpen] = useState(false);
  const [newProjectName, setNewProjectName] = useState("");
  // offline: a "new project" is just a remembered name until the save syncs
  const [pendingProject, setPendingProject] = useState(null);
  const [devices, setDevices] = useState(null);
  const [deviceId, setDeviceId] = useState(null);
  const [deviceOpen, setDeviceOpen] = useState(false);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    base44.entities.Project.list("-created_date", 100)
      .then(setProjects)
      .catch(() => setProjects([]));
    base44.entities.Device.list("-created_date", 200)
      .then(setDevices)
      .catch(() => setDevices([]));
  }, []);

  const chosen = projects?.find((p) => p.id === projectId) || (pendingProject ? { name: pendingProject } : null);
  const chosenDevice = devices?.find((d) => d.id === deviceId) || null;

  // only devices inside projects this user can see - matches the Home panels
  const projectDevices = (devices || [])
    .filter((d) => (projects || []).some((p) => p.id === d.project_id))
    .sort((a, b) => a.name.localeCompare(b.name));

  const createProject = async () => {
    const pn = newProjectName.trim();
    if (!pn || busy) return;
    // offline: the project is created together with the device once the
    // queued save syncs - just remember the name and carry on
    if (!navigator.onLine) {
      setPendingProject(pn);
      setNewProjectOpen(false);
      setNewProjectName("");
      setProjectOpen(false);
      return;
    }
    setBusy(true);
    try {
      const rec = await base44.entities.Project.create({ name: pn });
      setProjects((prev) => (prev || []).concat(rec));
      setProjectId(rec.id);
      setNewProjectOpen(false);
      setNewProjectName("");
      setProjectOpen(false);
    } catch {
      setError("Could not create project - check your connection and try again");
    }
    setBusy(false);
  };

  const save = async () => {
    if (busy || !canSave) return;
    const n = name.trim();
    setBusy(true);
    setError(null);
    try {
      if (target === "fav") {
        saveConfig({ kind: "os", category: "OS", name: n, data: slimConfig(config) });
        onSaved?.(null);
      } else if (target === "this") {
        await applyConfigToDevice(linkedId, slimConfig(config));
        onSaved?.(getDeviceName());
      } else if (target === "device") {
        await applyConfigToDevice(deviceId, slimConfig(config));
        linkDevice(deviceId, chosenDevice?.name);
        onSaved?.(chosenDevice?.name);
      } else {
        // offline this returns null - the record appears once the save syncs
        const rec = await createDeviceInProject(projectId, n, slimConfig(config), pendingProject || undefined);
        if (rec) linkDevice(rec.id, rec.name);
        onSaved?.(rec?.name);
      }
      onClose();
    } catch {
      setBusy(false);
      setError("Save failed - check your connection and try again");
    }
  };

  const Row = ({ label, sub, selected, onClick }) => (
    <button onClick={onClick}
      className={cn("flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left transition",
        selected ? "bg-[#0A84FF]/25" : "bg-white/[0.06] active:bg-white/10")}>
      <span className="min-w-0 flex-1">
        <span className="block truncate text-[13.5px] font-medium">{label}</span>
        {sub && <span className="block truncate text-[10.5px] text-white/40">{sub}</span>}
      </span>
      {selected && <span className="h-2.5 w-2.5 shrink-0 rounded-full bg-[#0A84FF]" />}
    </button>
  );

  const canSave = !busy && (target === "this" ? true
    : target === "device" ? Boolean(deviceId)
    : Boolean(name.trim()) && (target === "fav" || Boolean(projectId || pendingProject)));

  return (
    <div className="absolute inset-0 z-40 flex items-end bg-black/60" onClick={() => !busy && onClose()}>
      <div onClick={(e) => e.stopPropagation()}
        className="no-scrollbar max-h-[85%] w-full overflow-y-auto rounded-t-3xl bg-[#1c1c1e] px-4 pb-5 pt-3 text-white shadow-2xl">
        <div className="mx-auto mb-3 h-1 w-10 rounded-full bg-white/20" />
        <div className="mb-3 flex items-center justify-between">
          <span className="font-display text-[16px] font-semibold">Save OS layout</span>
          <button onClick={onClose} aria-label="Close"
            className="rounded-full bg-white/10 p-1.5 text-white/70"><X size={14} /></button>
        </div>
        {target !== "device" && target !== "this" && (
          <input value={name} onChange={(e) => setName(e.target.value)}
            placeholder={target === "fav" ? "Favourite name (e.g. Maya's setup)" : "Device name (e.g. Maya's phone)"}
            className="w-full rounded-xl bg-white/10 px-3.5 py-2.5 text-[14px] outline-none placeholder:text-white/30" />
        )}
        <div className="mt-3 space-y-1.5">
          <div className="px-1 pb-1 text-[10px] font-semibold uppercase tracking-widest text-white/35">Save to</div>
          {linkedId && (
            <Row label="This device" sub={`${getDeviceName()} · update its saved layout`}
              selected={target === "this"}
              onClick={() => { setTarget("this"); setProjectOpen(false); setDeviceOpen(false); }} />
          )}
          {!linkedId && (<>
          <button onClick={() => { setTarget("project"); setDeviceOpen(false); setProjectOpen((o) => !o); }}
            className={cn("flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left transition",
              target === "project" ? "bg-[#0A84FF]/25" : "bg-white/[0.06] active:bg-white/10")}>
            <span className="min-w-0 flex-1">
              <span className="block truncate text-[13.5px] font-medium">Project</span>
              <span className="block truncate text-[10.5px] text-white/40">
                {chosen ? chosen.name : "Choose a project"}
              </span>
            </span>
            <ChevronDown size={15}
              className={cn("shrink-0 text-white/50 transition", projectOpen && "rotate-180")} />
          </button>
          {target === "project" && projectOpen && (
            projects === null ? (
              <div className="flex justify-center py-2 text-white/40"><Loader2 size={16} className="animate-spin" /></div>
            ) : (
              <>
                {projects.map((p) => (
                  <Row key={p.id} label={p.name} selected={projectId === p.id}
                    onClick={() => { setProjectId(p.id); setPendingProject(null); setProjectOpen(false); }} />
                ))}
                <Row label="Add new project…" sub="Create a project for this device"
                  onClick={() => { setNewProjectOpen(true); setProjectOpen(false); }} />
              </>
            )
          )}
          <button onClick={() => { setTarget("device"); setProjectOpen(false); setDeviceOpen((o) => !o); }}
            className={cn("flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left transition",
              target === "device" ? "bg-[#0A84FF]/25" : "bg-white/[0.06] active:bg-white/10")}>
            <span className="min-w-0 flex-1">
              <span className="block truncate text-[13.5px] font-medium">Existing device</span>
              <span className="block truncate text-[10.5px] text-white/40">
                {chosenDevice ? chosenDevice.name : "Update a saved device"}
              </span>
            </span>
            <ChevronDown size={15}
              className={cn("shrink-0 text-white/50 transition", deviceOpen && "rotate-180")} />
          </button>
          {target === "device" && deviceOpen && (
            devices === null || projects === null ? (
              <div className="flex justify-center py-2 text-white/40"><Loader2 size={16} className="animate-spin" /></div>
            ) : projectDevices.length > 0 ? (
              projectDevices.map((d) => (
                <Row key={d.id} label={d.name}
                  sub={projects.find((p) => p.id === d.project_id)?.name}
                  selected={deviceId === d.id}
                  onClick={() => { setDeviceId(d.id); setDeviceOpen(false); }} />
              ))
            ) : (
              <p className="px-3 py-2 text-[11px] text-white/40">No existing devices yet - save one under Project first.</p>
            )
          )}
          </>)}
          <Row label="Favourites" sub="Saved card on Home"
            selected={target === "fav"}
            onClick={() => { setTarget("fav"); setProjectOpen(false); setDeviceOpen(false); }} />
        </div>
        {error && <p className="mt-2 px-1 text-[11px] text-red-400">{error}</p>}
        <button onClick={save} disabled={!canSave}
          className="mt-4 flex w-full items-center justify-center gap-2 rounded-xl bg-[#0A84FF] py-3 text-[15px] font-semibold transition active:opacity-80 disabled:opacity-40">
          {busy ? <Loader2 size={16} className="animate-spin" /> : <Save size={15} />}
          {busy ? "Saving…" : "Save"}
        </button>
      </div>

      {/* create-new-project window */}
      {newProjectOpen && (
        <div className="absolute inset-0 z-10 flex items-center justify-center bg-black/70 px-4"
          onClick={() => !busy && setNewProjectOpen(false)}>
          <div onClick={(e) => e.stopPropagation()}
            className="w-full max-w-sm rounded-2xl bg-[#1c1c1e] p-4 text-white shadow-2xl">
            <p className="mb-3 font-display text-[15px] font-semibold">New project</p>
            <input autoFocus value={newProjectName} onChange={(e) => setNewProjectName(e.target.value)}
              placeholder="Project name (e.g. Night Shift)"
              className="w-full rounded-xl bg-white/10 px-3.5 py-2.5 text-[14px] outline-none placeholder:text-white/30" />
            <div className="mt-3 flex gap-2">
              <button onClick={() => setNewProjectOpen(false)} disabled={busy}
                className="flex-1 rounded-xl bg-white/10 py-2.5 text-[14px] font-medium disabled:opacity-50">Cancel</button>
              <button onClick={createProject} disabled={!newProjectName.trim() || busy}
                className="flex flex-1 items-center justify-center gap-1.5 rounded-xl bg-[#0A84FF] py-2.5 text-[14px] font-semibold disabled:opacity-40">
                {busy ? <Loader2 size={14} className="animate-spin" /> : <Plus size={14} />} Create
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}