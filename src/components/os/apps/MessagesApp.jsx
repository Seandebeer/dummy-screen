import React, { useState, useEffect, useRef } from "react";
import { Send, Search, ChevronLeft, ChevronRight, SquarePen, Minus, X } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { cn } from "@/lib/utils";
import { Image } from "@/components/ui/image";

const READ_KEY = "takeover-os-msg-read";

function loadRead() {
  try { return JSON.parse(localStorage.getItem(READ_KEY)) || {}; } catch { return {}; }
}
function saveRead(map) {
  try { localStorage.setItem(READ_KEY, JSON.stringify(map)); } catch {}
}

function fmtListTime(d) {
  const dt = new Date(d);
  const now = new Date();
  const sameDay = (a, b) => a.toDateString() === b.toDateString();
  if (sameDay(dt, now)) return dt.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  const yest = new Date(now); yest.setDate(now.getDate() - 1);
  if (sameDay(dt, yest)) return "Yesterday";
  if (now - dt < 6 * 86400000) return dt.toLocaleDateString([], { weekday: "long" });
  return dt.toLocaleDateString([], { day: "numeric", month: "short" });
}

const digits = (s) => (s || "").replace(/\D/g, "");

export default function MessagesApp({ contacts = [], initialTo, theme = "dark" }) {
  const dark = theme !== "light";
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [query, setQuery] = useState("");
  const [editMode, setEditMode] = useState(false);
  const [view, setView] = useState(() => (initialTo ? { type: "thread", id: String(initialTo.id) } : { type: "list" }));
  const [to, setTo] = useState("");
  const [newBody, setNewBody] = useState("");
  const [text, setText] = useState("");
  const [readMap, setReadMap] = useState(loadRead);
  const scrollRef = useRef(null);

  useEffect(() => {
    let mounted = true;
    base44.entities.Message.list("-created_date", 300)
      .then((data) => { if (mounted) { setMessages(data); setLoading(false); } })
      .catch(() => { if (mounted) setLoading(false); });
    const unsub = base44.entities.Message.subscribe((event) => {
      if (event.type === "create") setMessages((m) => (m.some((x) => x.id === event.data.id) ? m : [...m, event.data]));
    });
    return () => { mounted = false; unsub(); };
  }, []);

  // mark the open thread as read
  useEffect(() => {
    if (view.type !== "thread") return;
    setReadMap((m) => {
      const n = { ...m, [view.id]: new Date().toISOString() };
      saveRead(n);
      return n;
    });
  }, [view, messages.length]);

  useEffect(() => {
    if (scrollRef.current && view.type === "thread") scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [messages.length, view]);

  const nameFor = (tid) => {
    if (tid === "stage-1") return controlIdentity().name;
    const c = contacts.find((x) => String(x.id) === String(tid));
    return c ? c.name : tid;
  };
  // the identity the control deck last used (name + photo) shows on this OS
  const controlIdentity = () => {
    const last = threadMsgs("stage-1").filter((m) => m.sender === "control").slice(-1)[0];
    const name = last?.sender_name?.trim();
    return { name: name && name !== "Control" ? name : "Control Deck", image: last?.contact_image || "" };
  };
  const contactFor = (tid) => contacts.find((x) => String(x.id) === String(tid));
  const colorFor = (tid) => contactFor(tid)?.color || "#B9C1CB";

  const threadMsgs = (tid) =>
    messages.filter((m) => m.thread_id === tid).sort((a, b) => new Date(a.created_date) - new Date(b.created_date));

  const isUnread = (tid) => {
    const msgs = threadMsgs(tid);
    if (!msgs.length) return false;
    const last = msgs[msgs.length - 1];
    if (last.sender === "phone") return false;
    const seen = readMap[tid];
    return !seen || new Date(last.created_date) > new Date(seen);
  };

  const threadIds = Array.from(new Set(["stage-1", ...messages.map((m) => m.thread_id)]));
  if (initialTo && !threadIds.includes(String(initialTo.id))) threadIds.push(String(initialTo.id));
  threadIds.sort((a, b) => {
    const la = threadMsgs(a).slice(-1)[0]?.created_date;
    const lb = threadMsgs(b).slice(-1)[0]?.created_date;
    return new Date(lb || 0) - new Date(la || 0);
  });

  const visible = threadIds.filter((tid) =>
    nameFor(tid).toLowerCase().includes(query.toLowerCase()) ||
    (threadMsgs(tid).slice(-1)[0]?.text || "").toLowerCase().includes(query.toLowerCase())
  );

  const sendThread = async () => {
    if (!text.trim()) return;
    const body = text.trim();
    setText("");
    try {
      await base44.entities.Message.create({ thread_id: view.id, sender: "phone", text: body, sender_name: "Phone" });
    } catch { setText(body); }
  };

  const sendNew = async () => {
    const q = to.trim();
    if (!q || !newBody.trim()) return;
    const body = newBody.trim();
    const contact = contacts.find((c) =>
      c.name.toLowerCase() === q.toLowerCase() ||
      (digits(q) && digits(c.number).endsWith(digits(q)))
    );
    const threadId = contact ? String(contact.id) : q;
    setTo("");
    setNewBody("");
    try {
      await base44.entities.Message.create({ thread_id: threadId, sender: "phone", text: body, sender_name: contact?.name || q });
      setView({ type: "thread", id: threadId });
    } catch {}
  };

  const deleteThread = async (tid) => {
    setMessages((m) => m.filter((x) => x.thread_id !== tid));
    try { await base44.entities.Message.deleteMany({ thread_id: tid }); } catch {}
  };

  const suggestion = to.trim()
    ? contacts.find((c) => c.name.toLowerCase().startsWith(to.trim().toLowerCase()) || digits(c.number).startsWith(digits(to)))
    : null;

  // thread view
  if (view.type === "thread") {
    const tid = view.id;
    const msgs = threadMsgs(tid);
    return (
      <div className={cn("h-full flex flex-col", dark ? "bg-[#0b0b0f] text-white" : "bg-white text-black")}>
        <div className={cn("flex items-center gap-2 px-3 py-2.5 border-b", dark ? "border-white/10" : "border-black/10")}>
          <button onClick={() => setView({ type: "list" })} className="flex items-center gap-0.5 text-[#007AFF]"><ChevronLeft size={20} /> <span className="text-sm">Messages</span></button>
          <span className="flex-1 text-center text-[15px] font-semibold truncate">{nameFor(tid)}</span>
          <span className="w-16" />
        </div>
        <div ref={scrollRef} className="flex-1 overflow-auto no-scrollbar px-3 py-3 space-y-1.5">
          {loading && <div className={cn("text-center text-sm py-6", dark ? "text-white/30" : "text-black/30")}>Loading…</div>}
          {!loading && msgs.length === 0 && (
            <div className={cn("text-center text-sm py-10", dark ? "text-white/40" : "text-black/40")}>No messages with {nameFor(tid)} yet.</div>
          )}
          {msgs.map((m) => {
            const mine = m.sender === "phone";
            return (
              <div key={m.id} className={cn("flex", mine ? "justify-end" : "justify-start")}>
                <div className={cn("max-w-[75%] rounded-2xl px-3.5 py-2 text-sm",
                  mine ? "bg-[#007AFF] text-white rounded-br-md" : dark ? "bg-[#3A3A3C] text-white rounded-bl-md" : "bg-[#E9E9EB] text-black rounded-bl-md")}>
                  {m.text}
                </div>
              </div>
            );
          })}
        </div>
        <div className={cn("flex items-center gap-2 px-3 py-2.5 border-t", dark ? "border-white/10" : "border-black/10")}>
          <input value={text} onChange={(e) => setText(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && sendThread()}
            placeholder="Text message" className={cn("flex-1 rounded-full border px-4 py-2 text-sm outline-none", dark ? "border-white/15 placeholder:text-white/30" : "border-black/15 placeholder:text-black/30")} />
          <button onClick={sendThread} disabled={!text.trim()}
            className="h-9 w-9 rounded-full bg-[#007AFF] flex items-center justify-center disabled:opacity-30">
            <Send size={16} className="text-white" />
          </button>
        </div>
      </div>
    );
  }

  // compose view
  if (view.type === "compose") {
    return (
      <div className={cn("h-full flex flex-col", dark ? "bg-[#0b0b0f] text-white" : "bg-white text-black")}>
        <div className={cn("flex items-center justify-between px-3 py-2.5 border-b", dark ? "border-white/10" : "border-black/10")}>
          <button onClick={() => setView({ type: "list" })} className="flex items-center gap-0.5 text-[#007AFF]"><ChevronLeft size={20} /> <span className="text-sm">Messages</span></button>
          <span className="text-[15px] font-semibold">New Message</span>
          <button onClick={sendNew} disabled={!to.trim() || !newBody.trim()}
            className={cn("text-sm font-semibold text-[#007AFF]", dark ? "disabled:text-white/25" : "disabled:text-black/25")}>Send</button>
        </div>
        <div className="flex-1 overflow-auto no-scrollbar px-4 py-4">
          <div className={cn("flex items-center gap-2 border-b pb-2.5", dark ? "border-white/10" : "border-black/10")}>
            <span className={cn("text-sm shrink-0", dark ? "text-white/50" : "text-black/50")}>To:</span>
            <input autoFocus value={to} onChange={(e) => setTo(e.target.value)} placeholder="Name or number"
              className={cn("flex-1 bg-transparent text-sm outline-none", dark ? "placeholder:text-white/30" : "placeholder:text-black/30")} />
            {to && <button onClick={() => setTo("")} className={dark ? "text-white/30" : "text-black/30"}><X size={14} /></button>}
          </div>
          {suggestion && to.toLowerCase() !== suggestion.name.toLowerCase() && (
            <button onClick={() => setTo(suggestion.name)} className={cn("w-full flex items-center gap-2.5 px-1 py-2.5 border-b text-left", dark ? "border-white/10" : "border-black/10")}>
              <span className="h-8 w-8 rounded-full flex items-center justify-center text-xs font-semibold" style={{ background: suggestion.color, color: "#000" }}>{suggestion.initials}</span>
              <span className="text-sm font-medium">{suggestion.name}</span>
            </button>
          )}
          <textarea autoFocus={false} value={newBody} onChange={(e) => setNewBody(e.target.value)} rows={6} placeholder="message"
            className={cn("w-full bg-transparent text-sm outline-none resize-none mt-3", dark ? "placeholder:text-white/30" : "placeholder:text-black/30")} />
        </div>
        <div className="flex items-center justify-center gap-2 px-4 pb-4">
          <button onClick={sendNew} disabled={!to.trim() || !newBody.trim()}
            className={cn("h-10 w-10 rounded-full bg-[#007AFF] flex items-center justify-center", dark ? "disabled:bg-white/15" : "disabled:bg-black/15")}>
            <Send size={18} className="text-white" />
          </button>
        </div>
      </div>
    );
  }

  // list view
  return (
    <div className={cn("h-full flex flex-col", dark ? "bg-[#0b0b0f] text-white" : "bg-white text-black")}>
      <div className="px-4 pt-2 pb-2 flex items-center justify-between">
        <button onClick={() => setEditMode((v) => !v)} className="text-sm text-[#007AFF]">{editMode ? "Done" : "Edit"}</button>
        <span className="font-display text-[22px] font-bold tracking-tight">Messages</span>
        <span className="w-10" />
      </div>
      <div className="flex-1 overflow-auto no-scrollbar">
        {loading && <div className={cn("text-center text-sm py-6", dark ? "text-white/30" : "text-black/30")}>Loading…</div>}
        {!loading && visible.length === 0 && (
          <div className={cn("text-center text-sm py-10", dark ? "text-white/40" : "text-black/40")}>No messages.</div>
        )}
        {visible.map((tid) => {
          const msgs = threadMsgs(tid);
          const last = msgs[msgs.length - 1];
          const name = nameFor(tid);
          const snippet = last ? last.text : "No messages yet";
          const c = contactFor(tid);
          const ctrl = tid === "stage-1" ? controlIdentity() : null;
          return (
            <button key={tid}
              onClick={() => (editMode ? deleteThread(tid) : setView({ type: "thread", id: tid }))}
              className={cn("w-full flex items-center gap-2.5 px-4 py-2.5 border-b text-left", dark ? "border-white/[0.08]" : "border-black/[0.08]")}>
              {editMode ? (
                <span className="h-6 w-6 rounded-full bg-[#FF3B30] flex items-center justify-center shrink-0"><Minus size={14} className="text-white" /></span>
              ) : (
                <span className={cn("h-2 w-2 rounded-full shrink-0", isUnread(tid) ? "bg-[#007AFF]" : "bg-transparent")} />
              )}
              <span className="h-11 w-11 rounded-full flex items-center justify-center font-semibold text-sm shrink-0 overflow-hidden" style={{ background: colorFor(tid), color: tid === "stage-1" && !c ? "#fff" : "#000" }}>
                {ctrl?.image ? (
                  <Image src={ctrl.image} alt="" className="h-full w-full" fittingType="fill" />
                ) : tid === "stage-1" && !c ? "C" : (c?.initials || name.slice(0, 2).toUpperCase())}
              </span>
              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between gap-2">
                  <span className={cn("text-[15px] truncate", isUnread(tid) ? "font-semibold" : "font-medium")}>{name}</span>
                  <span className="flex items-center gap-1 text-[13px] text-[#8E8E93] shrink-0">
                    {last ? fmtListTime(last.created_date) : ""}
                    <ChevronRight size={14} className={dark ? "text-white/25" : "text-black/25"} />
                  </span>
                </div>
                <div className="text-[14px] text-[#8E8E93] truncate">{snippet}</div>
              </div>
            </button>
          );
        })}
      </div>
      <div className="px-4 pt-2 pb-3">
        <div className={cn("flex items-center gap-3 rounded-full px-4 py-2 shadow-sm", dark ? "bg-white/10" : "bg-[#F2F2F7]")}>
          <Search size={16} className="text-[#8E8E93] shrink-0" />
          <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search"
            className="flex-1 bg-transparent outline-none text-sm placeholder:text-[#8E8E93]" />
          <button onClick={() => setView({ type: "compose" })} className="shrink-0">
            <SquarePen size={18} className="text-[#007AFF]" />
          </button>
        </div>
      </div>
    </div>
  );
}