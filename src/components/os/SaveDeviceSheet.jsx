import React, { useState, useEffect } from "react";
import { Loader2, Save, X } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { saveConfig } from "@/lib/savedConfigs";
import { slimConfig } from "@/lib/osConfigStore";
import { linkDevice } from "@/lib/deviceLink";
import { createDeviceInProject, createProjectWithDevice } from "@/lib/osDeviceSave";
import { cn } from "@/lib/utils";

// SaveDeviceSheet - save this screen's OS layout as a new device inside a
// project (creating the project first if there are none), or to favourites
// (the Saved card on Home).

export default function SaveDeviceSheet({ config, onClose, onSaved }) {
  const [name, setName] = useState("");
  const [projectName, setProjectName] = useState("");
  const [projects, setProjects] = useState(null);
  const [target, setTarget] = useState("project");
  const [projectId, setProjectId] = useState(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    base44.entities.Project.list("-created_date", 100)
      .then(setProjects)
      .catch(() => setProjects([]));
  }, []);

  const save = async () => {
    const n = name.trim();
    if (!n || busy) return;
    setBusy(true);
    try {
      if (target === "fav") {
        saveConfig({ kind: "os", category: "OS", name: n, data: slimConfig(config) });
      } else if (projectId) {
        const rec = await createDeviceInProject(projectId, n, slimConfig(config));
        linkDevice(rec.id, rec.name);
        onSaved?.(rec.name);
      } else {
        const { device } = await createProjectWithDevice(projectName, n, slimConfig(config));
        linkDevice(device.id, device.name);
        onSaved?.(device.name);
      }
      onClose();
    } catch {
      setBusy(false);
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

  const canSave =
    Boolean(name.trim()) && !busy &&
    (target === "fav" || (projects?.length ? Boolean(projectId) : Boolean(projectName.trim())));

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
        <input value={name} onChange={(e) => setName(e.target.value)}
          placeholder={target === "fav" ? "Favourite name (e.g. Maya's setup)" : "Device name (e.g. Maya's phone)"}
          className="w-full rounded-xl bg-white/10 px-3.5 py-2.5 text-[14px] outline-none placeholder:text-white/30" />
        <div className="mt-3 space-y-1.5">
          <div className="px-1 pb-1 text-[10px] font-semibold uppercase tracking-widest text-white/35">Save to</div>
          <Row label="Project" sub="Add a new device to one of your projects"
            selected={target === "project"} onClick={() => setTarget("project")} />
          {target === "project" && (
            projects === null ? (
              <div className="flex justify-center py-2 text-white/40"><Loader2 size={16} className="animate-spin" /></div>
            ) : projects.length > 0 ? (
              projects.map((p) => (
                <Row key={p.id} label={p.name} sub="Add device to this project"
                  selected={projectId === p.id} onClick={() => setProjectId(p.id)} />
              ))
            ) : (
              <div className="rounded-xl bg-white/[0.06] px-3 py-2.5">
                <p className="text-[11px] text-white/40">No projects yet - create your first one:</p>
                <input autoFocus value={projectName} onChange={(e) => setProjectName(e.target.value)}
                  placeholder="Project name (e.g. Night Shift)"
                  className="mt-2 w-full rounded-xl bg-white/10 px-3.5 py-2.5 text-[13px] outline-none placeholder:text-white/30" />
              </div>
            )
          )}
          <Row label="Favourites" sub="Saved card on Home"
            selected={target === "fav"} onClick={() => setTarget("fav")} />
        </div>
        <button onClick={save} disabled={!canSave}
          className="mt-4 flex w-full items-center justify-center gap-2 rounded-xl bg-[#0A84FF] py-3 text-[15px] font-semibold transition active:opacity-80 disabled:opacity-40">
          {busy ? <Loader2 size={16} className="animate-spin" /> : <Save size={15} />}
          {busy ? "Saving…" : "Save"}
        </button>
      </div>
    </div>
  );
}