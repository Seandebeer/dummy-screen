import React, { useEffect, useState } from "react";
import { Check, ChevronLeft, Film, Pencil, Play, Trash2, X } from "lucide-react";
import { deletePhoto, getClip, renameClip } from "@/lib/cameraRoll";

const defaultName = (c) =>
  `Clip ${new Date(c.created).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })}`;

export default function ClipsGallery({ clips, onBack, onChange }) {
  const [viewing, setViewing] = useState(null);
  const [clipUrl, setClipUrl] = useState(null);
  const [draft, setDraft] = useState(null);
  const [confirmDel, setConfirmDel] = useState(false);

  // resolve the recorded blob from IndexedDB while the clip is previewed
  useEffect(() => {
    if (!viewing) return undefined;
    let url = null;
    let dead = false;
    getClip(viewing.id).then((rec) => {
      if (dead || !rec?.blob) return;
      url = URL.createObjectURL(rec.blob);
      setClipUrl(url);
    });
    return () => {
      dead = true;
      if (url) URL.revokeObjectURL(url);
      setClipUrl(null);
    };
  }, [viewing?.id]);

  // keep the preview in step with the roll - closes when the clip is deleted
  useEffect(() => {
    if (!viewing) return;
    const fresh = clips.find((c) => c.id === viewing.id);
    if (fresh) setViewing(fresh);
    else {
      setViewing(null);
      setDraft(null);
      setConfirmDel(false);
    }
  }, [clips]);

  const applyRename = () => {
    if (viewing && draft != null) onChange(renameClip(viewing.id, draft.trim()));
    setDraft(null);
  };
  const removeClip = () => {
    if (!viewing) return;
    onChange(deletePhoto(viewing.id));
    setViewing(null);
    setConfirmDel(false);
  };

  return (
    <div className="relative h-full flex flex-col bg-black text-white">
      <div className="flex items-center justify-between px-3 py-2 border-b border-white/10">
        <button onClick={onBack} className="flex items-center gap-1 text-sm font-body text-amber">
          <ChevronLeft size={16} /> Camera
        </button>
        <div className="text-xs font-body text-white/60">
          {clips.length} clip{clips.length === 1 ? "" : "s"}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto no-scrollbar p-2">
        {clips.length ? (
          <div className="grid grid-cols-2 gap-2">
            {clips.map((c) => (
              <button key={c.id} onClick={() => { setViewing(c); setDraft(null); setConfirmDel(false); }}
                className="text-left">
                <span className="relative block aspect-video overflow-hidden rounded-xl bg-white/5">
                  {c.poster ? (
                    <img src={c.poster} alt={c.name || "Video clip"} className="h-full w-full object-cover" />
                  ) : (
                    <span className="flex h-full items-center justify-center text-white/30"><Film size={20} /></span>
                  )}
                  <span className="absolute inset-0 flex items-center justify-center bg-black/25">
                    <span className="rounded-full bg-black/55 p-1.5"><Play size={12} /></span>
                  </span>
                </span>
                <span className="block truncate pt-1 px-0.5 text-[11px] font-body text-white/75">
                  {c.name?.trim() || defaultName(c)}
                </span>
                <span className="block px-0.5 text-[9px] font-body text-white/35">
                  {new Date(c.created).toLocaleDateString([], { month: "short", day: "numeric" })}
                </span>
              </button>
            ))}
          </div>
        ) : (
          <div className="h-full flex flex-col items-center justify-center gap-2 text-center px-8">
            <Film size={24} className="text-white/30" />
            <div className="text-xs font-body text-white/50">No clips yet - record one from the camera</div>
          </div>
        )}
      </div>

      {viewing && (
        <div className="absolute inset-0 z-10 bg-black flex flex-col">
          <div className="flex items-center justify-between px-3 py-2">
            <button onClick={() => { setViewing(null); setDraft(null); setConfirmDel(false); }}
              className="h-9 w-9 flex items-center justify-center rounded-full bg-white/10"><X size={16} /></button>
            <div className="min-w-0 flex-1 text-center text-[11px] font-body text-white/60 truncate px-2">
              {draft != null ? "Rename clip" : (viewing.name?.trim() || defaultName(viewing))}
            </div>
            <button onClick={() => setConfirmDel(true)}
              className="h-9 w-9 flex items-center justify-center rounded-full bg-white/10 text-red-400"><Trash2 size={16} /></button>
          </div>
          <div className="flex-1 flex items-center justify-center p-2">
            {clipUrl ? (
              <video src={clipUrl} controls autoPlay playsInline className="max-h-full w-full rounded-xl" />
            ) : (
              <div className="text-xs font-body text-white/50">Loading clip…</div>
            )}
          </div>
          <div className="p-3">
            {draft != null ? (
              <div className="flex gap-2">
                <input value={draft} onChange={(e) => setDraft(e.target.value)}
                  onKeyDown={(e) => { if (e.key === "Enter") applyRename(); }}
                  autoFocus placeholder="Clip name" maxLength={60}
                  className="flex-1 min-w-0 rounded-xl bg-white/10 border border-white/20 px-3 py-2 text-sm font-body outline-none focus:border-amber placeholder:text-white/30" />
                <button onClick={applyRename}
                  className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-amber text-black"><Check size={16} /></button>
              </div>
            ) : (
              <button onClick={() => setDraft(viewing.name || "")}
                className="flex w-full items-center justify-center gap-1.5 rounded-xl bg-white/10 py-2.5 text-sm font-body text-white/85">
                <Pencil size={14} /> Rename clip
              </button>
            )}
          </div>

          {confirmDel && (
            <div className="absolute inset-0 z-20 flex items-center justify-center bg-black/70 px-8">
              <div className="w-full rounded-2xl bg-[#1c1c1e] p-5 text-center">
                <h3 className="font-body text-[15px] font-semibold">Delete this clip?</h3>
                <p className="mt-1 text-[12px] font-body text-white/55">
                  "{viewing.name?.trim() || defaultName(viewing)}" is removed from the roll. This cannot be undone.
                </p>
                <div className="mt-4 flex flex-col gap-2">
                  <button onClick={removeClip} className="rounded-xl bg-[#FF453A] py-2.5 text-sm font-semibold">Delete clip</button>
                  <button onClick={() => setConfirmDel(false)} className="rounded-xl bg-white/10 py-2.5 text-sm font-body text-white/80">Cancel</button>
                </div>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}