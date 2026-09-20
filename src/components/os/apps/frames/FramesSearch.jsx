import React, { useState } from "react";
import { Search } from "lucide-react";
import { Image } from "@/components/ui/image";
import { fmtNum } from "../social/SocialBits";

// search across every Frames video (shorts + discover)
export default function FramesSearch({ posts, onPlay }) {
  const [q, setQ] = useState("");
  const query = q.trim().toLowerCase();
  const results = query
    ? posts.filter((p) => `${p.title} ${p.channel}`.toLowerCase().includes(query))
    : posts;

  return (
    <div className="flex h-full flex-col bg-black">
      <div className="px-3 pt-3">
        <div className="flex items-center gap-2 rounded-full border border-white/15 bg-white/10 px-3 py-1.5">
          <Search size={13} className="shrink-0 text-white/50" />
          <input autoFocus value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search videos"
            className="w-full bg-transparent text-[12px] text-white placeholder-white/40 outline-none" />
        </div>
      </div>
      <div className="flex-1 overflow-y-auto no-scrollbar px-3 pt-3">
        {results.length === 0 && (
          <p className="pt-10 text-center text-xs text-white/40">No videos match that search</p>
        )}
        {results.map((p) => (
          <button key={p.id} onClick={() => onPlay(p.id)}
            className="flex w-full items-start gap-2.5 border-b border-white/5 py-2.5 text-left">
            <span className="relative w-28 shrink-0 overflow-hidden rounded-lg bg-[#1c1c1e]">
              {p.video ? (
                <video src={p.video} muted playsInline className="aspect-video w-full object-contain" />
              ) : p.poster ? (
                <Image src={p.poster} alt="" className="aspect-video w-full" fittingType="fill" />
              ) : (
                <span className="block aspect-video w-full" />
              )}
              <span className="absolute bottom-1 right-1 rounded bg-black/70 px-1 text-[9px] font-semibold text-white">{p.duration}</span>
            </span>
            <span className="min-w-0 flex-1">
              <span className="line-clamp-2 block text-[12px] font-semibold leading-snug text-white">{p.title}</span>
              <span className="mt-0.5 block truncate text-[10px] text-white/50">{p.channel}</span>
              <span className="block text-[10px] text-white/40">{fmtNum(p.views)} views · {p.age}</span>
            </span>
          </button>
        ))}
      </div>
    </div>
  );
}