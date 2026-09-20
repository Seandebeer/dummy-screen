import React, { useState, useEffect } from "react";
import { Home as HomeIcon, Heart, MessageCircle, Send, Bookmark, User as UserIcon } from "lucide-react";
import { socialSlice, nextStockPhoto } from "@/lib/osSocial";
import { Avatar, Editable, EditToggle, SaveToggle, Photo, fmtNum } from "./SocialBits";
import { cn } from "@/lib/utils";

// Photogram - Instagram-style stories, square-photo feed and profile grid.
// Pencil toggles edit mode: captions, like counts, photos and profile fields.

const RING = "conic-gradient(#feda75, #fa7e1e, #d62976, #962fbf, #4f5bd5, #feda75)";

export default function PhotogramApp({ config, update, locked, fullscreen }) {
  const { data, setData } = socialSlice(config, update, "photogram");
  const [tab, setTab] = useState("home"); // home | liked | profile
  const [editing, setEditing] = useState(false);
  const me = data.profile;
  const canEdit = !locked && !fullscreen;
  useEffect(() => { if (!canEdit && editing) setEditing(false); }, [canEdit]);

  const patchPost = (id, patch) => setData((d) => ({ posts: d.posts.map((p) => (p.id === id ? { ...p, ...patch } : p)) }));
  const removePost = (id) => setData((d) => ({ posts: d.posts.filter((p) => p.id !== id) }));

  const addPost = () => {
    const caption = window.prompt("Caption for the new post:");
    if (caption === null) return;
    setData((d) => ({
      posts: [{
        id: `ig-${Date.now()}`, author: me.handle || me.name, hue: "#833AB4",
        caption: caption.trim(), image: nextStockPhoto(), likes: 0, comments: 0, liked: false, saved: false,
      }, ...d.posts],
    }));
  };

  const stories = [
    { name: "Your story", hue: "#262626", ring: false },
    ...[...new Map(data.posts.map((p) => [p.author, p.hue])).entries()].map(([name, hue]) => ({ name, hue, ring: true })),
  ];

  const feedPosts = tab === "liked" ? data.posts.filter((p) => p.liked) : data.posts;

  const postCard = (p) => (
    <div key={p.id} className="pb-1">
      <div className="flex items-center gap-2 px-3 py-2">
        <Avatar name={p.author} hue={p.hue} size={30} />
        <Editable editing={editing} value={p.author} onChange={(v) => patchPost(p.id, { author: v })}
          className="min-w-0 flex-1 truncate text-[13px] font-semibold" />
        {editing && (
          <button onClick={() => removePost(p.id)} aria-label="Delete post" className="p-1 text-black/40">
            <Send size={14} className="h-4 w-4 rotate-45" />
          </button>
        )}
      </div>
      <Photo src={p.image} className="aspect-square w-full object-cover" editing={editing}
        onSwap={() => patchPost(p.id, { image: nextStockPhoto(p.image) })}
        onUpload={(url) => patchPost(p.id, { image: url })} />
      <div className="flex items-center gap-4 px-3 pt-2.5">
        <button onClick={() => patchPost(p.id, { liked: !p.liked, likes: p.likes + (p.liked ? -1 : 1) })}>
          <Heart size={22} className={cn(p.liked ? "fill-[#FF3040] text-[#FF3040]" : "text-[#262626]")} />
        </button>
        <button onClick={() => patchPost(p.id, { comments: p.comments + 1 })}>
          <MessageCircle size={22} className="text-[#262626]" />
        </button>
        <button onClick={() => patchPost(p.id, { comments: p.comments + 1 })} aria-label="Send">
          <Send size={21} className="text-[#262626]" />
        </button>
        <button onClick={() => patchPost(p.id, { saved: !p.saved })} className="ml-auto" aria-label="Save">
          <Bookmark size={21} className={cn(p.saved ? "fill-[#262626] text-[#262626]" : "text-[#262626]")} />
        </button>
      </div>
      <div className="px-3 pt-1.5">
        <div className="text-[13px] font-semibold">
          <Editable editing={editing} type="number" value={p.likes} onChange={(v) => patchPost(p.id, { likes: v })} /> likes
        </div>
        <div className="pt-0.5 text-[13px] leading-snug">
          <span className="font-semibold">{p.author}</span>{" "}
          <Editable editing={editing} value={p.caption} onChange={(v) => patchPost(p.id, { caption: v })} className="inline-block" />
        </div>
        <div className="pt-0.5 text-[12px] text-black/45">
          View all <Editable editing={editing} type="number" value={p.comments} onChange={(v) => patchPost(p.id, { comments: v })} /> comments
        </div>
      </div>
    </div>
  );

  return (
    <div className="flex h-full flex-col bg-white text-[#262626]">
      <div className="flex items-center px-3 py-2">
        <Editable editing={editing} value={data.name || "Lume"}
          onChange={(v) => setData((d) => ({ name: v }))}
          className="text-[22px] font-display font-semibold italic tracking-tight" />
        <span className="ml-auto flex items-center gap-1">
          {canEdit && <SaveToggle app="photogram" defaultName={`${data.name || "Lume"} page`} data={data} />}
          {canEdit && <EditToggle editing={editing} onToggle={() => setEditing(!editing)} />}
        </span>
      </div>

      <div className="flex-1 overflow-y-auto no-scrollbar">
        {tab === "profile" ? (
          <div className="px-4 pb-4">
            <div className="flex items-center gap-4 pt-1">
              <span className="rounded-full p-[2.5px]" style={{ background: RING }}>
                <Avatar name={me.name} hue="#833AB4" size={68} className="border-2 border-white" />
              </span>
              <div className="flex flex-1 justify-around text-center">
                <div>
                  <div className="text-[16px] font-bold">{data.posts.length}</div>
                  <div className="text-[11px] text-black/55">posts</div>
                </div>
                <div>
                  <div className="text-[16px] font-bold">
                    <Editable editing={editing} type="number" value={me.followers}
                      onChange={(v) => setData((d) => ({ profile: { ...d.profile, followers: v } }))} />
                  </div>
                  <div className="text-[11px] text-black/55">followers</div>
                </div>
                <div>
                  <div className="text-[16px] font-bold">
                    <Editable editing={editing} type="number" value={me.following}
                      onChange={(v) => setData((d) => ({ profile: { ...d.profile, following: v } }))} />
                  </div>
                  <div className="text-[11px] text-black/55">following</div>
                </div>
              </div>
            </div>
            <div className="pt-2">
              <Editable editing={editing} value={me.name}
                onChange={(v) => setData((d) => ({ profile: { ...d.profile, name: v } }))}
                className="block text-[13px] font-semibold" />
              <Editable editing={editing} value={me.bio}
                onChange={(v) => setData((d) => ({ profile: { ...d.profile, bio: v } }))}
                className="block whitespace-pre-line text-[12px] leading-snug text-black/70" />
            </div>
            <div className="mt-3 grid grid-cols-3 gap-0.5">
              {data.posts.map((p) => (
                <Photo key={p.id} src={p.image} className="aspect-square w-full object-cover" editing={editing}
                  onSwap={() => patchPost(p.id, { image: nextStockPhoto(p.image) })}
                  onUpload={(url) => patchPost(p.id, { image: url })} />
              ))}
            </div>
          </div>
        ) : (
          <>
            <div className="flex gap-3.5 overflow-x-auto no-scrollbar border-b border-black/5 px-3 py-3">
              {stories.map((s, i) => (
                <div key={i} className="flex w-[62px] shrink-0 flex-col items-center gap-1">
                  <span className={cn("rounded-full", s.ring ? "p-[2px]" : "p-[2px] bg-black/15")}
                    style={s.ring ? { background: RING } : undefined}>
                    <Avatar name={s.name} hue={s.hue} size={54} className="border-2 border-white" />
                  </span>
                  <span className="w-full truncate text-center text-[10px] text-black/70">{s.name}</span>
                </div>
              ))}
            </div>
            {editing && (
              <button onClick={addPost}
                className="mx-3 mt-2 flex w-[calc(100%-24px)] items-center justify-center gap-1.5 rounded-lg border border-dashed border-black/25 py-1.5 text-[12px] font-semibold text-black/60">
                + Add post
              </button>
            )}
            {feedPosts.map(postCard)}
            {tab === "liked" && feedPosts.length === 0 && (
              <p className="pt-10 text-center text-[12px] text-black/40">No liked posts yet</p>
            )}
          </>
        )}
      </div>

      <div className="flex items-center justify-around border-t border-black/10 py-1.5">
        <button onClick={() => setTab("home")} aria-label="Home">
          <HomeIcon size={22} className={cn(tab === "home" ? "text-[#262626]" : "text-black/35")} />
        </button>
        <button onClick={() => setTab("liked")} aria-label="Liked posts">
          <Heart size={22} className={tab === "liked" ? "fill-[#262626] text-[#262626]" : "text-black/35"} />
        </button>
        <button onClick={() => setTab("profile")} aria-label="Profile">
          <UserIcon size={22} className={tab === "profile" ? "text-[#262626]" : "text-black/35"} />
        </button>
      </div>
    </div>
  );
}