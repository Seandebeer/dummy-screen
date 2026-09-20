import React, { useState, useEffect } from "react";
import { Home as HomeIcon, User as UserIcon, ThumbsUp, MessageCircle, Share2, Search, X } from "lucide-react";
import { socialSlice, nextStockPhoto } from "@/lib/osSocial";
import { Avatar, Editable, EditToggle, Photo } from "./SocialBits";
import { cn } from "@/lib/utils";

// Facepage - Facebook-style feed & profile. Pencil toggles edit mode:
// profile fields, post text, reaction counts and photos all become editable.

export default function FacepageApp({ config, update, locked, fullscreen }) {
  const { data, setData } = socialSlice(config, update, "facepage");
  const [tab, setTab] = useState("feed");
  const [editing, setEditing] = useState(false);
  const me = data.profile;
  const canEdit = !locked && !fullscreen;
  useEffect(() => { if (!canEdit && editing) setEditing(false); }, [canEdit]);

  const patchPost = (id, patch) => setData((d) => ({ posts: d.posts.map((p) => (p.id === id ? { ...p, ...patch } : p)) }));
  const removePost = (id) => setData((d) => ({ posts: d.posts.filter((p) => p.id !== id) }));
  const likePost = (p) => patchPost(p.id, { liked: !p.liked, likes: p.likes + (p.liked ? -1 : 1) });

  const compose = () => {
    const text = window.prompt("What's on your mind?");
    if (!text || !text.trim()) return;
    setData((d) => ({
      posts: [{
        id: `fp-${Date.now()}`, author: me.name, hue: "#1877F2", time: "Just now",
        text: text.trim(), image: "", likes: 0, comments: 0, shares: 0, liked: false,
      }, ...d.posts],
    }));
  };

  const actionBtn = "flex flex-1 items-center justify-center gap-1.5 rounded-md py-2 text-[12px] font-semibold transition active:scale-95";

  return (
    <div className="flex h-full flex-col bg-[#F0F2F5] text-[#050505]">
      {/* blue wordmark header */}
      <div className="flex items-center gap-2 bg-[#1877F2] px-3 py-2">
        <span className="text-[20px] font-bold tracking-tight text-white">Grapevine</span>
        <span className="ml-auto flex items-center gap-1.5">
          <span className="flex h-8 w-8 items-center justify-center rounded-full bg-white/15">
            <Search size={15} className="text-white" />
          </span>
          {canEdit && <EditToggle editing={editing} onToggle={() => setEditing(!editing)} className="bg-white/15 text-white" />}
        </span>
      </div>

      <div className="flex-1 overflow-y-auto no-scrollbar">
        {tab === "feed" ? (
          <>
            <div className="flex items-center gap-2 bg-white p-2.5 shadow-sm">
              <Avatar name={me.name} hue="#1877F2" size={36} />
              <button onClick={compose}
                className="flex-1 rounded-full bg-[#F0F2F5] px-3.5 py-2 text-left text-[13px] text-black/50">
                What's on your mind, {me.name.split(" ")[0]}?
              </button>
            </div>

            {editing && (
              <button onClick={compose}
                className="mx-3 mt-2 flex w-[calc(100%-24px)] items-center justify-center gap-1.5 rounded-lg border border-dashed border-[#1877F2]/50 py-1.5 text-[12px] font-semibold text-[#1877F2]">
                + Add post
              </button>
            )}

            {data.posts.map((p) => (
              <div key={p.id} className="mt-2 bg-white shadow-sm">
                <div className="flex items-center gap-2 p-2.5">
                  <Avatar name={p.author} hue={p.hue} size={36} />
                  <div className="min-w-0 flex-1">
                    <Editable editing={editing} value={p.author} onChange={(v) => patchPost(p.id, { author: v })}
                      className="block truncate text-[14px] font-semibold" />
                    <Editable editing={editing} value={p.time} onChange={(v) => patchPost(p.id, { time: v })}
                      className="block text-[11px] text-black/50" />
                  </div>
                  {editing && (
                    <button onClick={() => removePost(p.id)} aria-label="Delete post" className="p-1 text-black/40">
                      <X size={15} className="h-4 w-4" />
                    </button>
                  )}
                </div>
                <Editable editing={editing} value={p.text} onChange={(v) => patchPost(p.id, { text: v })}
                  className="block px-3 pb-2.5 text-[14px] leading-snug" />
                {p.image ? (
                  <Photo src={p.image} className="aspect-[4/3] w-full object-cover" editing={editing}
                    onSwap={() => patchPost(p.id, { image: nextStockPhoto(p.image) })}
                    onDelete={() => patchPost(p.id, { image: "" })} />
                ) : editing ? (
                  <Photo src="" editing className="mx-3 mb-2 h-28 rounded-lg" addLabel="Add photo"
                    onAdd={() => patchPost(p.id, { image: nextStockPhoto() })} />
                ) : null}
                <div className="flex items-center justify-between px-3 py-1.5 text-[12px] text-black/55">
                  <span>
                    👍 <Editable editing={editing} type="number" value={p.likes} onChange={(v) => patchPost(p.id, { likes: v })} />
                  </span>
                  <span>
                    <Editable editing={editing} type="number" value={p.comments} onChange={(v) => patchPost(p.id, { comments: v })} /> comments ·{" "}
                    <Editable editing={editing} type="number" value={p.shares} onChange={(v) => patchPost(p.id, { shares: v })} /> shares
                  </span>
                </div>
                <div className="flex items-center gap-1 border-t border-black/5 px-2 pb-1">
                  <button onClick={() => likePost(p)} className={cn(actionBtn, p.liked ? "text-[#1877F2]" : "text-black/60 hover:bg-black/5")}>
                    <ThumbsUp size={15} /> Like
                  </button>
                  <button onClick={() => patchPost(p.id, { comments: p.comments + 1 })} className={cn(actionBtn, "text-black/60 hover:bg-black/5")}>
                    <MessageCircle size={15} /> Comment
                  </button>
                  <button onClick={() => patchPost(p.id, { shares: p.shares + 1 })} className={cn(actionBtn, "text-black/60 hover:bg-black/5")}>
                    <Share2 size={15} /> Share
                  </button>
                </div>
              </div>
            ))}
          </>
        ) : (
          <div className="bg-white pb-4 shadow-sm">
            <div className="h-24" style={{ background: "linear-gradient(160deg, #1877F2, #0a4fa8)" }} />
            <div className="-mt-9 flex flex-col items-center px-4">
              <Avatar name={me.name} hue="#1877F2" size={72} className="border-4 border-white" />
              <Editable editing={editing} value={me.name}
                onChange={(v) => setData((d) => ({ profile: { ...d.profile, name: v } }))}
                className="mt-2 text-center text-[18px] font-bold" />
              <Editable editing={editing} value={me.bio}
                onChange={(v) => setData((d) => ({ profile: { ...d.profile, bio: v } }))}
                className="mt-1 text-center text-[12px] leading-snug text-black/60" />
              <div className="mt-2 flex items-center gap-1 text-[12px] font-semibold text-[#1877F2]">
                <Editable editing={editing} type="number" value={me.friends}
                  onChange={(v) => setData((d) => ({ profile: { ...d.profile, friends: v } }))} />
                Friends
              </div>
              <div className="mt-4 grid w-full grid-cols-3 gap-1">
                {data.posts.filter((p) => p.image).map((p) => (
                  <Photo key={p.id} src={p.image} className="aspect-square w-full object-cover" editing={editing}
                    onSwap={() => patchPost(p.id, { image: nextStockPhoto(p.image) })} />
                ))}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* bottom tabs */}
      <div className="flex border-t border-black/10 bg-white">
        {[["feed", HomeIcon, "Feed"], ["profile", UserIcon, "Profile"]].map(([id, Icon, label]) => (
          <button key={id} onClick={() => setTab(id)}
            className={cn("flex flex-1 flex-col items-center gap-0.5 py-1.5 text-[10px]",
              tab === id ? "font-semibold text-[#1877F2]" : "text-black/45")}>
            <Icon size={20} />
            {label}
          </button>
        ))}
      </div>
    </div>
  );
}