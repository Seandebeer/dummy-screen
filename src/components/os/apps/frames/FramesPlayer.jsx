import React from "react";
import { ChevronLeft, Heart, MessageCircle, Radio, Share2 } from "lucide-react";
import { Image } from "@/components/ui/image";
import { Avatar, fmtNum } from "../social/SocialBits";

const SEAT_HUES = ["#E76F51", "#2A9D8F", "#6A4C93", "#0077B6", "#F4A261"];

// full-screen 16:9 player - used by the feeds, search and the channel grid;
// pass `party` for a watch party (shows the watching-now row instead of
// the like / comment / share rail)
export default function FramesPlayer({ post, party, onBack, onLike }) {
  return (
    <div className="absolute inset-0 z-50 flex flex-col bg-black">
      <div className="flex items-center gap-2 px-3 py-2.5">
        <button onClick={onBack} aria-label="Back" className="shrink-0 text-white"><ChevronLeft size={24} /></button>
        <span className="min-w-0 flex-1 truncate text-[13px] font-semibold text-white">{post.title}</span>
        {party && (
          <span className="flex shrink-0 items-center gap-1 rounded-full bg-[#FF3B30]/15 px-2 py-0.5 text-[10px] font-semibold text-[#FF453A]">
            <Radio size={10} /> LIVE
          </span>
        )}
      </div>

      {/* the video always renders inside a fixed 16:9 frame */}
      <div className="w-full shrink-0 overflow-hidden bg-black">
        {post.video ? (
          <video src={post.video} autoPlay loop playsInline controls className="aspect-video w-full object-contain" />
        ) : post.poster ? (
          <Image src={post.poster} alt="" className="aspect-video w-full" fittingType="fill" />
        ) : (
          <div className="aspect-video w-full bg-[#1c1c1e]" />
        )}
      </div>

      <div className="flex-1 overflow-y-auto no-scrollbar px-4 pt-3">
        <div className="flex items-center gap-2.5">
          <Avatar name={post.channel} hue={post.chHue} size={38} />
          <div className="min-w-0 flex-1">
            <div className="truncate text-[14px] font-semibold text-white">{post.channel}</div>
            <div className="text-[11px] text-white/50">
              {fmtNum(post.views)} {party ? "watching" : "views"}{!party && post.age ? ` · ${post.age}` : ""}
            </div>
          </div>
          <button className="shrink-0 rounded-full bg-gradient-to-r from-[#E56E42] to-[#F1865F] px-3.5 py-1 text-[11px] font-semibold text-white">
            Subscribe
          </button>
        </div>

        {party && (
          <div className="mt-3 flex items-center gap-2 rounded-xl bg-white/5 px-3 py-2">
            <div className="flex -space-x-2">
              {(post.seats || []).slice(0, 5).map((s, i) => (
                <Avatar key={s + i} name={s} hue={SEAT_HUES[i % SEAT_HUES.length]} size={22} className="border border-black" />
              ))}
            </div>
            <span className="text-[11px] font-medium text-white/80">{fmtNum(post.views)} watching now</span>
          </div>
        )}

        <div className="mt-3 text-[13px] leading-snug text-white/85">{post.title}</div>

        {!party && onLike && (
          <div className="mt-4 flex items-center gap-6">
            <button onClick={onLike} className="flex items-center gap-1.5 text-[11px] font-semibold text-white">
              <Heart size={20} className={post.liked ? "fill-[#E56E42] text-[#E56E42]" : "text-white"} /> {fmtNum(post.likes)}
            </button>
            <span className="flex items-center gap-1.5 text-[11px] text-white/70"><MessageCircle size={18} /> {fmtNum(post.comments)}</span>
            <span className="flex items-center gap-1.5 text-[11px] text-white/70"><Share2 size={18} /> {fmtNum(post.shares || 0)}</span>
          </div>
        )}
      </div>
    </div>
  );
}