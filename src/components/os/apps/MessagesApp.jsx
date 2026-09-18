import React, { useState, useEffect, useRef } from "react";
import { Send, ChevronLeft } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { cn } from "@/lib/utils";

export default function MessagesApp() {
  const [messages, setMessages] = useState([]);
  const [text, setText] = useState("");
  const [loading, setLoading] = useState(true);
  const scrollRef = useRef(null);

  useEffect(() => {
    let mounted = true;
    base44.entities.Message.filter({ thread_id: "stage-1" }, "created_date", 200)
      .then((data) => { if (mounted) { setMessages(data); setLoading(false); } })
      .catch(() => { if (mounted) setLoading(false); });
    const unsub = base44.entities.Message.subscribe((event) => {
      if (event.type === "create") setMessages((m) => [...m, event.data]);
    });
    return () => { mounted = false; unsub(); };
  }, []);

  useEffect(() => {
    if (scrollRef.current) scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [messages]);

  const send = async () => {
    if (!text.trim()) return;
    const body = text.trim();
    setText("");
    try {
      await base44.entities.Message.create({ thread_id: "stage-1", sender: "phone", text: body, sender_name: "Phone" });
    } catch (e) { setText(body); }
  };

  return (
    <div className="h-full bg-black text-white flex flex-col">
      <div className="px-4 py-3 border-b border-white/10 flex items-center gap-3">
        <span className="h-9 w-9 rounded-full bg-[#34C759] flex items-center justify-center font-semibold text-black">C</span>
        <div>
          <div className="font-medium text-sm">Control Deck</div>
          <div className="text-[11px] text-[#34C759]">● connected</div>
        </div>
      </div>
      <div ref={scrollRef} className="flex-1 overflow-auto no-scrollbar px-3 py-3 space-y-2">
        {loading && <div className="text-center text-white/30 text-sm py-6">Loading…</div>}
        {!loading && messages.length === 0 && (
          <div className="text-center text-white/30 text-sm py-10">No messages yet.<br />Control can push a message from the deck.</div>
        )}
        {messages.map((m) => {
          const mine = m.sender === "phone";
          return (
            <div key={m.id} className={cn("flex", mine ? "justify-end" : "justify-start")}>
              <div className={cn("max-w-[75%] rounded-2xl px-3.5 py-2 text-sm",
                mine ? "bg-[#34C759] text-black rounded-br-md" : "bg-white/10 text-white rounded-bl-md")}>
                {m.text}
              </div>
            </div>
          );
        })}
      </div>
      <div className="flex items-center gap-2 px-3 py-2.5 border-t border-white/10">
        <input value={text} onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && send()}
          placeholder="Text message" className="flex-1 bg-white/10 rounded-full px-4 py-2 text-sm outline-none placeholder:text-white/30" />
        <button onClick={send} disabled={!text.trim()}
          className="h-9 w-9 rounded-full bg-[#34C759] flex items-center justify-center disabled:opacity-40">
          <Send size={16} className="text-black" />
        </button>
      </div>
    </div>
  );
}