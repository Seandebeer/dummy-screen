import React, { useState, useEffect } from "react";
import { ArrowLeft, Home as HomeIcon, Play, Search, ThumbsUp, ThumbsDown, Share2, Users } from "lucide-react";
import { socialSlice, nextStockPhoto } from "@/lib/osSocial";
import { Avatar, Editable, EditToggle, Photo, UploadButton, fmtNum } from "./SocialBits";
import { cn } from "@/lib/utils";

// VidTube - YouTube-style home grid, watch page, subscriptions and channel
// profile. Pencil toggles edit mode: titles, channels, views, thumbs, subs.

export default function VidTubeApp({ config, update, locked, fullscreen }) {
  const { data, setData } = socialSlice(config, update, "vidtube");
  const [tab, setTab] = useState("home"); // home | watch | subs | you
  const [watchId, setWatchId] = useState(null);
  const [chip, setChip] = useState("All");
  const [editing, setEditing] = useState(false);
  const me = data.profile;
  const canEdit = !locked && !fullscreen;
  useEffect(() => { if (!canEdit && editing) setEditing(false); }, [canEdit]);

  const patchVideo = (id, patch) => setData((d) => ({ videos: d.videos.map((v) => (v.id === id ? { ...v, ...patch } : v)) }));
  const removeVideo = (id) => setData((d) => ({ videos: d.videos.filter((v) => v.id !== id) }));
  const isSub = (ch) => !!(data.subs || {})[ch];
  const toggleSub = (ch) => setData((d) => ({ subs: { ...(d.subs || {}), [ch]: !d.subs?.[ch] } }));

  const addVideo = () => {
    const title = window.prompt("Title for the new video:");
    if (!title || !title.trim()) return;
    setData((d) => ({
      videos: [{
        id: `yt-${Date.now()}`, title: title.trim(), channel: me.name, chHue: "#1877F2",
        views: 0, age: "just now", duration: "0:00", image: nextStockPhoto(), cat: "Film",
      }, ...d.videos],
    }));
  };

  const addUploadedVideo = (url) => {
    const title = window.prompt("Title for the new video:", "New video");
    setData((d) => ({
      videos: [{
        id: `yt-${Date.now()}`, title: (title || "New video").trim(), channel: me.name, chHue: "#1877F2",
        views: 0, age: "just now", duration: "0:00", image: "", video: url, cat: "Film",
      }, ...d.videos],
    }));
  };

  const chSubsOf = (ch, views) => (data.chSubs || {})[ch] ?? Math.max(1000, Math.round((views || 0) / 40));
  const setChSubs = (ch, n) => setData((d) => ({ chSubs: { ...(d.chSubs || {}), [ch]: n } }));

  const cats = ["All", ...new Set(data.videos.map((v) => v.cat))];
  const visible = chip === "All" ? data.videos : data.videos.filter((v) => v.cat === chip);
  const watch = data.videos.find((v) => v.id === watchId) || null;

  const videoCard = (v, small) => (
    <button key={v.id} onClick={() => { setWatchId(v.id); setTab("watch"); }}
      className="block w-full text-left">
      <span className="relative block">
        {v.video && !v.image ? (
          <video src={v.video} muted playsInline className="aspect-video w-full object-cover" />
        ) : (
          <Photo src={v.image} className="aspect-video w-full object-cover" editing={editing}
            onSwap={() => patchVideo(v.id, { image: nextStockPhoto(v.image) })}
            onUpload={(url) => patchVideo(v.id, { image: url })} />
        )}
        <span className="absolute bottom-1 right-1 rounded bg-black/75 px-1 text-[10px] font-medium text-white">{v.duration}</span>
        {editing && (
          <span className="absolute left-1 top-1 flex gap-1.5">
            <span onClick={(e) => { e.stopPropagation(); removeVideo(v.id); }}
              className="flex h-6 w-6 items-center justify-center rounded-full bg-black/60 text-white">✕</span>
            {v.video && (
              <UploadButton label="Thumb" onFile={(url) => patchVideo(v.id, { image: url })} />
            )}
          </span>
        )}
      </span>
      <div onClick={(e) => { if (editing) e.stopPropagation(); }} className={cn("flex gap-2", small ? "p-1.5" : "p-2.5 pt-2")}>
        <Avatar name={v.channel} hue={v.chHue} size={small ? 24 : 34} />
        <span className="min-w-0 flex-1">
          <Editable editing={editing} value={v.title} onChange={(t) => patchVideo(v.id, { title: t })}
            className="block line-clamp-2 text-[13px] font-medium leading-snug" />
          <Editable editing={editing} value={v.channel} onChange={(t) => patchVideo(v.id, { channel: t })}
            className="block truncate text-[11px] text-black/55" />
          <span className="block text-[11px] text-black/55">
            <Editable editing={editing} type="number" value={v.views} onChange={(n) => patchVideo(v.id, { views: n })} />{" "}
            views · <Editable editing={editing} value={v.age} onChange={(t) => patchVideo(v.id, { age: t })} />
          </span>
        </span>
      </div>
    </button>
  );

  return (
    <div className="flex h-full flex-col bg-white text-[#0f0f0f]">
      <div className="flex items-center gap-2 px-3 py-2">
        {tab === "watch" ? (
          <button onClick={() => setTab("home")} aria-label="Back" className="p-0.5"><ArrowLeft size={20} /></button>
        ) : (
          <span className="flex items-center gap-1">
            <span className="flex h-[22px] w-[32px] items-center justify-center rounded-md bg-[#FF0000]">
              <Play size={13} className="fill-white text-white" />
            </span>
            <Editable editing={editing} value={data.name || "Streamly"}
              onChange={(v) => setData((d) => ({ name: v }))}
              className="text-[18px] font-semibold tracking-tight" />
          </span>
        )}
        <span className="ml-auto flex items-center gap-1.5">
          <span className="flex h-8 w-8 items-center justify-center rounded-full bg-black/5"><Search size={16} /></span>
          {canEdit && <EditToggle editing={editing} onToggle={() => setEditing(!editing)} />}
        </span>
      </div>

      <div className="flex-1 overflow-y-auto no-scrollbar">
        {tab === "home" && (
          <>
            <div className="flex gap-2 overflow-x-auto no-scrollbar px-3 pb-1">
              {cats.map((c) => (
                <button key={c} onClick={() => setChip(c)}
                  className={cn("shrink-0 rounded-lg px-2.5 py-1 text-[12px] font-medium",
                    chip === c ? "bg-[#0f0f0f] text-white" : "bg-black/[0.06] text-[#0f0f0f]")}>
                  {c}
                </button>
              ))}
            </div>
            {editing && (
              <div className="mx-3 mt-2 flex gap-2">
                <button onClick={addVideo}
                  className="flex-1 rounded-lg border border-dashed border-black/25 py-1.5 text-[12px] font-semibold text-black/60">
                  + Add video
                </button>
                <UploadButton accept="video/*" label="Upload video" onFile={(url) => addUploadedVideo(url)}
                  className="flex-1 rounded-lg border border-dashed border-black/25 py-1.5 text-[12px] font-semibold text-black/60 bg-black/[0.04]" />
              </div>
            )}
            <div className="grid grid-cols-1 gap-1 pb-2">
              {visible.map((v) => videoCard(v))}
            </div>
          </>
        )}

        {tab === "watch" && watch && (
          <>
            {watch.video ? (
              <video src={watch.video} controls autoPlay playsInline className="aspect-video w-full bg-black" />
            ) : (
              <span className="relative block">
                <Photo src={watch.image} className="aspect-video w-full object-cover" editing={editing}
                  onSwap={() => patchVideo(watch.id, { image: nextStockPhoto(watch.image) })}
                  onUpload={(url) => patchVideo(watch.id, { image: url })} />
                <span className="absolute inset-0 flex items-center justify-center">
                  <span className="flex h-12 w-12 items-center justify-center rounded-full bg-black/40 backdrop-blur-sm">
                    <Play size={22} className="fill-white text-white" />
                  </span>
                </span>
              </span>
            )}
            <div className="px-3 pt-2.5">
              <Editable editing={editing} value={watch.title} onChange={(t) => patchVideo(watch.id, { title: t })}
                className="block text-[16px] font-semibold leading-snug" />
              <div className="pt-1 text-[12px] text-black/55">
                <Editable editing={editing} type="number" value={watch.views} onChange={(n) => patchVideo(watch.id, { views: n })} />{" "}
                views · <Editable editing={editing} value={watch.age} onChange={(t) => patchVideo(watch.id, { age: t })} />
              </div>
              <div className="mt-2 flex items-center gap-4 rounded-xl bg-black/[0.04] px-3 py-2">
                <span className="flex items-center gap-1 text-[12px] font-medium"><ThumbsUp size={16} /> {fmtNum(Math.round(watch.views / 20))}</span>
                <span className="flex items-center gap-1 text-[12px] font-medium text-black/60"><ThumbsDown size={16} /></span>
                <span className="flex items-center gap-1 text-[12px] font-medium text-black/60"><Share2 size={16} /> Share</span>
              </div>
              <div className="mt-2 flex items-center gap-2.5">
                <Avatar name={watch.channel} hue={watch.chHue} size={36} />
                <div className="min-w-0 flex-1">
                  <Editable editing={editing} value={watch.channel} onChange={(t) => patchVideo(watch.id, { channel: t })}
                    className="block truncate text-[13px] font-semibold" />
                  <span className="block text-[11px] text-black/50">
                    <Editable editing={editing} type="number" value={chSubsOf(watch.channel, watch.views)}
                      onChange={(n) => setChSubs(watch.channel, n)} /> subscribers
                  </span>
                </div>
                <button onClick={() => toggleSub(watch.channel)}
                  className={cn("rounded-full px-3.5 py-1.5 text-[12px] font-semibold",
                    isSub(watch.channel) ? "bg-black/[0.08] text-[#0f0f0f]" : "bg-[#FF0000] text-white")}>
                  {isSub(watch.channel) ? "Subscribed" : "Subscribe"}
                </button>
              </div>
              <div className="mt-2.5 rounded-xl bg-black/[0.04] p-2.5 text-[12px] leading-snug text-black/70">
                <Editable editing={editing} value={watch.duration} onChange={(t) => patchVideo(watch.id, { duration: t })} /> ·{" "}
                <Editable editing={editing} value={watch.cat} onChange={(t) => patchVideo(watch.id, { cat: t })} />. Tap Subscribe to keep up with new uploads.
              </div>
            </div>
            <div className="mt-3 border-t border-black/10 pt-1">
              <p className="px-3 pt-2 text-[13px] font-semibold">Up next</p>
              {data.videos.filter((v) => v.id !== watch.id).slice(0, 4).map((v) => videoCard(v, true))}
            </div>
          </>
        )}

        {tab === "subs" && (
          <div className="px-3">
            {[...new Map(data.videos.map((v) => [v.channel, v.chHue])).entries()].map(([ch, hue]) => (
              <div key={ch} className="flex items-center gap-3 border-b border-black/5 py-2.5">
                <Avatar name={ch} hue={hue} size={40} />
                <span className="min-w-0 flex-1">
                  <span className="block truncate text-[14px] font-medium">{ch}</span>
                  <span className="block text-[11px] text-black/50">
                    <Editable editing={editing} type="number"
                      value={chSubsOf(ch, data.videos.find((x) => x.channel === ch)?.views || 0)}
                      onChange={(n) => setChSubs(ch, n)} /> subscribers
                  </span>
                </span>
                <button onClick={() => toggleSub(ch)}
                  className={cn("rounded-full px-3 py-1.5 text-[11px] font-semibold",
                    isSub(ch) ? "bg-black/[0.08] text-[#0f0f0f]" : "bg-[#FF0000] text-white")}>
                  {isSub(ch) ? "Subscribed" : "Subscribe"}
                </button>
              </div>
            ))}
          </div>
        )}

        {tab === "you" && (
          <>
            <div className="h-20" style={{ background: "linear-gradient(160deg, #FF0000, #7a0000)" }} />
            <div className="-mt-7 flex flex-col items-center">
              <Avatar name={me.name} hue="#FF0000" size={56} className="border-2 border-white" />
              <Editable editing={editing} value={me.name}
                onChange={(v) => setData((d) => ({ profile: { ...d.profile, name: v } }))}
                className="pt-1.5 text-[16px] font-semibold" />
              <Editable editing={editing} value={me.handle}
                onChange={(v) => setData((d) => ({ profile: { ...d.profile, handle: v } }))}
                className="text-[12px] text-black/55" />
              <div className="text-[12px] font-medium text-black/70">
                <Editable editing={editing} type="number" value={me.subscribers}
                  onChange={(v) => setData((d) => ({ profile: { ...d.profile, subscribers: v } }))} /> subscribers
              </div>
            </div>
            <div className="mt-3 border-t border-black/10 pt-1">
              <p className="px-3 pt-2 text-[13px] font-semibold">Videos</p>
              {data.videos.filter((v) => v.channel === me.name).map((v) => videoCard(v, true))}
            </div>
          </>
        )}
      </div>

      <div className="flex border-t border-black/10">
        {[["home", HomeIcon, "Home"], ["subs", Users, "Subs"], ["you", null, "You"]].map(([id, Icon, label]) => (
          <button key={id} onClick={() => setTab(id)}
            className={cn("flex flex-1 flex-col items-center gap-0.5 py-1.5 text-[10px]",
              tab === id ? "font-semibold text-[#0f0f0f]" : "text-black/45")}>
            {id === "you"
              ? <Avatar name={me.name} hue="#FF0000" size={18} className={tab === "you" ? "ring-2 ring-[#0f0f0f]" : "opacity-60"} />
              : <Icon size={19} />}
            {label}
          </button>
        ))}
      </div>
    </div>
  );
}