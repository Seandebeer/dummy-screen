import React, { useEffect, useRef, useState } from "react";
import { ChevronLeft, Send, Trash2 } from "lucide-react";
import { getClip } from "@/lib/cameraRoll";

const fmtDate = (t) => {
  const d = new Date(t);
  const time = d.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  if (d.toDateString() === new Date().toDateString()) return `Today at ${time}`;
  return `${d.toLocaleDateString([], { day: "numeric", month: "long", year: "numeric" })} at ${time}`;
};

function Slide({ item }) {
  const [clipUrl, setClipUrl] = useState(null);
  useEffect(() => {
    if (item.type !== "video") return undefined;
    let url = null;
    let dead = false;
    getClip(item.id).then((rec) => {
      if (dead || !rec?.blob) return;
      url = URL.createObjectURL(rec.blob);
      setClipUrl(url);
    });
    return () => { dead = true; if (url) URL.revokeObjectURL(url); setClipUrl(null); };
  }, [item.id]);
  if (item.type === "video") {
    return clipUrl
      ? <video src={clipUrl} controls autoPlay loop playsInline className="h-full w-full object-contain" />
      : <div className="flex h-full w-full items-center justify-center text-xs text-white/50">Loading clip…</div>;
  }
  return <img src={item.url} alt="" className="h-full w-full object-contain" />;
}

// Apple-style full-screen photo browser - swipe sideways between items
export default function PhotoViewer({ items, index, setIndex, light, onBack, onShare, onDelete }) {
  const [drag, setDrag] = useState(0);
  const start = useRef(null);

  const onDown = (e) => { start.current = e.clientX; };
  const onMove = (e) => { if (start.current !== null) setDrag(e.clientX - start.current); };
  const onUp = () => {
    if (start.current === null) return;
    const d = drag;
    start.current = null;
    setDrag(0);
    if (d > 60 && index > 0) setIndex(index - 1);
    else if (d < -60 && index < items.length - 1) setIndex(index + 1);
  };

  const item = items[index];
  return (
    <div className="absolute inset-0 z-20 flex flex-col bg-black text-white">
      <div className="flex items-center justify-between px-3 py-2.5">
        <button onClick={onBack} className="flex items-center gap-0.5 text-[#007AFF]">
          <ChevronLeft size={20} /> <span className="text-sm">{light ? "Photos" : "Library"}</span>
        </button>
        <div className="flex items-center gap-4">
          {onShare && (
            <button onClick={onShare} title="Send via Messages"
              className="flex items-center gap-1 text-[#007AFF]">
              <Send size={16} /> <span className="text-xs font-medium">Send</span>
            </button>
          )}
          <button onClick={onDelete} title="Delete"
            className="flex items-center gap-1 text-[#FF3B30]">
            <Trash2 size={16} /> <span className="text-xs font-medium">Delete</span>
          </button>
        </div>
      </div>
      <div className="pb-2 text-center">
        <div className="text-[13px] font-semibold">{fmtDate(item.created)}</div>
        <div className="text-[11px] text-white/50">{index + 1} of {items.length}</div>
      </div>
      <div className="flex-1 overflow-hidden touch-none"
        onPointerDown={onDown} onPointerMove={onMove} onPointerUp={onUp} onPointerCancel={onUp}>
        <div className="flex h-full"
          style={{
            transform: `translateX(calc(${-index * 100}% + ${drag}px))`,
            transition: start.current === null ? "transform 0.25s" : "none",
          }}>
          {items.map((it, i) => (
            Math.abs(i - index) <= 1
              ? <div key={it.id} className="h-full w-full shrink-0"><Slide item={it} /></div>
              : <div key={it.id} className="h-full w-full shrink-0" />
          ))}
        </div>
      </div>
    </div>
  );
}