import React, { useState, useEffect } from "react";
import { Heart, MessageCircle, Share2, Music2, User as UserIcon, Check, Plus, X, Home as HomeIcon } from "lucide-react";
import { socialSlice, nextStockPhoto } from "@/lib/osSocial";
import { Avatar, Editable, EditToggle, Photo, fmtNum } from "./SocialBits";
import { Image } from "@/components/ui/image";
import { cn } from "@/lib/utils";

// QuickTok - TikTok-style full-screen vertical feed with a profile grid.
// Pencil toggles edit mode: captions, like counts, photos and profile fields.

export default function QuickTokApp({ config, update, locked, fullscreen }) {
  const { data, setData } = socialSlice(config, update, "quicktok");
  const [tab, setTab] = useState("home"); // home | me
  const [feed, setFeed] = useState("foryou"); // foryou | following
  const [editing, setEditing] = useState(false);
  const me = data.profile;
  const canEdit = !locked && !fullscreen;
  useEffect(() => { if (!canEdit && editing) setEditing(false); }, [canEdit]);

  const patchPost = (id, patch) => setData((d) => ({ posts: d.posts.map((p) => (p.id === id ? { ...p, ...patch } : p)) }));
  const removePost = (id) => setData((d) => ({ posts: d.posts.filter((p) => p.id !== id) }));
  const isFollowing = (a) => (data.following || []).includes(a);
  const toggleFollow = (a) => setData((d) => ({
    following: isFollowing(a) ? d.following.filter((x) => x !== a) : [...(d.following || []), a],
  }));

  const addClip = () => {
    const caption = window.prompt("Caption for the new clip:");
    if (caption === null) return;
    setData((d) => ({
      posts: [{
        id: `tt-${Date.now()}`, author: me.handle || me.name, caption: caption.trim(),
        image: nextStockPhoto(), likes: 0, comments: 0, shares: 0, liked: false,
        music: `Original sound - ${me.handle || me.name}`,
      }, ...d.posts],
    }));
  };

  const posts = feed === "following"
    ? data.posts.filter((p) => isFollowing(p.author))
    : data.posts;

  return (
    <div className="relative flex h-full flex-col bg-black text-white">
      {tab === "home" ? (
        <>
          <div className="absolute inset-x-0 top-0 z-20 flex items-center justify-center gap-5 bg-gradient-to-b from-black/60 to-transparent pb-4 pt-2 text-[14px] font-semibold">
            <button onClick={() => setFeed("following")}
              className={feed === "following" ? "text-white" : "text-white/50"}>Following</button>
            <span className="h-3.5 w-px bg-white/30" />
            <button onClick={() => setFeed("foryou")}
              className={feed === "foryou" ? "text-white" : "text-white/50"}>For You</button>
          </div>
          {canEdit && (
            <div className="absolute right-2 top-2 z-30">
              <EditToggle editing={editing} onToggle={() => setEditing(!editing)} className="bg-white/10 text-white" />
            </div>
          )}

          <div className="h-full snap-y snap-mandatory overflow-y-auto no-scrollbar">
            {editing && (
              <div className="snap-start">
                <button onClick={addClip}
                  className="flex h-full w-full flex-col items-center justify-center gap-2 text-[13px] font-semibold text-white/70">
                  <Plus size={26} /> Add clip
                </button>
              </div>
            )}
            {posts.map((p) => (
              <div key={p.id} className="relative h-full w-full snap-start overflow-hidden">
                <Image src={p.image} alt="" className="absolute inset-0 h-full w-full object-cover" />
                <div className="absolute inset-0 bg-gradient-to-t from-black/75 via-transparent to-black/35" />

                {/* right action rail */}
                <div className="absolute bottom-28 right-2 z-10 flex flex-col items-center gap-4">
                  <button onClick={() => patchPost(p.id, { liked: !p.liked, likes: p.likes + (p.liked ? -1 : 1) })}
                    className="flex flex-col items-center gap-0.5">
                    <Heart size={32} className={p.liked ? "fill-[#FE2C55] text-[#FE2C55]" : "text-white"} />
                    <span className="text-[11px] font-semibold">{fmtNum(p.likes)}</span>
                  </button>
                  <button onClick={() => patchPost(p.id, { comments: p.comments + 1 })} className="flex flex-col items-center gap-0.5">
                    <MessageCircle size={30} className="text-white" />
                    <span className="text-[11px] font-semibold">{fmtNum(p.comments)}</span>
                  </button>
                  <button onClick={() => patchPost(p.id, { shares: p.shares + 1 })} className="flex flex-col items-center gap-0.5">
                    <Share2 size={30} className="text-white" />
                    <span className="text-[11px] font-semibold">{fmtNum(p.shares)}</span>
                  </button>
                </div>

                {/* bottom info */}
                <div className="absolute bottom-14 left-3 right-16 z-10">
                  <div className="flex items-center gap-2">
                    <span className="text-[15px] font-bold">@{p.author}</span>
                    {isFollowing(p.author) ? (
                      <span className="flex items-center gap-0.5 text-[11px] text-white/70"><Check size={11} /> Following</span>
                    ) : (
                      <button onClick={() => toggleFollow(p.author)}
                        className="rounded-full bg-[#FE2C55] px-2 py-0.5 text-[11px] font-semibold">Follow</button>
                    )}
                  </div>
                  <Editable editing={editing} value={p.caption} onChange={(v) => patchPost(p.id, { caption: v })}
                    className="block pt-1 text-[13px] leading-snug"
                    inputClass="border-white/30 bg-white/10 text-white" />
                  <div className="flex items-center gap-1.5 pt-1.5">
                    <Music2 size={13} className="shrink-0 text-white" />
                    <Editable editing={editing} value={p.music} onChange={(v) => patchPost(p.id, { music: v })}
                      className="block truncate text-[12px]"
                      inputClass="border-white/30 bg-white/10 text-white" />
                  </div>
                </div>

                {/* edit card over the clip */}
                {editing && (
                  <div className="absolute bottom-28 left-3 right-16 z-20 rounded-xl bg-black/75 p-2.5 backdrop-blur">
                    <div className="flex items-center gap-2 text-[10px] font-semibold uppercase tracking-wider text-white/60">
                      Edit clip
                      <button onClick={() => patchPost(p.id, { image: nextStockPhoto(p.image) })}
                        className="ml-auto rounded-full bg-white/15 px-2 py-0.5 text-[10px] normal-case tracking-normal text-white">Swap photo</button>
                      <button onClick={() => removePost(p.id)} aria-label="Delete clip"
                        className="rounded-full bg-white/15 p-1 text-white"><X size={11} /></button>
                    </div>
                    <div className="mt-1.5 flex gap-2">
                      <Editable editing={editing} type="number" value={p.likes} onChange={(v) => patchPost(p.id, { likes: v })}
                        className="w-16 rounded bg-white/10 px-1 text-center text-[12px] text-white"
                        inputClass="border-white/30 bg-white/10 text-white" />
                      <span className="self-center text-[10px] text-white/50">likes</span>
                      <Editable editing={editing} type="number" value={p.comments} onChange={(v) => patchPost(p.id, { comments: v })}
                        className="w-16 rounded bg-white/10 px-1 text-center text-[12px] text-white"
                        inputClass="border-white/30 bg-white/10 text-white" />
                      <span className="self-center text-[10px] text-white/50">comments</span>
                    </div>
                  </div>
                )}
              </div>
            ))}
            {posts.length === 0 && !editing && (
              <div className="flex h-full flex-col items-center justify-center gap-2 text-[13px] text-white/50">
                <span>Nothing here yet.</span>
                <button onClick={() => setFeed("foryou")} className="font-semibold text-white">Go to For You</button>
              </div>
            )}
          </div>
        </>
      ) : (
        <div className="flex-1 overflow-y-auto no-scrollbar px-5">
          <div className="flex flex-col items-center pt-6">
            <span className="rounded-full p-[2.5px]" style={{ background: "linear-gradient(45deg, #25F4EE, #FE2C55)" }}>
              <Avatar name={me.name} hue="#FE2C55" size={76} className="border-2 border-black" />
            </span>
            <div className="pt-2 text-[14px] font-semibold">{me.name}</div>
            <div className="text-[12px] text-white/55">@{me.handle}</div>
            <div className="flex items-center gap-7 pt-3 text-center">
              <div>
                <div className="text-[15px] font-bold">
                  <Editable editing={editing} type="number" value={me.following}
                    onChange={(v) => setData((d) => ({ profile: { ...d.profile, following: v } }))} />
                </div>
                <div className="text-[10px] text-white/50">Following</div>
              </div>
              <div>
                <div className="text-[15px] font-bold">
                  <Editable editing={editing} type="number" value={me.followers}
                    onChange={(v) => setData((d) => ({ profile: { ...d.profile, followers: v } }))} />
                </div>
                <div className="text-[10px] text-white/50">Followers</div>
              </div>
              <div>
                <div className="text-[15px] font-bold">
                  <Editable editing={editing} type="number" value={me.likes}
                    onChange={(v) => setData((d) => ({ profile: { ...d.profile, likes: v } }))} />
                </div>
                <div className="text-[10px] text-white/50">Likes</div>
              </div>
            </div>
          </div>
          <div className="mt-4 grid grid-cols-3 gap-0.5 pb-2">
            {data.posts.map((p) => (
              <Photo key={p.id} src={p.image} className="aspect-[9/14] w-full object-cover" editing={editing}
                onSwap={() => patchPost(p.id, { image: nextStockPhoto(p.image) })} />
            ))}
          </div>
        </div>
      )}

      {/* bottom nav */}
      <div className="absolute inset-x-0 bottom-0 z-30 flex items-center justify-between bg-black/60 px-6 pb-3 pt-2 backdrop-blur">
        <button onClick={() => setTab("home")} className="flex flex-col items-center gap-0.5 text-[10px]">
          <HomeIcon size={22} className={tab === "home" ? "text-white" : "text-white/40"} />
          <span className={tab === "home" ? "text-white" : "text-white/40"}>Home</span>
        </button>
        <button onClick={() => setTab("me")} className="flex flex-col items-center gap-0.5 text-[10px]">
          <UserIcon size={22} className={tab === "me" ? "text-white" : "text-white/40"} />
          <span className={tab === "me" ? "text-white" : "text-white/40"}>Me</span>
        </button>
      </div>
    </div>
  );
}