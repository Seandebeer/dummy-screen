import React from "react";
import { Heart, MessageCircle, Play, Plus, Share2, X } from "lucide-react";
import { Image } from "@/components/ui/image";
import { Avatar, Editable, UploadButton, fmtNum } from "../social/SocialBits";
import { nextStockPhoto } from "@/lib/osSocial";

// the shared 16:9 snap feed - used by both the Shorts and the Discover
// tabs so the two feeds look identical. Every video renders letterboxed
// into a 16:9 frame.
export default function FramesFeed({ posts, editing, patch, remove, addStock, upload, onPlay, emptyNote }) {
  return (
    <div className="h-full snap-y snap-mandatory overflow-y-auto no-scrollbar">
      {editing && (
        <div className="flex h-full w-full snap-start flex-col items-center justify-center gap-3">
          <button onClick={addStock} className="flex flex-col items-center gap-1.5 text-[13px] font-semibold text-white/70">
            <Plus size={26} /> Stock video
          </button>
          <UploadButton accept="video/*,image/*" label="Upload video" onFile={upload} className="px-4 py-2 text-[12px]" />
        </div>
      )}
      {posts.map((p) => (
        <div key={p.id} className="flex h-full w-full snap-start flex-col items-center justify-center px-3">
          <button onClick={() => onPlay(p.id)} className="relative aspect-video w-full overflow-hidden rounded-2xl bg-[#1c1c1e]">
            {p.video ? (
              <video src={p.video} muted loop autoPlay playsInline className="h-full w-full object-contain" />
            ) : p.poster ? (
              <Image src={p.poster} alt="" className="h-full w-full" fittingType="fill" />
            ) : (
              <span className="block h-full w-full" />
            )}
            <span className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/10 to-black/25" />
            <span className="absolute left-2 top-2 rounded-full bg-black/55 px-2 py-0.5 text-[9px] font-semibold tracking-[0.18em] backdrop-blur">16:9</span>
            <span className="absolute right-2 top-2 rounded-md bg-black/65 px-1.5 py-0.5 text-[10px] font-semibold">{p.duration}</span>
            <span className="absolute inset-x-2.5 bottom-2.5 flex items-center gap-2 text-left">
              <Avatar name={p.channel} hue={p.chHue} size={26} />
              <span className="min-w-0 flex-1">
                <span className="block truncate text-[11px] font-semibold text-white">{p.channel}</span>
                <span className="block text-[10px] text-white/70">{fmtNum(p.views)} views · {p.age}</span>
              </span>
              <Play size={18} className="shrink-0 text-white drop-shadow" />
            </span>
          </button>

          <div className="mt-2 flex w-full items-center gap-3">
            <Editable editing={editing} value={p.title} onChange={(v) => patch(p.id, { title: v })}
              className="min-w-0 flex-1 truncate text-[13px] font-semibold" inputClass="border-white/30 bg-white/10 text-white" />
            <div className="flex shrink-0 items-center gap-3.5">
              <button onClick={() => patch(p.id, { liked: !p.liked, likes: p.likes + (p.liked ? -1 : 1) })}
                className="flex flex-col items-center gap-0.5">
                <Heart size={19} className={p.liked ? "fill-[#E56E42] text-[#E56E42]" : "text-white"} />
                <span className="text-[9px] font-semibold">{fmtNum(p.likes)}</span>
              </button>
              <button onClick={() => patch(p.id, { comments: p.comments + 1 })} className="flex flex-col items-center gap-0.5">
                <MessageCircle size={19} className="text-white" />
                <span className="text-[9px] font-semibold">{fmtNum(p.comments)}</span>
              </button>
              <button onClick={() => patch(p.id, { shares: (p.shares || 0) + 1 })} className="flex flex-col items-center gap-0.5">
                <Share2 size={19} className="text-white" />
                <span className="text-[9px] font-semibold">{fmtNum(p.shares || 0)}</span>
              </button>
            </div>
          </div>

          {editing && (
            <div className="mt-2 flex w-full flex-wrap items-center gap-1.5 rounded-xl bg-white/10 px-2.5 py-1.5 text-[10px]">
              <button onClick={() => patch(p.id, { poster: nextStockPhoto(p.poster), video: "" })}
                className="rounded-full bg-white/15 px-2 py-0.5 font-semibold text-white">Swap poster</button>
              <UploadButton accept="video/*,image/*" label="Upload"
                onFile={(url, type) => String(type || "").startsWith("video")
                  ? patch(p.id, { video: url })
                  : patch(p.id, { poster: url, video: "" })} />
              <Editable editing={editing} type="number" value={p.views} onChange={(v) => patch(p.id, { views: v })}
                className="w-14 rounded bg-white/10 px-1 text-center text-[11px]" inputClass="border-white/30 bg-white/10 text-white" />
              <Editable editing={editing} type="number" value={p.likes} onChange={(v) => patch(p.id, { likes: v })}
                className="w-14 rounded bg-white/10 px-1 text-center text-[11px]" inputClass="border-white/30 bg-white/10 text-white" />
              <button onClick={() => remove(p.id)} aria-label="Delete video"
                className="ml-auto flex h-6 w-6 items-center justify-center rounded-full bg-white/15 text-white">
                <X size={12} />
              </button>
            </div>
          )}
        </div>
      ))}
      {!editing && posts.length === 0 && (
        <div className="flex h-full flex-col items-center justify-center text-[13px] text-white/50">
          <span>{emptyNote || "No videos here yet."}</span>
        </div>
      )}
    </div>
  );
}