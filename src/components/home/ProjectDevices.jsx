import React, { useState } from "react";
import { base44 } from "@/api/base44Client";
import { Plus, Trash2, Loader2, Info, Save } from "lucide-react";
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

// a project's device list - add, edit, sync and remove devices in place
export default function ProjectDevices({ project, devices, projects, readOnly, onChange }) {
  const [name, setName] = useState("");
  const [kind, setKind] = useState("phone");
  const [busy, setBusy] = useState(false);
  const [detailsOpen, setDetailsOpen] = useState(null);
  const navigate = useNavigate();

  const linked = devices.filter((d) => d.project_id === project.id);
  const hasDetails = (d) => Boolean(d.make || d.model || d.colour || d.serial || d.photo);

  const add = async (e) => {
    e.preventDefault();
    if (!name.trim() || busy) return;
    setBusy(true);
    try {
      await base44.entities.Device.create({ name: name.trim(), kind, status: "offline", project_id: project.id });
      setName("");
      setKind("phone");
      onChange();
    } finally {
      setBusy(false);
    }
  };

  const toggleStatus = async (d) => {
    await base44.entities.Device.update(d.id, { status: d.status === "online" ? "offline" : "online" });
    onChange();
  };

  const assign = async (d, projectId) => {
    await base44.entities.Device.update(d.id, { project_id: projectId || null });
    onChange();
  };

  const removeDevice = async (d) => {
    await base44.entities.Device.delete(d.id);
    onChange();
  };

  // each device carries its own saved OS layout - snapshot this screen's
  // current config onto the device, or load the device's layout back here
  const saveLayout = async (d) => {
    const config = readCurrentOsConfig();
    if (!config) return;
    await base44.entities.Device.update(d.id, { config: JSON.stringify(slimConfig(config)) });
    onChange();
  };

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

  return (
    <div className="mt-2 pt-2 border-t border-border/60 flex flex-col gap-1.5">
      {linked.length === 0 && (
        <span className="text-[10px] text-muted-foreground/70 font-body">No devices linked yet</span>
      )}
      {linked.map((d) => (
        <div key={d.id} className="rounded-lg border border-border bg-muted/20 px-2.5 py-2 group">
          <div className="flex items-center gap-2.5">
            <button onClick={() => toggleStatus(d)} disabled={readOnly} title="Toggle online/offline"
              className={cn("h-2.5 w-2.5 rounded-full shrink-0 transition",
                d.status === "online" ? "bg-signal led-pulse" : "bg-muted-foreground/40 hover:bg-muted-foreground/70",
                readOnly && "cursor-default")} />
            <button onClick={() => openDevice(d)} title="Open this device's OS"
              className="flex-1 min-w-0 text-left">
              <span className="block text-xs font-body truncate text-foreground/80">{d.name}</span>
              <span className="block text-[9px] text-muted-foreground font-body uppercase tracking-wider">
                {d.kind}{[d.make, d.model].filter(Boolean).join(" ") ? ` · ${[d.make, d.model].filter(Boolean).join(" ")}` : ""}{d.config ? " · layout saved" : ""}
              </span>
            </button>
            {!readOnly && (
              <select value={d.project_id || ""} onChange={(e) => assign(d, e.target.value)} title="Move to project"
                className="rounded-md bg-muted/40 border border-border px-1.5 py-1 text-[10px] font-body outline-none max-w-[100px]">
                <option value="">Unassigned</option>
                {projects.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
              </select>
            )}
            {!readOnly && (
              <button onClick={() => setDetailsOpen(detailsOpen === d.id ? null : d.id)} title="Device info"
                className={cn("transition opacity-60 group-hover:opacity-100", hasDetails(d) ? "text-signal" : "text-muted-foreground hover:text-foreground")}>
                <Info size={14} />
              </button>
            )}
            {!readOnly && (
              <button onClick={() => saveLayout(d)} title="Save this screen's OS layout to the device"
                className="text-muted-foreground hover:text-foreground transition opacity-60 group-hover:opacity-100">
                <Save size={14} />
              </button>
            )}
            {!readOnly && (
              <button onClick={() => removeDevice(d)} title="Delete device"
                className="text-muted-foreground hover:text-alert transition opacity-60 group-hover:opacity-100">
                <Trash2 size={14} />
              </button>
            )}
          </div>
          {detailsOpen === d.id && !readOnly && (
            <div className="mt-2 pt-2 border-t border-border/60">
              <DeviceDetails device={d} onChange={onChange} />
            </div>
          )}
        </div>
      ))}
      {!readOnly && (
        <form onSubmit={add} className="flex gap-2">
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="New device name"
            className="flex-1 min-w-0 rounded-lg bg-muted/40 border border-border px-2.5 py-1.5 text-xs font-body outline-none focus:border-amber/50"
          />
          <select value={kind} onChange={(e) => setKind(e.target.value)}
            className="rounded-lg bg-muted/40 border border-border px-2 py-1.5 text-[10px] font-body outline-none">
            {kinds.map((k) => <option key={k.id} value={k.id}>{k.label}</option>)}
          </select>
          <button type="submit" disabled={busy || !name.trim()}
            className="rounded-lg bg-amber text-background px-2.5 flex items-center text-sm font-display font-semibold disabled:opacity-40">
            {busy ? <Loader2 size={14} className="animate-spin" /> : <Plus size={14} />}
          </button>
        </form>
      )}
    </div>
  );
}