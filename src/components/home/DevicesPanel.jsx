import React, { useState, useEffect, useCallback, useRef } from "react";
import { base44 } from "@/api/base44Client";
import { MonitorSmartphone, FolderKanban, Plus, Trash2, Loader2, Info, ImageUp, Check, GripVertical, Folder } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { cn } from "@/lib/utils";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { applyOsConfig, resetOsConfig } from "@/lib/osConfigStore";
import { linkDevice } from "@/lib/deviceLink";
import DeviceDetails from "@/components/home/DeviceDetails";
import DeviceFolder from "@/components/home/DeviceFolder";
import ConfirmDeleteDialog from "@/components/home/ConfirmDeleteDialog";
import { DragDropContext, Droppable, Draggable } from "@hello-pangea/dnd";
import { arrayMove, bySortOrder } from "@/lib/reorder";

const kinds = [
  { id: "phone", label: "Phone" },
  { id: "tablet", label: "Tablet" },
  { id: "screen", label: "Screen" },
  { id: "remote", label: "Remote" },
];

export default function DevicesPanel({ project }) {
  const [devices, setDevices] = useState(null);
  const [name, setName] = useState("");
  const [kind, setKind] = useState("phone");
  const [busy, setBusy] = useState(false);
  const [addOpen, setAddOpen] = useState(false);
  const [make, setMake] = useState("");
  const [model, setModel] = useState("");
  const [colour, setColour] = useState("");
  const [serial, setSerial] = useState("");
  const [photo, setPhoto] = useState("");
  const [uploading, setUploading] = useState(false);
  const fileRef = useRef(null);
  const [detailsOpen, setDetailsOpen] = useState(null);
  const [folderOpen, setFolderOpen] = useState(null);
  const [confirmDel, setConfirmDel] = useState(null);
  const navigate = useNavigate();

  const hasDetails = (d) => Boolean(d.make || d.model || d.colour || d.serial || d.photo);

  const refresh = useCallback(() => {
    base44.entities.Device.list("-created_date", 100)
      .then((d) => setDevices(d))
      .catch(() => setDevices([]));
  }, []);

  useEffect(() => {
    refresh();
    const unsub = base44.entities.Device.subscribe(() => refresh());
    return () => unsub();
  }, [refresh]);

  const add = async (e) => {
    e.preventDefault();
    if (!name.trim() || busy || !project) return;
    setBusy(true);
    try {
      await base44.entities.Device.create({
        name: name.trim(), kind, status: "offline", project_id: project.id,
        make: make.trim(), model: model.trim(), colour: colour.trim(), serial: serial.trim(), photo,
        sort_order: ordered.length ? (ordered[0].sort_order ?? 0) - 1 : 0,
      });
      setName("");
      setKind("phone");
      setMake(""); setModel(""); setColour(""); setSerial(""); setPhoto("");
      setAddOpen(false);
      refresh();
    } finally {
      setBusy(false);
    }
  };

  const onFile = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setUploading(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
      setPhoto(file_url);
    } catch {}
    setUploading(false);
  };

  const toggleStatus = async (d) => {
    await base44.entities.Device.update(d.id, { status: d.status === "online" ? "offline" : "online" });
    refresh();
  };

  const remove = async (d) => {
    await base44.entities.Device.delete(d.id);
    refresh();
  };

  // open this device's OS on this screen - its saved layout if it has one,
  // otherwise the out-of-the-box setup (latest Apple skin, graphite, no lock)
  const loadLayout = (d) => {
    if (d.config) {
      try {
        applyOsConfig(JSON.parse(d.config));
      } catch {}
    } else {
      resetOsConfig();
    }
    linkDevice(d.id, d.name);
    navigate("/os");
  };

  // this panel follows the project selected in Projects - only its devices show
  const visible = project && devices ? devices.filter((d) => d.project_id === project.id) : [];
  const ordered = visible.slice().sort(bySortOrder);

  const onDragEnd = async (res) => {
    if (!res.destination || res.destination.index === res.source.index) return;
    const next = arrayMove(ordered, res.source.index, res.destination.index);
    await base44.entities.Device.bulkUpdate(next.map((d, i) => ({ id: d.id, sort_order: i })));
    refresh();
  };

  return (
    <div className="rounded-2xl border border-border bg-surface p-5">
      <div className="flex items-center gap-2.5 mb-4">
        <span className="h-9 w-9 rounded-lg bg-signal/15 text-signal flex items-center justify-center">
          {project ? <FolderKanban size={18} /> : <MonitorSmartphone size={18} />}
        </span>
        <div className="flex-1">
          <h3 className="font-display font-bold text-base leading-none">{project ? project.name : "Devices"}</h3>
          <p className="text-[11px] text-muted-foreground font-body mt-1">
            {project ? `${visible.length} ${visible.length === 1 ? "device" : "devices"}` : ""}
          </p>
        </div>
        {project && (
        <Popover open={addOpen} onOpenChange={setAddOpen}>
          <PopoverTrigger asChild>
            <button title="Add device"
              className="h-8 w-8 rounded-lg bg-signal/15 text-signal flex items-center justify-center hover:bg-signal/30 transition">
              <Plus size={17} />
            </button>
          </PopoverTrigger>
          <PopoverContent align="end" className="w-96 p-4">
            <form onSubmit={add} className="flex flex-col gap-2">
              <input
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="New device name"
                className="rounded-lg bg-muted/40 border border-border px-3 py-2 text-sm font-body outline-none focus:border-signal/50"
              />
              <select value={kind} onChange={(e) => setKind(e.target.value)}
                className="rounded-lg bg-muted/40 border border-border px-3 py-2 text-xs font-body outline-none">
                {kinds.map((k) => <option key={k.id} value={k.id}>{k.label}</option>)}
              </select>
              <div className="grid grid-cols-2 gap-2 pt-1">
                <input value={make} onChange={(e) => setMake(e.target.value)} placeholder="Make (e.g. Apple)"
                  className="rounded-lg bg-muted/40 border border-border px-2.5 py-1.5 text-xs font-body outline-none focus:border-signal/50" />
                <input value={model} onChange={(e) => setModel(e.target.value)} placeholder="Model (e.g. iPhone 1)"
                  className="rounded-lg bg-muted/40 border border-border px-2.5 py-1.5 text-xs font-body outline-none focus:border-signal/50" />
                <input value={colour} onChange={(e) => setColour(e.target.value)} placeholder="Colour"
                  className="rounded-lg bg-muted/40 border border-border px-2.5 py-1.5 text-xs font-body outline-none focus:border-signal/50" />
                <input value={serial} onChange={(e) => setSerial(e.target.value)} placeholder="Serial number"
                  className="rounded-lg bg-muted/40 border border-border px-2.5 py-1.5 text-xs font-body outline-none focus:border-signal/50" />
              </div>
              <div className="flex items-center gap-2 pt-0.5">
                <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={onFile} />
                <button type="button" onClick={() => fileRef.current?.click()} disabled={uploading}
                  className="flex items-center gap-1.5 rounded-lg bg-muted/40 border border-border px-2.5 py-1.5 text-[11px] font-body text-foreground/80 disabled:opacity-50">
                  {uploading ? <Loader2 size={13} className="animate-spin" /> : <ImageUp size={13} />}
                  {photo ? "Replace photo" : "Upload photo"}
                </button>
                {photo && (
                  <span className="text-[10px] font-body text-signal flex items-center gap-1">
                    <Check size={11} /> Added
                  </span>
                )}
              </div>
              <button type="submit" disabled={busy || !name.trim()}
                className="rounded-lg bg-signal text-background px-3 py-2 text-sm font-display font-semibold disabled:opacity-40 flex items-center justify-center gap-1.5">
                {busy ? <Loader2 size={15} className="animate-spin" /> : <Plus size={15} />} Add device
              </button>
            </form>
          </PopoverContent>
        </Popover>
        )}
      </div>

      {devices === null ? (
        <div className="py-10 flex justify-center text-muted-foreground"><Loader2 className="animate-spin" size={20} /></div>
      ) : !project ? (
        <p className="py-8 text-center text-xs text-muted-foreground font-body">Add or select a project to view its devices</p>
      ) : visible.length === 0 ? (
        <p className="py-8 text-center text-xs text-muted-foreground font-body">No devices linked to {project.name} yet - add one above.</p>
      ) : (
        <DragDropContext onDragEnd={onDragEnd}>
          <Droppable droppableId="devices">
            {(provided) => (
              <ul ref={provided.innerRef} {...provided.droppableProps} className="flex flex-col gap-1.5">
                {ordered.map((d, i) => (
                  <Draggable key={d.id} draggableId={d.id} index={i}>
                    {(drag) => (
                      <li ref={drag.innerRef} {...drag.draggableProps}
                        className="group rounded-lg border border-border bg-muted/30 px-3 py-2.5">
                        <div className="flex items-center gap-3">
                          <span {...drag.dragHandleProps} title="Drag to reorder"
                            className="cursor-grab active:cursor-grabbing text-muted-foreground/50 hover:text-muted-foreground transition shrink-0">
                            <GripVertical size={14} />
                          </span>
                          <button onClick={() => toggleStatus(d)} title="Toggle online/offline"
                            className={cn("h-2.5 w-2.5 rounded-full shrink-0 transition",
                              d.status === "online" ? "bg-signal led-pulse" : "bg-muted-foreground/40 hover:bg-muted-foreground/70")} />
                          <button onClick={() => loadLayout(d)} title="Open this device's OS"
                            className="flex-1 min-w-0 text-left hover:opacity-80 transition">
                            <div className="text-sm font-body truncate">{d.name}</div>
                            <div className="text-[10px] text-muted-foreground font-body uppercase tracking-wider">
                              {d.kind}
                              {[d.make, d.model, d.colour].filter(Boolean).length > 0 ? ` · ${[d.make, d.model, d.colour].filter(Boolean).join(" ")}` : ""}
                            </div>
                          </button>
                          <button onClick={() => setFolderOpen(folderOpen === d.id ? null : d.id)} title="Saved screens & markers"
                            className={cn("transition opacity-60 group-hover:opacity-100", folderOpen === d.id ? "text-amber" : "text-muted-foreground hover:text-foreground")}>
                            <Folder size={15} />
                          </button>
                          <button onClick={() => setDetailsOpen(detailsOpen === d.id ? null : d.id)} title="Device info"
                            className={cn("transition opacity-60 group-hover:opacity-100", hasDetails(d) ? "text-signal" : "text-muted-foreground hover:text-foreground")}>
                            <Info size={15} />
                          </button>
                          <button onClick={() => setConfirmDel(d)} title="Delete device"
                            className="ml-3 pl-2 border-l border-border/60 text-muted-foreground hover:text-alert transition opacity-60 group-hover:opacity-100">
                            <Trash2 size={15} />
                          </button>
                        </div>
                        {detailsOpen === d.id && (
                          <div className="mt-2 pt-2 border-t border-border/60">
                            <DeviceDetails device={d} onChange={refresh} />
                          </div>
                        )}
                        {folderOpen === d.id && (
                          <div className="mt-2 pt-2 border-t border-border/60">
                            <DeviceFolder device={d} />
                          </div>
                        )}
                      </li>
                    )}
                  </Draggable>
                ))}
                {provided.placeholder}
              </ul>
            )}
          </Droppable>
        </DragDropContext>
      )}
      <ConfirmDeleteDialog
        open={Boolean(confirmDel)}
        onOpenChange={(o) => !o && setConfirmDel(null)}
        name={confirmDel?.name}
        onConfirm={() => { remove(confirmDel); setConfirmDel(null); }}
      />
    </div>
  );
}