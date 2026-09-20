import React, { useState, useEffect, useCallback } from "react";
import { base44 } from "@/api/base44Client";
import { MonitorSmartphone, Plus, Trash2, Loader2, Download, Info, Save } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { cn } from "@/lib/utils";
import { applyOsConfig, readCurrentOsConfig, slimConfig } from "@/lib/osConfigStore";
import { linkDevice } from "@/lib/deviceLink";
import DeviceDetails from "@/components/home/DeviceDetails";

const kinds = [
  { id: "phone", label: "Phone" },
  { id: "tablet", label: "Tablet" },
  { id: "screen", label: "Screen" },
  { id: "remote", label: "Remote" },
];

export default function DevicesPanel({ project }) {
  const [devices, setDevices] = useState(null);
  const [projects, setProjects] = useState([]);
  const [name, setName] = useState("");
  const [kind, setKind] = useState("phone");
  const [busy, setBusy] = useState(false);
  const [detailsOpen, setDetailsOpen] = useState(null);
  const [confirmDel, setConfirmDel] = useState(null);
  const navigate = useNavigate();

  const hasDetails = (d) => Boolean(d.make || d.model || d.colour || d.serial || d.photo);

  const refresh = useCallback(() => {
    base44.entities.Device.list("-created_date", 100)
      .then((d) => setDevices(d))
      .catch(() => setDevices([]));
    base44.entities.Project.list("-created_date", 100)
      .then((d) => setProjects(d))
      .catch(() => {});
  }, []);

  useEffect(() => {
    refresh();
    const unsub = base44.entities.Device.subscribe(() => refresh());
    return () => unsub();
  }, [refresh]);

  const add = async (e) => {
    e.preventDefault();
    if (!name.trim() || busy) return;
    setBusy(true);
    try {
      await base44.entities.Device.create({ name: name.trim(), kind, status: "offline", project_id: project?.id || null });
      setName("");
      setKind("phone");
      refresh();
    } finally {
      setBusy(false);
    }
  };

  const toggleStatus = async (d) => {
    await base44.entities.Device.update(d.id, { status: d.status === "online" ? "offline" : "online" });
    refresh();
  };

  const assign = async (d, projectId) => {
    await base44.entities.Device.update(d.id, { project_id: projectId || null });
    refresh();
  };

  const remove = async (d) => {
    await base44.entities.Device.delete(d.id);
    refresh();
  };

  // each device carries its own saved OS layout - snapshot this screen's
  // current config onto the device, or load the device's layout back here
  const saveLayout = async (d) => {
    const config = readCurrentOsConfig();
    if (!config) return;
    await base44.entities.Device.update(d.id, { config: JSON.stringify(slimConfig(config)) });
    refresh();
  };

  const loadLayout = (d) => {
    try {
      applyOsConfig(JSON.parse(d.config));
      linkDevice(d.id, d.name);
      navigate("/os");
    } catch {}
  };

  const projectById = (id) => projects.find((p) => p.id === id);

  // this panel follows the project selected in Projects - only its devices show
  const visible = project && devices ? devices.filter((d) => d.project_id === project.id) : [];

  return (
    <div className="rounded-2xl border border-border bg-surface p-5">
      <div className="flex items-center gap-2.5 mb-4">
        <span className="h-9 w-9 rounded-lg bg-signal/15 text-signal flex items-center justify-center">
          <MonitorSmartphone size={18} />
        </span>
        <div className="flex-1">
          <h3 className="font-display font-bold text-base leading-none">{project ? project.name : "Devices"}</h3>
          <p className="text-[11px] text-muted-foreground font-body mt-1">
            {project ? `${visible.length} ${visible.length === 1 ? "device" : "devices"}` : devices ? "select a project in Projects" : "loading…"}
          </p>
        </div>
      </div>

      <form onSubmit={add} className="flex gap-2 mb-4">
        <input
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="New device name"
          className="flex-1 min-w-0 rounded-lg bg-muted/40 border border-border px-3 py-2 text-sm font-body outline-none focus:border-signal/50"
        />
        <select value={kind} onChange={(e) => setKind(e.target.value)}
          className="rounded-lg bg-muted/40 border border-border px-2 py-2 text-xs font-body outline-none">
          {kinds.map((k) => <option key={k.id} value={k.id}>{k.label}</option>)}
        </select>
        <button type="submit" disabled={busy || !name.trim()}
          className="rounded-lg bg-signal text-background px-3 flex items-center gap-1 text-sm font-display font-semibold disabled:opacity-40">
          {busy ? <Loader2 size={15} className="animate-spin" /> : <Plus size={15} />}
        </button>
      </form>

      {devices === null ? (
        <div className="py-10 flex justify-center text-muted-foreground"><Loader2 className="animate-spin" size={20} /></div>
      ) : !project ? (
        <p className="py-8 text-center text-xs text-muted-foreground font-body">Select a project in Projects to see its devices.</p>
      ) : visible.length === 0 ? (
        <p className="py-8 text-center text-xs text-muted-foreground font-body">No devices linked to {project.name} yet - add one above.</p>
      ) : (
        <ul className="flex flex-col gap-1.5">
          {visible.map((d) => (
            <li key={d.id} className="rounded-lg border border-border bg-muted/30 px-3 py-2.5">
              <div className="group flex items-center gap-3">
              <button onClick={() => toggleStatus(d)} title="Toggle online/offline"
                className={cn("h-2.5 w-2.5 rounded-full shrink-0 transition",
                  d.status === "online" ? "bg-signal led-pulse" : "bg-muted-foreground/40 hover:bg-muted-foreground/70")} />
              <div className="flex-1 min-w-0">
                <div className="text-sm font-body truncate">{d.name}</div>
                <div className="text-[10px] text-muted-foreground font-body uppercase tracking-wider">
                  {d.kind}{[d.make, d.model].filter(Boolean).join(" ") ? ` · ${[d.make, d.model].filter(Boolean).join(" ")}` : ""}{d.project_id && projectById(d.project_id) ? ` · ${projectById(d.project_id).name}` : ""}{d.config ? " · layout saved" : ""}
                </div>
              </div>
              <select value={d.project_id || ""} onChange={(e) => assign(d, e.target.value)}
                className="rounded-md bg-muted/40 border border-border px-1.5 py-1 text-[10px] font-body outline-none max-w-[110px]">
                <option value="">Unassigned</option>
                {projects.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
              </select>
              <button onClick={() => setDetailsOpen(detailsOpen === d.id ? null : d.id)} title="Device info"
                className={cn("transition opacity-60 group-hover:opacity-100", hasDetails(d) ? "text-signal" : "text-muted-foreground hover:text-foreground")}>
                <Info size={15} />
              </button>
              <button onClick={() => saveLayout(d)} title="Save this screen's OS layout to the device"
                className="text-muted-foreground hover:text-foreground transition opacity-60 group-hover:opacity-100">
                <Save size={15} />
              </button>
              {d.config && (
                <button onClick={() => loadLayout(d)} title="Load this device's layout onto this screen"
                  className="text-amber/80 hover:text-amber transition opacity-60 group-hover:opacity-100">
                  <Download size={15} />
                </button>
              )}
              {confirmDel === d.id ? (
                <span className="flex shrink-0 items-center gap-1.5">
                  <span className="text-[10px] font-body text-alert">Delete?</span>
                  <button onClick={() => { remove(d); setConfirmDel(null); }}
                    className="text-[10px] font-body font-semibold uppercase tracking-wider text-alert">Yes</button>
                  <button onClick={() => setConfirmDel(null)}
                    className="text-[10px] font-body uppercase tracking-wider text-muted-foreground hover:text-foreground">No</button>
                </span>
              ) : (
                <button onClick={() => setConfirmDel(d.id)}
                  className="text-muted-foreground hover:text-alert transition opacity-60 group-hover:opacity-100">
                  <Trash2 size={15} />
                </button>
              )}
              </div>
              {detailsOpen === d.id && (
                <div className="mt-2 pt-2 border-t border-border/60">
                  <DeviceDetails device={d} onChange={refresh} />
                </div>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}