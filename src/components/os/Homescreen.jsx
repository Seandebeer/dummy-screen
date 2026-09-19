import React, { useState, useRef } from "react";
import { LayoutGrid, Image as ImageIcon, Sun, Moon, Loader2 } from "lucide-react";
import { allApps } from "@/lib/osApps";
import { bgPresets } from "@/hooks/useOsConfig";
import IconTile from "./IconTile";
import AppLibrary from "./AppLibrary";
import BackgroundPanel from "./BackgroundPanel";
import ClockEditor from "./ClockEditor";
import { base44 } from "@/api/base44Client";
import { cn } from "@/lib/utils";

export default function Homescreen({ config, update, onOpen }) {
  const [library, setLibrary] = useState(false);
  const [bgPanel, setBgPanel] = useState(false);
  const [clockEdit, setClockEdit] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState(false);
  const fileRef = useRef(null);
  const dragIndex = useRef(null);
  const [draggingId, setDraggingId] = useState(null);

  const light = config.theme === "light";
  const now = new Date();
  const time = config.clock.mode === "custom" && config.clock.time
    ? config.clock.time
    : now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  const date = config.clock.mode === "custom" && config.clock.date
    ? config.clock.date
    : now.toLocaleDateString([], { weekday: "long", month: "long", day: "numeric" });

  const apps = config.order.map((id) => allApps.find((a) => a.id === id)).filter(Boolean);
  const hasImage = config.background.type === "image" && config.background.url;
  const preset = bgPresets.find((p) => p.id === (config.background.preset || "default")) || bgPresets[0];

  const backgroundStyle = hasImage
    ? { backgroundImage: `url(${config.background.url})`, backgroundSize: "cover", backgroundPosition: "center" }
    : { background: preset[light ? "light" : "dark"] };

  // tap on empty background to upload an image
  const onBackgroundTap = (e) => {
    if (e.target.closest("button, a, input, select, textarea, label")) return;
    fileRef.current?.click();
  };

  const onFile = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setUploading(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
      update({ background: { type: "image", preset: preset.id, url: file_url } });
      setUploadError(false);
    } catch {
      setUploadError(true);
    } finally {
      setUploading(false);
    }
  };

  const handleDragEnter = (id) => {
    const from = dragIndex.current;
    if (from === null) return;
    const to = config.order.indexOf(id);
    if (from === to) return;
    const next = [...config.order];
    const [moved] = next.splice(from, 1);
    next.splice(to, 0, moved);
    dragIndex.current = to;
    update({ order: next });
  };

  const toggleApp = (id) => {
    update({
      order: config.order.includes(id)
        ? config.order.filter((x) => x !== id)
        : [...config.order, id],
    });
  };

  const pill = cn("flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-[10px] font-body uppercase tracking-wider backdrop-blur transition",
    light ? "bg-black/10 border-black/15 text-black/70 hover:bg-black/20" : "bg-white/10 border-white/15 text-white/80 hover:bg-white/20");

  return (
    <div className="h-full flex flex-col relative overflow-hidden" style={backgroundStyle} onClick={onBackgroundTap}>
      {!hasImage && <div className="grid-backdrop absolute inset-0 opacity-30 pointer-events-none" />}
      <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={onFile} />

      {/* clock — tap to edit */}
      <div className={cn("relative flex flex-col items-center pt-9 pb-2", light ? "text-black/85" : "text-white")}>
        <button onClick={() => setClockEdit(true)} className="flex flex-col items-center">
          <div className="font-display text-6xl font-bold tracking-tight">{time}</div>
          <div className="text-sm mt-1 opacity-60">{date}</div>
        </button>
      </div>

      {clockEdit && (
        <div className="absolute top-28 inset-x-0 z-20 px-4">
          <ClockEditor clock={config.clock}
            onSave={(clock) => { update({ clock }); setClockEdit(false); }}
            onClose={() => setClockEdit(false)} />
        </div>
      )}

      {/* app grid */}
      <div className="relative flex-1 overflow-y-auto no-scrollbar" onDragOver={(e) => e.preventDefault()}>
        {apps.length === 0 ? (
          <p className={cn("pt-12 text-center text-xs font-body", light ? "text-black/40" : "text-white/40")}>No apps — open Apps to add some</p>
        ) : (
          <div className="grid grid-cols-4 gap-y-5 gap-x-3 px-5 content-start pt-3 pb-4">
            {apps.map((a) => (
              <button key={a.id} draggable
                onDragStart={() => { dragIndex.current = config.order.indexOf(a.id); setDraggingId(a.id); }}
                onDragEnter={() => handleDragEnter(a.id)}
                onDragOver={(e) => e.preventDefault()}
                onDragEnd={() => { dragIndex.current = null; setDraggingId(null); }}
                onClick={() => onOpen(a.id)}
                className={cn("flex flex-col items-center gap-1.5 active:scale-95 transition select-none",
                  draggingId === a.id && "opacity-40")}>
                <IconTile app={a} />
                <span className={cn("text-[11px]", light ? "text-black/80" : "text-white/80")}>{a.label}</span>
              </button>
            ))}
          </div>
        )}
      </div>

      {/* editor toolbar */}
      <div className="relative flex justify-center gap-2 pb-3">
        <button onClick={() => setLibrary(true)} className={pill}><LayoutGrid size={13} /> Apps</button>
        <button onClick={() => setBgPanel(true)} className={pill}>
          {uploading ? <Loader2 size={13} className="animate-spin" /> : <ImageIcon size={13} />} Background
        </button>
        <button onClick={() => update({ theme: light ? "dark" : "light" })} className={pill}>
          {light ? <Moon size={13} /> : <Sun size={13} />} {light ? "Dark" : "Light"}
        </button>
      </div>
      {uploadError && (
        <div className="relative text-center text-[10px] text-[#FF453A] font-body pb-1">image upload failed — try again</div>
      )}
      <div className={cn("relative flex justify-center pb-4 text-[10px] font-body tracking-widest uppercase",
        light ? "text-black/30" : "text-white/30")}>
        {hasImage ? "tap background to replace image" : "tap background to set image"} · drag icons to rearrange
      </div>

      {library && <AppLibrary order={config.order} onToggle={toggleApp} onClose={() => setLibrary(false)} />}
      {bgPanel && (
        <BackgroundPanel
          background={config.background}
          uploading={uploading}
          onPickPreset={(id) => update({ background: { type: "preset", preset: id, url: "" } })}
          onUpload={() => fileRef.current?.click()}
          onRemoveImage={() => update({ background: { type: "preset", preset: preset.id, url: "" } })}
          onClose={() => setBgPanel(false)}
        />
      )}
    </div>
  );
}