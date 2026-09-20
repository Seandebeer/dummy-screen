import React from "react";
import { Image } from "@/components/ui/image";
import { Avatar, Editable, fmtNum } from "../social/SocialBits";

// my channel - banner, profile stats and a grid of this channel's 16:9 videos
export default function FramesChannel({ profile, videos, editing, patchProfile, onPlay }) {
  return (
    <div className="h-full overflow-y-auto no-scrollbar bg-black">
      <div className="relative h-24 bg-gradient-to-r from-[#E56E42] to-[#F1865F]">
        <span className="absolute inset-0 bg-black/20" />
      </div>
      <div className="-mt-8 flex flex-col items-center px-4">
        <Avatar name={profile.name} hue="#E56E42" size={72} className="border-[3px] border-black" />
        <div className="pt-2 text-[15px] font-semibold text-white">
          <Editable editing={editing} value={profile.name} onChange={(v) => patchProfile({ name: v })} />
        </div>
        <div className="text-[12px] text-white/55">
          <Editable editing={editing} value={profile.handle} onChange={(v) => patchProfile({ handle: v })} />
        </div>
        <div className="flex items-center gap-6 pt-3 text-center">
          <div>
            <div className="text-[14px] font-bold text-white">
              <Editable editing={editing} type="number" value={profile.subscribers} onChange={(v) => patchProfile({ subscribers: v })} />
            </div>
            <div className="text-[10px] text-white/50">Subscribers</div>
          </div>
          <div>
            <div className="text-[14px] font-bold text-white">{videos.length}</div>
            <div className="text-[10px] text-white/50">Videos</div>
          </div>
        </div>
      </div>
      <div className="px-3 pt-4">
        <div className="pb-2 text-[10px] font-semibold uppercase tracking-[0.18em] text-white/50">My videos</div>
        {videos.length === 0 && (
          <p className="pt-6 text-center text-xs text-white/40">No videos on this channel yet.</p>
        )}
        <div className="grid grid-cols-2 gap-3 pb-4">
          {videos.map((p) => (
            <button key={p.id} onClick={() => onPlay(p.id)} className="text-left">
              <span className="relative block overflow-hidden rounded-xl bg-[#1c1c1e]">
                {p.video ? (
                  <video src={p.video} muted playsInline className="aspect-video w-full object-contain" />
                ) : p.poster ? (
                  <Image src={p.poster} alt="" className="aspect-video w-full" fittingType="fill" />
                ) : (
                  <span className="block aspect-video w-full" />
                )}
                <span className="absolute bottom-1 right-1 rounded bg-black/70 px-1 text-[9px] font-semibold text-white">{p.duration}</span>
              </span>
              <span className="mt-1 line-clamp-2 block text-[11px] font-semibold leading-snug text-white">{p.title}</span>
              <span className="block text-[10px] text-white/45">{fmtNum(p.views)} views</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}