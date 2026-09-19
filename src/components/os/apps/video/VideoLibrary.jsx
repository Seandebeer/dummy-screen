import React, { useRef, useState } from "react";
import { ArrowDown, ArrowUp, Film, Loader2, Play, Plus, Trash2 } from "lucide-react";
import { MAX_DURATION, MAX_VIDEOS, deleteVideo, fmtDur, grabThumbs, importVideo, updateVideo } from "@/lib/videoStore";

export default function VideoLibrary({ videos, reload, onPlay }) {
  const fileRef = useRef(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  const onPick = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    if (videos.length >= MAX_VIDEOS) { setError("Queue is full - remove a video first"); return; }
    setBusy(true);
    setError(null);
    try {
      const nextOrder = videos.length ? (videos[videos.length - 1].order ?? videos.length - 1) + 1 : 0;
      const rec = await importVideo(file, nextOrder);
      reload();
      // filmstrip thumbnails build in the background so the import is instant
      const url = URL.createObjectURL(file);
      grabThumbs(url, rec.duration, 8)
        .then((thumbs) => (thumbs.length ? updateVideo(rec.id, { thumbs }) : null))
        .then(reload)
        .catch(() => {})
        .finally(() => URL.revokeObjectURL(url));
    } catch (err) {
      setError(err.message || "Could not add this video");
    }
    setBusy(false);
  };

  const move = async (i, dir) => {
    const j = i + dir;
    if (j < 0 || j >= videos.length) return;
    const next = [...videos];
    [next[i], next[j]] = [next[j], next[i]];
    await Promise.all(next.map((v, k) => updateVideo(v.id, { order: k })));
    reload();
  };

  const remove = async (id) => {
    await deleteVideo(id);
    reload();
  };

  return (
    <div className="h-full overflow-y-auto no-scrollbar bg-[#0b0b0f] p-3 text-white">
      <div className="mb-3 flex items-center justify-between">
        <div>
          <div className="font-display text-sm font-bold">Videos</div>
          <div className="text-[10px] font-body text-white/40">
            {videos.length} of {MAX_VIDEOS} slots · max {MAX_DURATION / 60} min each
          </div>
        </div>
        <button onClick={() => onPlay(0)} disabled={!videos.length}
          className="flex items-center gap-1.5 rounded-lg border border-amber/40 bg-amber/10 px-3 py-2 text-[11px] font-body font-semibold text-amber disabled:opacity-40">
          <Play size={12} /> Play queue
        </button>
      </div>

      <button onClick={() => fileRef.current?.click()} disabled={busy || videos.length >= MAX_VIDEOS}
        className="flex w-full items-center justify-center gap-2 rounded-xl border border-dashed border-white/20 bg-white/[0.03] py-4 text-[11px] font-body text-white/50 transition hover:border-white/40 disabled:opacity-40">
        {busy
          ? <><Loader2 size={14} className="animate-spin" /> Adding video...</>
          : <><Plus size={14} /> Add video from this device</>}
      </button>
      <input ref={fileRef} type="file" accept="video/*" className="hidden" onChange={onPick} />
      {error && <p className="mt-2 text-center text-[10px] font-body text-alert">{error}</p>}

      {!videos.length ? (
        <div className="mt-10 flex flex-col items-center gap-2 text-white/35">
          <Film size={28} />
          <p className="text-[11px] font-body">No videos yet - add up to five to build the queue</p>
        </div>
      ) : (
        <ul className="mt-3 flex flex-col gap-2">
          {videos.map((v, i) => (
            <li key={v.id} className="flex items-center gap-2.5 rounded-xl border border-white/10 bg-white/[0.04] p-2">
              <button onClick={() => onPlay(i)} className="relative h-12 w-20 shrink-0 overflow-hidden rounded-lg bg-black">
                {v.thumbs?.[0]
                  ? <img src={v.thumbs[0]} alt="" className="h-full w-full object-cover" />
                  : <span className="flex h-full w-full items-center justify-center text-white/30"><Film size={16} /></span>}
                <span className="absolute bottom-0 right-0 rounded-tl bg-black/80 px-1 text-[8px] font-mono text-white/80">
                  {fmtDur((v.trimEnd ?? v.duration) - (v.trimStart || 0))}
                </span>
              </button>
              <button onClick={() => onPlay(i)} className="min-w-0 flex-1 text-left">
                <div className="truncate text-[12px] font-body text-white">{v.name}</div>
                <div className="mt-0.5 flex items-center gap-1.5 text-[9px] font-body text-white/40">
                  <span>{i + 1} in queue</span>
                  {(v.trimStart > 0.1 || v.trimEnd < v.duration - 0.1) && <span className="rounded bg-amber/20 px-1 text-amber">trimmed</span>}
                  {v.loop && <span className="rounded bg-signal/20 px-1 text-signal">loop</span>}
                  {v.aspect && v.aspect !== "fit" && <span className="rounded bg-white/10 px-1">{v.aspect}</span>}
                </div>
              </button>
              <div className="flex flex-col">
                <button onClick={() => move(i, -1)} disabled={i === 0} className="p-0.5 text-white/40 hover:text-white disabled:opacity-20"><ArrowUp size={12} /></button>
                <button onClick={() => move(i, 1)} disabled={i === videos.length - 1} className="p-0.5 text-white/40 hover:text-white disabled:opacity-20"><ArrowDown size={12} /></button>
              </div>
              <button onClick={() => remove(v.id)} className="p-1.5 text-white/40 hover:text-alert"><Trash2 size={13} /></button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}