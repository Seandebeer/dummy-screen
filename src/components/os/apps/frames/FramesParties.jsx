import React from "react";
import { Plus, X } from "lucide-react";
import { Image } from "@/components/ui/image";
import { Avatar, Editable, UploadButton, fmtNum } from "../social/SocialBits";
import { nextStockPhoto } from "@/lib/osSocial";

// watch parties - live co-watching rooms, each with a 16:9 screen
export default function FramesParties({ parties, editing, patch, remove, add, onJoin }) {
  return (
    <div className="h-full overflow-y-auto no-scrollbar bg-black px-3 pt-3">
      <div className="flex items-center justify-between pb-2">
        <span className="text-[10px] font-semibold uppercase tracking-[0.18em] text-white/50">Watch parties</span>
        {editing && (
          <button onClick={add} className="flex items-center gap-1 rounded-full bg-white/15 px-2.5 py-1 text-[10px] font-semibold text-white">
            <Plus size={12} /> Add party
          </button>
        )}
      </div>
      {parties.length === 0 && (
        <p className="pt-10 text-center text-xs text-white/40">No watch parties right now.</p>
      )}
      <div className="space-y-3 pb-4">
        {parties.map((p) => (
          <div key={p.id} className="overflow-hidden rounded-2xl bg-[#1c1c1e]">
            <button onClick={() => onJoin(p.id)} className="relative w-full">
              {p.video ? (
                <video src={p.video} muted playsInline className="aspect-video w-full object-contain" />
              ) : (
                <Image src={p.poster} alt="" className="aspect-video w-full" fittingType="fill" />
              )}
              <span className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/5 to-black/20" />
              <span className="absolute left-2 top-2 flex items-center gap-1.5 rounded-full bg-[#FF3B30]/85 px-2 py-0.5 text-[9px] font-bold tracking-wider text-white">
                <span className="h-1.5 w-1.5 rounded-full bg-white led-pulse" /> LIVE
              </span>
              <span className="absolute inset-x-2.5 bottom-2 flex items-center gap-2">
                <Avatar name={p.host} hue={p.hostHue} size={22} className="border border-black/40" />
                <span className="truncate text-[11px] font-semibold text-white">{p.host} is hosting</span>
                <span className="ml-auto shrink-0 text-[10px] font-medium text-white/80">{fmtNum(p.viewers)} watching</span>
              </span>
            </button>
            <div className="flex items-center gap-2 p-2.5">
              <Editable editing={editing} value={p.title} onChange={(v) => patch(p.id, { title: v })}
                className="min-w-0 flex-1 truncate text-[12px] font-semibold text-white" inputClass="border-white/30 bg-white/10 text-white" />
              <button onClick={() => onJoin(p.id)}
                className="shrink-0 rounded-full bg-gradient-to-r from-[#E56E42] to-[#F1865F] px-3 py-1 text-[11px] font-semibold text-white">
                Join
              </button>
            </div>
            {editing && (
              <div className="flex flex-wrap items-center gap-1.5 border-t border-white/10 px-2.5 py-1.5 text-[10px]">
                <button onClick={() => patch(p.id, { poster: nextStockPhoto(p.poster), video: "" })}
                  className="rounded-full bg-white/15 px-2 py-0.5 font-semibold text-white">Swap poster</button>
                <UploadButton accept="video/*,image/*" label="Upload"
                  onFile={(url, type) => String(type || "").startsWith("video")
                    ? patch(p.id, { video: url })
                    : patch(p.id, { poster: url, video: "" })} />
                <Editable editing={editing} type="number" value={p.viewers} onChange={(v) => patch(p.id, { viewers: v })}
                  className="w-14 rounded bg-white/10 px-1 text-center text-[11px]" inputClass="border-white/30 bg-white/10 text-white" />
                <button onClick={() => remove(p.id)} aria-label="Delete party"
                  className="ml-auto flex h-6 w-6 items-center justify-center rounded-full bg-white/15 text-white">
                  <X size={12} />
                </button>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}