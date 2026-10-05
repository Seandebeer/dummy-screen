import React, { useRef, useState } from "react";
import { Link } from "react-router-dom";
import { ArrowLeft, Check, Eye, EyeOff, ImagePlus, Lock, Palette, Plus, RotateCcw, RotateCw, Save, Shapes, SlidersHorizontal, Target, Upload, X } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Slider } from "@/components/ui/slider";
import CustomColour from "@/components/vfx/CustomColour";
import { OverlayControl } from "@/components/vfx/OverlayImage";
import { compositeMarks, trackingMarks, vfxColors } from "@/lib/vfxData";
import { cn } from "@/lib/utils";

const glass = "bg-black/55 text-white border-white/15 shadow-2xl backdrop-blur-xl";
const btn = "flex h-9 w-9 items-center justify-center rounded-full transition hover:bg-white/15";
const divider = "h-5 w-px bg-white/15 mx-0.5";
const panel = "border-white/15 bg-black/80 text-white backdrop-blur-xl shadow-2xl";

const MARKER_KINDS = [
  { id: "cross", label: "Cross" },
  { id: "circles", label: "Targets" },
  { id: "squares", label: "Squares" },
  { id: "brackets", label: "Brackets" },
  { id: "diamond", label: "Diamond" },
  { id: "triangle", label: "Triangle" },
  ...compositeMarks,
];

const MARK_COLORS = [
  { id: "white", hex: "#FFFFFF" },
  { id: "black", hex: "#000000" },
  { id: "red", hex: "#FF3B30" },
  { id: "green", hex: "#34C759" },
  { id: "magenta", hex: "#FF2D92" },
  { id: "cyan", hex: "#32ADE6" },
  { id: "yellow", hex: "#FFD60A" },
];

export default function StageToolbar({
  colorId, marksId, isPoint, marks, addKind, light,
  onSelectAddKind, onRotateAll, onLock,
  onSelectColor, onSelectMarks, onScale, onThick, onMarkColor, onBgColor, onBgImage,
  onOverlayChange, onAdd, onSave, onReset,
}) {
  const fileRef = useRef(null);
  const [uploading, setUploading] = useState(false);

  const handleUpload = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setUploading(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
      onBgImage(file_url);
    } catch {}
    setUploading(false);
  };
  return (
    <>
      {/* lock - same position & style as the UI markers lock */}
      <button onClick={onLock}
        className={cn("absolute top-2 right-2 z-40 flex items-center gap-1 rounded-full border px-2.5 py-1 text-[10px] font-body transition", light ? "border-black/10 text-black/50 hover:text-black" : "border-white/10 text-white/50 hover:text-white")}>
        <Lock size={11} /> Lock
      </button>

      <div className="absolute inset-x-0 bottom-6 z-40 flex flex-col items-center gap-3 px-4">
        {/* single consolidated tool bar */}
        <div className={cn("flex flex-wrap items-center justify-center gap-0.5 rounded-full border p-1.5 max-w-[92vw]", glass)}>
          <Link to="/" title="Exit stage" className={btn}><ArrowLeft size={16} /></Link>
          <span className={divider} />

          <Popover>
            <PopoverTrigger asChild>
              <button title="Colour" className={btn}><Palette size={16} /></button>
            </PopoverTrigger>
            <PopoverContent side="top" align="start" className={cn("w-44 p-2", panel)}>
              <p className="mb-1 px-2 text-[9px] font-body uppercase tracking-[0.2em] text-white/50">Background</p>
              {marksId === "checkerboard" ? (
                <p className="px-2 py-1 text-[10px] font-body text-white/60">Black &amp; white only</p>
              ) : (<>
                {vfxColors.map((c) => (
                  <button key={c.id} onClick={() => onSelectColor(c.id)}
                    className="flex w-full items-center gap-2.5 rounded-lg px-2 py-1.5 text-[11px] font-body transition hover:bg-white/10">
                    <span className="h-4 w-4 rounded-full border border-white/25" style={{ background: c.hex }} />
                    {c.label}
                    {colorId === c.id && <Check size={12} className="ml-auto text-amber" />}
                  </button>
                ))}
                <CustomColour value={marks.bgColor} onChange={onBgColor} />
                {marks.bgColor && (
                  <button type="button" onClick={() => onBgColor(null)}
                    className="flex w-full items-center gap-2.5 rounded-lg px-2 py-1.5 text-[11px] font-body transition hover:bg-white/10">
                    <X size={14} /> Clear custom colour
                  </button>
                )}
              </>)}
              {marksId !== "checkerboard" && marksId !== "none" && (
                <div className="mt-2 border-t border-white/10 pt-2">
                  <p className="mb-1.5 px-2 text-[9px] font-body uppercase tracking-[0.2em] text-white/50">Marks</p>
                  <div className="flex flex-wrap items-center gap-1.5 px-2">
                    <button onClick={() => onMarkColor(null)} title="Auto (contrast with background)"
                      className={cn("h-5 w-5 rounded-full border border-white/30 transition hover:bg-white/15",
                        !marks.markColor && "ring-2 ring-amber ring-offset-1 ring-offset-black")}
                      style={{ background: "conic-gradient(#FFFFFF 0turn 0.5turn, #000000 0.5turn 1turn)" }} />
                    {MARK_COLORS.map((c) => (
                      <button key={c.id} onClick={() => onMarkColor(c.hex)} title={c.id}
                        className={cn("h-5 w-5 rounded-full border border-white/25 transition hover:bg-white/15",
                          marks.markColor === c.hex && "ring-2 ring-amber ring-offset-1 ring-offset-black")}
                        style={{ background: c.hex }} />
                    ))}
                  </div>
                  <CustomColour label="Custom mark colour" value={marks.markColor} onChange={onMarkColor} />
                </div>
              )}
              {marksId !== "checkerboard" && (
                <div className="mt-2 border-t border-white/10 pt-2">
                  <p className="mb-1 px-2 text-[9px] font-body uppercase tracking-[0.2em] text-white/50">Photo</p>
                  <button disabled={uploading} onClick={() => fileRef.current?.click()}
                    className="flex w-full items-center gap-2.5 rounded-lg px-2 py-1.5 text-[11px] font-body transition hover:bg-white/10 disabled:opacity-50">
                    <Upload size={14} /> {uploading ? "Uploading…" : marks.bgImage ? "Replace photo" : "Upload photo"}
                  </button>
                  {marks.bgImage && (
                    <button onClick={() => onBgImage(null)}
                      className="flex w-full items-center gap-2.5 rounded-lg px-2 py-1.5 text-[11px] font-body transition hover:bg-white/10">
                      <X size={14} /> Remove photo
                    </button>
                  )}
                  <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={handleUpload} />
                </div>
              )}
            </PopoverContent>
          </Popover>

          <Popover>
            <PopoverTrigger asChild>
              <button title="Tracking marks" className={btn}><Shapes size={16} /></button>
            </PopoverTrigger>
            <PopoverContent side="top" className={cn("w-36 p-1.5", panel)}>
              {trackingMarks.map((m) => (
                <button key={m.id} onClick={() => onSelectMarks(m.id)}
                  className="flex w-full items-center justify-between rounded-lg px-2.5 py-1.5 text-[10px] font-body uppercase tracking-wider transition hover:bg-white/10">
                  {m.name}
                  {marksId === m.id && <Check size={12} className="text-amber" />}
                </button>
              ))}
            </PopoverContent>
          </Popover>

          {marksId !== "none" && (
            <Popover>
              <PopoverTrigger asChild>
                <button title="Size & thickness" className={btn}><SlidersHorizontal size={16} /></button>
              </PopoverTrigger>
              <PopoverContent side="top" align="end" className={cn("w-56 p-4", panel)}>
                <div className="mb-1 flex items-center justify-between text-[9px] font-body uppercase tracking-[0.2em]">
                  <span>Size</span>
                  <span className="text-white/60">{Number(marks.scale.toFixed(2))}×</span>
                </div>
                <Slider value={[marks.scale]} min={0.5} max={3} step={0.25} onValueChange={([v]) => onScale(v)} />
                {marksId !== "checkerboard" && (
                  <div className="mt-4">
                    <div className="mb-1 flex items-center justify-between text-[9px] font-body uppercase tracking-[0.2em]">
                      <span>Thickness</span>
                      <span className="text-white/60">{Number(marks.thickness.toFixed(2))}×</span>
                    </div>
                    <Slider value={[marks.thickness]} min={0.5} max={3} step={0.25} onValueChange={([v]) => onThick(v)} />
                  </div>
                )}
              </PopoverContent>
            </Popover>
          )}
          <Popover>
            <PopoverTrigger asChild>
              <button title="Image overlay" className={btn}><ImagePlus size={16} /></button>
            </PopoverTrigger>
            <PopoverContent side="top" className={cn("w-56 p-2", panel)}>
              <OverlayControl overlay={marks.overlay} onChange={onOverlayChange} />
            </PopoverContent>
          </Popover>
          {marks.overlay?.url && (
            <button title={marks.overlay.hidden ? "Show image" : "Hide image"}
              onClick={() => onOverlayChange({ hidden: !marks.overlay.hidden })}
              className={btn}>
              {marks.overlay.hidden ? <EyeOff size={16} /> : <Eye size={16} />}
            </button>
          )}
          <span className={divider} />

          {isPoint && (
            <>
              <Popover>
                <PopoverTrigger asChild>
                  <button title="Marker type to add" className={btn}><Target size={16} /></button>
                </PopoverTrigger>
                <PopoverContent side="top" className={cn("w-36 p-1.5", panel)}>
                  {MARKER_KINDS.map((k) => (
                    <button key={k.id} onClick={() => onSelectAddKind(k.id)}
                      className="flex w-full items-center justify-between rounded-lg px-2.5 py-1.5 text-[10px] font-body uppercase tracking-wider transition hover:bg-white/10">
                      {k.label}
                      {addKind === k.id && <Check size={12} className="text-amber" />}
                    </button>
                  ))}
                </PopoverContent>
              </Popover>
              <button title="Add marker" onClick={onAdd} className={btn}><Plus size={16} /></button>
              <button title="Rotate all markers 45°" onClick={onRotateAll} className={btn}><RotateCw size={16} /></button>
            </>
          )}
          <button title="Save screen" onClick={onSave} className={btn}><Save size={16} /></button>
          {marksId !== "none" && (
            <button title="Reset" onClick={onReset} className={btn}><RotateCcw size={16} /></button>
          )}
        </div>
      </div>
    </>
  );
}