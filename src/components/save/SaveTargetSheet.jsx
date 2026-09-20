import React, { useState, useEffect } from "react";
import { Bookmark, ChevronLeft, FolderKanban, Loader2, Monitor, Plus, Smartphone, Tablet, Tv, X } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { saveConfig } from "@/lib/savedConfigs";
import { cn } from "@/lib/utils";

// SaveTargetSheet - whenever a screen or UI marker layout is saved, choose
// where it goes: the Saved card on Home (favourites) or a device via its
// project - pick a project (or add one), then one of its devices (or add
// one). Device saves live in that device's folder on Home.

const KINDS = [
  { id: "phone", label: "Phone", Icon: Smartphone },
  { id: "tablet", label: "Tablet", Icon: Tablet },
  { id: "screen", label: "Screen", Icon: Monitor },
  { id: "remote", label: "Remote", Icon: Tv },
];

export default function SaveTargetSheet({ title, defaultName, build, onClose }) {
  const [name, setName] = useState(defaultName || "");
  const [step, setStep] = useState("target"); // target | project | device
  const [projects, setProjects] = useState(null);
  const [devices, setDevices] = useState(null);
  const [project, setProject] = useState(null);
  const [newProjectName, setNewProjectName] = useState("");
  const [newDeviceName, setNewDeviceName] = useState("");
  const [newKind, setNewKind] = useState("phone");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (step !== "project") return;
    let alive = true;
    base44.entities.Project.list("-created_date", 100)
      .then((ps) => alive && setProjects(ps))
      .catch(() => alive && setProjects([]));
    return () => { alive = false; };
  }, [step]);

  useEffect(() => {
    if (step !== "device" || !project) return;
    let alive = true;
    setDevices(null);
    base44.entities.Device.filter({ project_id: project.id }, "-created_date", 100)
      .then((ds) => alive && setDevices(ds))
      .catch(() => alive && setDevices([]));
    return () => { alive = false; };
  }, [step, project]);

  const saveWith = (deviceId) => {
    const entry = build(name.trim() || defaultName || "Untitled");
    if (deviceId) entry.device_id = deviceId;
    if (project) entry.project_id = project.id;
    saveConfig(entry);
    onClose();
  };

  const saveFavourites = () => saveWith(null);

  const addProject = async () => {
    if (!newProjectName.trim() || busy) return;
    setBusy(true);
    try {
      const rec = await base44.entities.Project.create({ name: newProjectName.trim() });
      setNewProjectName("");
      setProject(rec);
      setStep("device");
    } finally {
      setBusy(false);
    }
  };

  const addDevice = async () => {
    if (!newDeviceName.trim() || !project || busy) return;
    setBusy(true);
    try {
      const rec = await base44.entities.Device.create({
        name: newDeviceName.trim(), kind: newKind, project_id: project.id, sort_order: (devices?.length ?? 0),
      });
      saveWith(rec.id);
    } finally {
      setBusy(false);
    }
  };

  const Row = ({ icon, label, sub, onClick, disabled }) => (
    <button onClick={onClick} disabled={disabled}
      className="flex w-full items-center gap-3 rounded-xl bg-white/[0.08] px-3 py-2.5 text-left transition active:bg-white/15 disabled:opacity-50">
      <span className="shrink-0 text-white/80">{icon}</span>
      <span className="min-w-0 flex-1">
        <span className="block truncate text-[13.5px] font-medium">{label}</span>
        {sub && <span className="block truncate text-[10.5px] text-white/40">{sub}</span>}
      </span>
    </button>
  );

  return (
    <div className="absolute inset-0 z-[70] flex items-end bg-black/60" onClick={onClose}>
      <div onClick={(e) => e.stopPropagation()}
        className="max-h-[85%] w-full overflow-y-auto rounded-t-3xl bg-[#1c1c1e] px-4 pb-5 pt-3 text-white shadow-2xl">
        <div className="mx-auto mb-3 h-1 w-10 rounded-full bg-white/20" />
        <div className="mb-3 flex items-center gap-2">
          {step !== "target" && (
            <button onClick={() => setStep(step === "device" ? "project" : "target")} aria-label="Back"
              className="rounded-full bg-white/10 p-1.5 text-white/70"><ChevronLeft size={14} /></button>
          )}
          <span className="flex-1 font-display text-[16px] font-semibold">
            {step === "target" ? title : step === "project" ? "Choose a project" : `Devices in ${project?.name}`}
          </span>
          <button onClick={onClose} aria-label="Close"
            className="rounded-full bg-white/10 p-1.5 text-white/70"><X size={14} /></button>
        </div>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Name"
          className="mb-3 w-full rounded-xl bg-white/10 px-3.5 py-2.5 text-[14px] outline-none placeholder:text-white/30" />

        {step === "target" && (
          <div className="space-y-1.5">
            <Row icon={<Bookmark size={16} />} label="Favourites" sub="Saved card on Home" onClick={saveFavourites} />
            <Row icon={<FolderKanban size={16} />} label="Project" sub="Pick a project, then a device"
              onClick={() => setStep("project")} />
          </div>
        )}

        {step === "project" && (
          <div className="space-y-1.5">
            {projects === null ? (
              <div className="flex justify-center py-6 text-white/50"><Loader2 size={18} className="animate-spin" /></div>
            ) : projects.length === 0 ? (
              <>
                <p className="py-2 text-center text-[11px] font-body text-white/40">
                  You have no projects yet - create one to save to a device.
                </p>
                <div className="flex gap-1.5 pt-1">
                  <input value={newProjectName} onChange={(e) => setNewProjectName(e.target.value)}
                    placeholder="New project name"
                    className="min-w-0 flex-1 rounded-xl bg-white/10 px-3.5 py-2.5 text-[13px] outline-none placeholder:text-white/30" />
                  <button onClick={addProject} disabled={busy || !newProjectName.trim()}
                    className="flex items-center gap-1 rounded-xl bg-[#0A84FF] px-3.5 text-[13px] font-semibold transition active:opacity-80 disabled:opacity-40">
                    {busy ? <Loader2 size={14} className="animate-spin" /> : <Plus size={14} />} Add
                  </button>
                </div>
              </>
            ) : projects.map((p) => (
              <Row key={p.id} icon={<FolderKanban size={16} />} label={p.name} sub="Open device list"
                onClick={() => { setProject(p); setStep("device"); }} />
            ))}
          </div>
        )}

        {step === "device" && project && (
          <div className="space-y-1.5">
            {devices === null ? (
              <div className="flex justify-center py-6 text-white/50"><Loader2 size={18} className="animate-spin" /></div>
            ) : devices.length === 0 ? (
              <>
                <p className="py-2 text-center text-[11px] font-body text-white/40">
                  No devices in {project.name} yet - create one to save to it.
                </p>
                <div className="flex gap-1.5 pt-1">
                  <input value={newDeviceName} onChange={(e) => setNewDeviceName(e.target.value)}
                    placeholder="New device name"
                    className="min-w-0 flex-1 rounded-xl bg-white/10 px-3.5 py-2.5 text-[13px] outline-none placeholder:text-white/30" />
                  <select value={newKind} onChange={(e) => setNewKind(e.target.value)}
                    className="rounded-xl bg-white/10 px-2 py-2.5 text-[12px] text-white/70 outline-none">
                    {KINDS.map((k) => <option key={k.id} value={k.id}>{k.label}</option>)}
                  </select>
                  <button onClick={addDevice} disabled={busy || !newDeviceName.trim()}
                    className="flex items-center gap-1 rounded-xl bg-[#0A84FF] px-3.5 text-[13px] font-semibold transition active:opacity-80 disabled:opacity-40">
                    {busy ? <Loader2 size={14} className="animate-spin" /> : <Plus size={14} />} Add
                  </button>
                </div>
              </>
            ) : devices.map((d) => {
              const meta = KINDS.find((k) => k.id === d.kind) || KINDS[0];
              return (
                <Row key={d.id} icon={<meta.Icon size={16} />} label={d.name}
                  sub={meta.label + ([d.make, d.model].filter(Boolean).length ? ` · ${[d.make, d.model].filter(Boolean).join(" ")}` : "")}
                  onClick={() => saveWith(d.id)} />
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}