import React, { useMemo, useState } from "react";
import { Check, ChevronLeft, Images, Play, Send, Trash2 } from "lucide-react";
import { deletePhoto, getPhotos } from "@/lib/cameraRoll";
import { base44 } from "@/api/base44Client";
import { uploadRollItem } from "@/lib/sendMedia";
import { cn } from "@/lib/utils";
import PhotoViewer from "./photos/PhotoViewer";
import SendSheet from "./photos/SendSheet";

// Apple Photos-style gallery: month sections, tap to browse full-screen,
// select mode, delete, and send items into a Messages thread
export default function PhotosApp({ contacts = [], light = false, onBack }) {
  const [items, setItems] = useState(getPhotos);
  const [selectMode, setSelectMode] = useState(false);
  const [selected, setSelected] = useState(() => new Set());
  const [viewIndex, setViewIndex] = useState(null);
  const [sendOpen, setSendOpen] = useState(false);
  const [notice, setNotice] = useState("");
  const canSend = contacts.length > 0;

  const groups = useMemo(() => {
    const out = [];
    for (const p of items) {
      const d = new Date(p.created);
      const label = `${d.toLocaleString([], { month: "long" })} ${d.getFullYear()}`;
      if (!out.length || out[out.length - 1].label !== label) out.push({ label, items: [] });
      out[out.length - 1].items.push(p);
    }
    return out;
  }, [items]);

  const toggleSel = (id) => setSelected((s) => {
    const n = new Set(s);
    if (n.has(id)) n.delete(id);
    else n.add(id);
    return n;
  });

  const openViewer = (item) => setViewIndex(items.findIndex((i) => i.id === item.id));

  const deleteSelected = () => {
    for (const id of selected) deletePhoto(id);
    setItems(getPhotos());
    setSelected(new Set());
    setViewIndex(null);
  };

  const deleteOne = (id) => {
    setItems(deletePhoto(id));
    setViewIndex(null);
  };

  const shareItem = (item) => {
    setSelected(new Set([item.id]));
    setSendOpen(true);
  };

  const shareSelected = () => setSendOpen(true);

  // send every selected gallery item into the contact's Messages thread
  const sendTo = async (contact) => {
    setSendOpen(false);
    setNotice(`Sending to ${contact.name}…`);
    let ok = true;
    for (const id of selected) {
      const item = items.find((i) => i.id === id);
      if (!item) continue;
      try {
        const url = await uploadRollItem(item);
        if (!url) { ok = false; continue; }
        await base44.entities.Message.create({
          thread_id: String(contact.id), sender: "phone", text: "",
          media: url, media_type: item.type === "video" ? "video" : "photo",
          sender_name: contact.name, read: true,
        });
      } catch { ok = false; }
    }
    setNotice(ok ? `Sent to ${contact.name}` : "Couldn't send some items");
    setSelected(new Set());
    setSelectMode(false);
    setViewIndex(null);
    setTimeout(() => setNotice(""), 1800);
  };

  const root = cn("relative h-full flex flex-col overflow-hidden",
    light ? "bg-white text-black" : "bg-black text-white");

  // full-screen browser
  if (viewIndex !== null && items[viewIndex]) {
    const item = items[viewIndex];
    return (
      <div className={root}>
        <PhotoViewer items={items} index={viewIndex} setIndex={setViewIndex} light={light}
          onBack={() => setViewIndex(null)}
          onShare={canSend ? () => shareItem(item) : null}
          onDelete={() => deleteOne(item.id)} />
        {sendOpen && (
          <SendSheet contacts={contacts} light={light} count={selected.size}
            onPick={sendTo} onClose={() => setSendOpen(false)} />
        )}
        {notice && (
          <div className="pointer-events-none absolute inset-x-0 bottom-4 z-40 flex justify-center">
            <span className="rounded-full bg-black/70 px-3 py-1 text-[11px] font-medium text-white backdrop-blur">
              {notice}
            </span>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className={root}>
      <div className="flex items-center justify-between px-4 pt-3 pb-1">
        {onBack ? (
          <button onClick={onBack} className="flex items-center gap-0.5 text-[#007AFF]">
            <ChevronLeft size={20} /> <span className="text-sm">Camera</span>
          </button>
        ) : (
          <span className="font-display text-[22px] font-bold tracking-tight">Library</span>
        )}
        <button onClick={() => { setSelectMode((v) => !v); setSelected(new Set()); }}
          className="text-sm font-medium text-[#007AFF]">
          {selectMode ? "Done" : "Select"}
        </button>
      </div>

      <div className="flex-1 overflow-auto no-scrollbar">
        {items.length === 0 && (
          <div className="h-full flex flex-col items-center justify-center gap-2 px-8 text-center">
            <Images size={26} className="opacity-30" />
            <div className="text-xs opacity-50">No photos yet - capture them from the Camera</div>
          </div>
        )}
        {groups.map((g) => (
          <div key={g.label}>
            <div className="px-4 pb-1 pt-3 text-[13px] font-semibold">{g.label}</div>
            <div className="grid grid-cols-3 gap-[2px]">
              {g.items.map((p) => {
                const sel = selected.has(p.id);
                return (
                  <button key={p.id}
                    onClick={() => (selectMode ? toggleSel(p.id) : openViewer(p))}
                    className="relative aspect-square overflow-hidden">
                    <img src={p.type === "video" ? p.poster : p.url} alt=""
                      className="h-full w-full object-cover" />
                    {p.type === "video" && (
                      <span className="absolute bottom-1 right-1 rounded-full bg-black/45 p-0.5">
                        <Play size={10} className="text-white" />
                      </span>
                    )}
                    {selectMode && (
                      <span className={cn("absolute top-1 right-1 flex h-5 w-5 items-center justify-center rounded-full border",
                        sel ? "border-white bg-[#007AFF]" : "border-white/80 bg-black/25")}>
                        {sel && <Check size={12} className="text-white" />}
                      </span>
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        ))}
      </div>

      {selectMode && selected.size > 0 && (
        <div className={cn("flex items-center justify-between border-t px-4 py-2.5",
          light ? "border-black/10 bg-white" : "border-white/10 bg-black")}>
          <span className="text-[12px] opacity-60">{selected.size} selected</span>
          <div className="flex items-center gap-4">
            {canSend && (
              <button onClick={shareSelected} className="flex items-center gap-1 text-[#007AFF]">
                <Send size={15} /> <span className="text-xs font-medium">Send</span>
              </button>
            )}
            <button onClick={deleteSelected} className="flex items-center gap-1 text-[#FF3B30]">
              <Trash2 size={15} /> <span className="text-xs font-medium">Delete</span>
            </button>
          </div>
        </div>
      )}

      {sendOpen && (
        <SendSheet contacts={contacts} light={light} count={selected.size}
          onPick={sendTo} onClose={() => setSendOpen(false)} />
      )}
      {notice && (
        <div className="pointer-events-none absolute inset-x-0 bottom-4 z-40 flex justify-center">
          <span className="rounded-full bg-black/70 px-3 py-1 text-[11px] font-medium text-white backdrop-blur">
            {notice}
          </span>
        </div>
      )}
    </div>
  );
}