import React, { useState, useEffect } from "react";
import { Search, ChevronLeft, Archive, Trash2 } from "lucide-react";
import { mockEmails } from "@/lib/osData";
import { cn } from "@/lib/utils";
import { scheduleDeviceSync } from "@/lib/cloudSync";

const KEY = "takeover-os-emails";

// every email is a conversation: a thread of { who: "them" | "me", body, time }
const withThread = (e) => (Array.isArray(e.thread) && e.thread.length
  ? e
  : { ...e, thread: [{ who: "them", body: e.body || "", time: e.time || "" }] });

const loadEmails = () => {
  try {
    const saved = JSON.parse(localStorage.getItem(KEY));
    if (Array.isArray(saved) && saved.length) return saved.map(withThread);
  } catch {}
  return mockEmails.map(withThread);
};

const previewOf = (thread) => (thread[0]?.body || "").slice(0, 90);
const nowTime = () => new Date().toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });

export default function EmailApp({ initialTo, locked, fullscreen }) {
  // conversation building only works while the screen lock is unlocked and
  // the stage isn't in a locked fullscreen takeover
  const canEdit = !locked && !fullscreen;
  const [emails, setEmails] = useState(loadEmails);
  const [openId, setOpenId] = useState(null);
  const [query, setQuery] = useState("");
  const [editMode, setEditMode] = useState(false);
  const [replyText, setReplyText] = useState("");
  const [compose, setCompose] = useState(() => (initialTo ? { to: initialTo.email || "", subject: "", body: "" } : null));

  useEffect(() => { if (!canEdit) setEditMode(false); }, [canEdit]);

  const persist = (updater) => {
    setEmails((prev) => {
      const next = updater(prev);
      try { localStorage.setItem(KEY, JSON.stringify(next)); } catch {}
      return next;
    });
    scheduleDeviceSync();
  };

  const patchEmail = (id, patch) => persist((prev) => prev.map((e) => (e.id === id ? { ...withThread(e), ...patch } : e)));
  const patchMsg = (id, idx, patch) => persist((prev) => prev.map((e) => {
    if (e.id !== id) return e;
    const thread = withThread(e).thread.map((t, i) => (i === idx ? { ...t, ...patch } : t));
    return { ...e, thread, preview: previewOf(thread) };
  }));
  // build the conversation from both sides - "Them" adds the sender's reply,
  // "Me" adds this phone's reply
  const addMsg = (id, who) => {
    if (!replyText.trim()) return;
    const body = replyText.trim();
    setReplyText("");
    persist((prev) => prev.map((e) => {
      if (e.id !== id) return e;
      return { ...withThread(e), thread: [...withThread(e).thread, { who, body, time: nowTime() }] };
    }));
  };
  const deleteMsg = (id, idx) => persist((prev) => prev.map((e) => {
    if (e.id !== id) return e;
    const thread = withThread(e).thread.filter((_, i) => i !== idx);
    return { ...e, thread, preview: previewOf(thread) };
  }));

  const open = emails.find((e) => e.id === openId);
  const filtered = emails.filter((e) =>
    e.from.toLowerCase().includes(query.toLowerCase()) || e.subject.toLowerCase().includes(query.toLowerCase())
  );
  const unreadCount = emails.filter((e) => e.unread).length;

  if (compose) {
    const canSend = compose.to.trim() && compose.body.trim();
    return (
      <div className="h-full bg-black text-white flex flex-col">
        <div className="flex items-center justify-between px-3 py-2 border-b border-white/10">
          <button onClick={() => setCompose(null)} className="flex items-center gap-1 text-[#0A84FF]"><ChevronLeft size={20} /> Inbox</button>
          <span className="text-sm font-medium">New Message</span>
          <button onClick={() => setCompose(null)} disabled={!canSend}
            className={cn("text-sm font-semibold", canSend ? "text-[#0A84FF]" : "text-white/25")}>
            Send
          </button>
        </div>
        <div className="flex-1 overflow-auto no-scrollbar px-4 pt-4 space-y-3">
          <input value={compose.to} onChange={(e) => setCompose({ ...compose, to: e.target.value })} placeholder="To:"
            className="w-full bg-transparent border-b border-white/10 pb-2.5 text-sm outline-none placeholder:text-white/30" />
          <input value={compose.subject} onChange={(e) => setCompose({ ...compose, subject: e.target.value })} placeholder="Subject"
            className="w-full bg-transparent border-b border-white/10 pb-2.5 text-sm outline-none placeholder:text-white/30" />
          <textarea value={compose.body} onChange={(e) => setCompose({ ...compose, body: e.target.value })} rows={8} placeholder="Body"
            className="w-full rounded-xl bg-white/5 p-3 text-sm outline-none resize-none placeholder:text-white/30" />
        </div>
      </div>
    );
  }

  if (open) {
    const thread = withThread(open).thread;
    return (
      <div className="h-full bg-black text-white flex flex-col">
        <div className="flex items-center justify-between px-3 py-2 border-b border-white/10">
          <button onClick={() => { setOpenId(null); setEditMode(false); }} className="flex items-center gap-1 text-[#0A84FF]"><ChevronLeft size={20} /> Inbox</button>
          {canEdit && (
            <button onClick={() => setEditMode((v) => !v)} className="text-sm text-[#0A84FF]">{editMode ? "Done" : "Edit"}</button>
          )}
        </div>
        <div className="flex-1 overflow-auto no-scrollbar px-4 py-3">
          {editMode ? (
            <input value={open.subject} onChange={(e) => patchEmail(open.id, { subject: e.target.value })}
              className="w-full bg-transparent font-display text-xl font-bold outline-none mb-3" />
          ) : (
            <h2 className="font-display text-xl font-bold mb-3">{open.subject}</h2>
          )}
          {thread.map((t, i) => (
            <div key={i} className="mb-4">
              <div className="flex items-center gap-2 mb-1.5">
                <span className={cn("h-9 w-9 rounded-full flex items-center justify-center text-sm font-semibold shrink-0",
                  t.who === "me" ? "bg-[#34C759]" : "bg-[#0A84FF]")}>
                  {t.who === "me" ? "M" : (open.from[0] || "?")}
                </span>
                <div className="min-w-0">
                  <div className="text-sm font-medium truncate">{t.who === "me" ? "Me" : open.from}</div>
                  <div className="text-xs text-white/40">{t.time || ""}</div>
                </div>
                {editMode && thread.length > 1 && (
                  <button onClick={() => deleteMsg(open.id, i)} aria-label="Remove message"
                    className="ml-auto text-white/40 hover:text-[#FF3B30] transition"><Trash2 size={14} /></button>
                )}
              </div>
              {editMode ? (
                <textarea value={t.body} onChange={(e) => patchMsg(open.id, i, { body: e.target.value })} rows={4}
                  className="w-full rounded-xl bg-white/5 p-3 text-sm outline-none resize-none" />
              ) : (
                <p className="text-sm leading-relaxed whitespace-pre-line text-white/80">{t.body}</p>
              )}
            </div>
          ))}
        </div>
        {editMode && (
          <div className="flex items-center gap-2 border-t border-white/10 px-3 py-2.5">
            <input value={replyText} onChange={(e) => setReplyText(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && addMsg(open.id, "them")}
              placeholder="Add to the conversation…"
              className="flex-1 rounded-full bg-white/10 px-4 py-2 text-sm outline-none placeholder:text-white/30" />
            <button onClick={() => addMsg(open.id, "them")} disabled={!replyText.trim()}
              className="rounded-lg border border-white/15 px-2.5 py-2 text-[11px] font-medium text-white/80 disabled:opacity-30">Them</button>
            <button onClick={() => addMsg(open.id, "me")} disabled={!replyText.trim()}
              className="rounded-lg bg-[#34C759] px-2.5 py-2 text-[11px] font-medium text-white disabled:opacity-30">Me</button>
          </div>
        )}
        <div className="flex border-t border-white/10">
          <button onClick={() => patchEmail(open.id, { unread: false })}
            className="flex-1 flex flex-col items-center gap-1 py-3 text-xs text-white/60"><Archive size={18} /> Mark read</button>
          <button onClick={() => { persist((prev) => prev.filter((e) => e.id !== open.id)); setOpenId(null); }}
            className="flex-1 flex flex-col items-center gap-1 py-3 text-xs text-[#FF3B30]"><Trash2 size={18} /> Delete</button>
        </div>
      </div>
    );
  }

  return (
    <div className="h-full bg-black text-white flex flex-col">
      <div className="px-4 pt-2 pb-3">
        <div className="flex items-center justify-between mb-3">
          <h2 className="font-display text-2xl font-bold">Inbox{unreadCount > 0 && <span className="ml-2 text-xs align-middle text-white/50">{unreadCount} unread</span>}</h2>
        </div>
        <div className="flex items-center gap-2 rounded-xl bg-white/10 px-3 py-2">
          <Search size={16} className="text-white/40" />
          <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search mail" className="bg-transparent outline-none text-sm flex-1 placeholder:text-white/30" />
        </div>
      </div>
      <div className="flex-1 overflow-auto no-scrollbar">
        {filtered.map((e) => (
          <button key={e.id} onClick={() => { setOpenId(e.id); patchEmail(e.id, { unread: false }); }}
            className={cn("w-full flex gap-3 px-4 py-3 border-b border-white/5 text-left", e.unread && "bg-white/[0.03]")}>
            <span className={cn("mt-1 h-2 w-2 rounded-full shrink-0", e.unread ? "bg-[#0A84FF]" : "bg-transparent")} />
            <div className="min-w-0 flex-1">
              <div className="flex justify-between gap-2">
                <span className={cn("text-sm truncate", e.unread ? "font-semibold" : "text-white/60")}>{e.from}</span>
                <span className="text-[11px] text-white/40 shrink-0">{(withThread(e).thread.slice(-1)[0]?.time) || e.time}</span>
              </div>
              <div className={cn("text-sm truncate", e.unread ? "font-medium" : "text-white/50")}>{e.subject}</div>
              <div className="text-xs text-white/35 truncate">{e.preview}</div>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}