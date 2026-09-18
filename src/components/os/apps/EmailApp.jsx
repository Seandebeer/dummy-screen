import React, { useState } from "react";
import { Search, ChevronLeft, Archive, Trash2 } from "lucide-react";
import { mockEmails } from "@/lib/osData";
import { cn } from "@/lib/utils";

export default function EmailApp() {
  const [emails, setEmails] = useState(mockEmails);
  const [openId, setOpenId] = useState(null);
  const [query, setQuery] = useState("");

  const open = emails.find((e) => e.id === openId);
  const filtered = emails.filter((e) =>
    e.from.toLowerCase().includes(query.toLowerCase()) || e.subject.toLowerCase().includes(query.toLowerCase())
  );
  const unreadCount = emails.filter((e) => e.unread).length;

  if (open) {
    return (
      <div className="h-full bg-black text-white flex flex-col">
        <div className="flex items-center gap-2 px-3 py-2 border-b border-white/10">
          <button onClick={() => setOpenId(null)} className="flex items-center gap-1 text-[#0A84FF]"><ChevronLeft size={20} /> Inbox</button>
        </div>
        <div className="flex-1 overflow-auto no-scrollbar px-4 py-3">
          <h2 className="font-display text-xl font-bold mb-2">{open.subject}</h2>
          <div className="flex items-center gap-2 mb-4">
            <span className="h-9 w-9 rounded-full bg-[#0A84FF] flex items-center justify-center text-sm font-semibold">{open.from[0]}</span>
            <div className="min-w-0">
              <div className="text-sm font-medium truncate">{open.from}</div>
              <div className="text-xs text-white/40">{open.time}</div>
            </div>
          </div>
          <p className="text-sm leading-relaxed whitespace-pre-line text-white/80">{open.body}</p>
        </div>
        <div className="flex border-t border-white/10">
          <button onClick={() => setEmails((arr) => arr.map((e) => e.id === open.id ? { ...e, unread: false } : e))}
            className="flex-1 flex flex-col items-center gap-1 py-3 text-xs text-white/60"><Archive size={18} /> Mark read</button>
          <button onClick={() => { setEmails((arr) => arr.filter((e) => e.id !== open.id)); setOpenId(null); }}
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
          <button key={e.id} onClick={() => { setOpenId(e.id); setEmails((arr) => arr.map((x) => x.id === e.id ? { ...x, unread: false } : x)); }}
            className={cn("w-full flex gap-3 px-4 py-3 border-b border-white/5 text-left", e.unread && "bg-white/[0.03]")}>
            <span className={cn("mt-1 h-2 w-2 rounded-full shrink-0", e.unread ? "bg-[#0A84FF]" : "bg-transparent")} />
            <div className="min-w-0 flex-1">
              <div className="flex justify-between gap-2">
                <span className={cn("text-sm truncate", e.unread ? "font-semibold" : "text-white/60")}>{e.from}</span>
                <span className="text-[11px] text-white/40 shrink-0">{e.time}</span>
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