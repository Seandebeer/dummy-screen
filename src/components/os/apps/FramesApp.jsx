import React, { useState, useEffect } from "react";
import { Zap, Compass, Search, Users, User } from "lucide-react";
import { framesSlice } from "@/lib/framesData";
import { nextStockPhoto } from "@/lib/osSocial";
import { EditToggle, SaveToggle } from "./social/SocialBits";
import FramesFeed from "./frames/FramesFeed";
import FramesSearch from "./frames/FramesSearch";
import FramesParties from "./frames/FramesParties";
import FramesChannel from "./frames/FramesChannel";
import FramesPlayer from "./frames/FramesPlayer";

// Frames - a 16:9-only video sharing app. Shorts and Discover are rendered
// by the same feed component so the two tabs look identical, plus search,
// watch parties and a channel page. The bottom dock is icons-only.
const TABS = [
  { id: "shorts", Icon: Zap },
  { id: "discover", Icon: Compass },
  { id: "search", Icon: Search },
  { id: "parties", Icon: Users },
  { id: "channel", Icon: User },
];

export default function FramesApp({ config, update, locked, fullscreen }) {
  const { data, setData } = framesSlice(config, update);
  const [tab, setTab] = useState("shorts");
  const [editing, setEditing] = useState(false);
  const [player, setPlayer] = useState(null); // { id } opens a video, { partyId } joins a party
  const canEdit = !locked && !fullscreen;
  useEffect(() => { if (!canEdit && editing) setEditing(false); }, [canEdit]);

  const patchFeed = (feed, id, patch) => setData((d) => ({
    [feed]: d[feed].map((p) => (p.id === id ? { ...p, ...patch } : p)),
  }));
  const removeFeedPost = (feed, id) => setData((d) => ({ [feed]: d[feed].filter((p) => p.id !== id) }));
  const addFeedPost = (feed, extra = {}) => {
    const title = window.prompt("Title for the new video:");
    if (title === null) return;
    setData((d) => ({
      [feed]: [{
        id: `fr-${Date.now()}`, title: title.trim() || "Untitled",
        channel: d.profile.name, chHue: "#E56E42",
        views: 0, likes: 0, comments: 0, shares: 0,
        age: "now", duration: "0:16", poster: nextStockPhoto(), video: "", liked: false,
        ...extra,
      }, ...d[feed]],
    }));
  };
  const addFeedUpload = (feed, url, type) =>
    addFeedPost(feed, String(type || "").startsWith("video") ? { video: url, poster: "" } : { poster: url });

  const patchParty = (id, patch) => setData((d) => ({
    parties: d.parties.map((p) => (p.id === id ? { ...p, ...patch } : p)),
  }));
  const removeParty = (id) => setData((d) => ({ parties: d.parties.filter((p) => p.id !== id) }));
  const addParty = () => {
    const title = window.prompt("What are you watching?");
    if (title === null) return;
    setData((d) => ({
      parties: [{
        id: `fp-${Date.now()}`, title: title.trim() || "Movie night",
        host: d.profile.name, hostHue: "#E56E42", viewers: 3,
        poster: nextStockPhoto(), video: "", seats: ["Maya Kim", "Owen Frost", "Priya Nair"],
      }, ...d.parties],
    }));
  };

  const allPosts = [...data.shorts, ...data.discover];
  const channelVideos = allPosts.filter((p) => p.channel === data.profile.name);
  const openPost = (id) => setPlayer({ id });
  const openParty = (partyId) => setPlayer({ partyId });
  const playerPost = player?.id ? allPosts.find((p) => p.id === player.id) : null;
  const playerParty = player?.partyId ? data.parties.find((p) => p.id === player.partyId) : null;
  const patchPlayer = (patch) => {
    if (!player?.id) return;
    setData((d) => ({
      shorts: d.shorts.map((p) => (p.id === player.id ? { ...p, ...patch } : p)),
      discover: d.discover.map((p) => (p.id === player.id ? { ...p, ...patch } : p)),
    }));
  };

  return (
    <div className="relative flex h-full flex-col bg-black text-white">
      {canEdit && (
        <div className="absolute right-2 top-2 z-30 flex gap-1.5">
          <SaveToggle className="bg-white/10 text-white" app="frames"
            defaultName={`${data.name || "Frames"} page`} data={data} />
          <EditToggle editing={editing} onToggle={() => setEditing(!editing)} className="bg-white/10 text-white" />
        </div>
      )}

      <div className="min-h-0 flex-1">
        {tab === "shorts" && (
          <FramesFeed posts={data.shorts} editing={editing}
            patch={(id, patch) => patchFeed("shorts", id, patch)}
            remove={(id) => removeFeedPost("shorts", id)}
            addStock={() => addFeedPost("shorts")}
            upload={(url, type) => addFeedUpload("shorts", url, type)}
            onPlay={openPost} emptyNote="No shorts yet." />
        )}
        {tab === "discover" && (
          <FramesFeed posts={data.discover} editing={editing}
            patch={(id, patch) => patchFeed("discover", id, patch)}
            remove={(id) => removeFeedPost("discover", id)}
            addStock={() => addFeedPost("discover")}
            upload={(url, type) => addFeedUpload("discover", url, type)}
            onPlay={openPost} emptyNote="Nothing to discover yet." />
        )}
        {tab === "search" && <FramesSearch posts={allPosts} onPlay={openPost} />}
        {tab === "parties" && (
          <FramesParties parties={data.parties} editing={editing}
            patch={patchParty} remove={removeParty} add={addParty} onJoin={openParty} />
        )}
        {tab === "channel" && (
          <FramesChannel profile={data.profile} videos={channelVideos} editing={editing}
            patchProfile={(patch) => setData((d) => ({ profile: { ...d.profile, ...patch } }))}
            onPlay={openPost} />
        )}
      </div>

      {/* icons-only dock */}
      <div className="flex items-center justify-around border-t border-white/10 bg-black/80 px-4 pb-4 pt-2.5">
        {TABS.map(({ id, Icon }) => (
          <button key={id} onClick={() => setTab(id)} aria-label={id}
            className="flex h-10 w-10 items-center justify-center">
            <Icon size={22} className={tab === id ? "text-white" : "text-white/40"} />
          </button>
        ))}
      </div>

      {playerParty && (
        <FramesPlayer party
          post={{ ...playerParty, channel: playerParty.host, chHue: playerParty.hostHue, views: playerParty.viewers, age: "" }}
          onBack={() => setPlayer(null)} />
      )}
      {playerPost && (
        <FramesPlayer post={playerPost}
          onLike={() => patchPlayer({ liked: !playerPost.liked, likes: playerPost.likes + (playerPost.liked ? -1 : 1) })}
          onBack={() => setPlayer(null)} />
      )}
    </div>
  );
}