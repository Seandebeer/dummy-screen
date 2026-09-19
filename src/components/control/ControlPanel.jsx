import React, { useState, useEffect, useRef } from "react";
import { PhoneIncoming, PhoneOff, Send, Radio, Users } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { mockContacts } from "@/lib/osData";
import { cn } from "@/lib/utils";

export default function ControlPanel() {
  const [messages, setMessages] = useState([]);
  const [text, setText] = useState("");
  const [callState, setCallState] = useState("idle"); // idle | ringing | active | ended
  const [activeCmdId, setActiveCmdId] = useState(null);
  const [contact, setContact] = useState(mockContacts[0]);
  const [busy, setBusy] = useState(false);
  const scrollRef = useRef(null);

  // load + subscribe to messages
  useEffect(() => {
    let mounted = true;
    base44.entities.Message.filter({ thread_id: "stage-1" }, "created_date", 200)
      .then((d) => mounted && setMessages(d)).catch(() => {});
    const unsub = base44.entities.Message.subscribe((e) => {
      if (e.type === "create") setMessages((m) => [...m, e.data]);
    });
    return () => { mounted = false; unsub(); };
  }, []);

  // subscribe to command status updates (reflect phone answering/ending)
  useEffect(() => {
    const unsub = base44.entities.Command.subscribe((e) => {
      if (e.type === "update" && e.data.id === activeCmdId) {
        if (e.data.status === "active") setCallState("active");
        if (e.data.status === "completed") {
          setCallState("ended");
          setTimeout(() => setCallState("idle"), 1500);
          setActiveCmdId(null);
        }
      }
    });
    return () => unsub();
  }, [activeCmdId]);

  useEffect(() => {
    if (scrollRef.current) scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [messages]);

  const triggerCall = async (type) => {
    if (busy || callState !== "idle") return;
    setBusy(true);
    try {
      const rec = await base44.entities.Command.create({
        channel: "stage-1", type,
        contact_name: contact.name, contact_number: contact.number, status: "pending",
      });
      setActiveCmdId(rec.id);
      setCallState(type === "call_incoming" ? "ringing" : "active");
      if (type === "call_outgoing") {
        // OS auto-connects; reflect active shortly as fallback
        setTimeout(() => setCallState((s) => s === "active" ? "active" : "active"), 100);
      }
    } catch (e) {}
    setBusy(false);
  };

  const endCall = async () => {
    if (activeCmdId) {
      try { await base44.entities.Command.update(activeCmdId, { status: "completed" }); } catch (e) {}
    }
    setCallState("ended");
    setTimeout(() => setCallState("idle"), 1200);
    setActiveCmdId(null);
  };

  const sendMessage = async () => {
    if (!text.trim()) return;
    const body = text.trim();
    setText("");
    try {
      await base44.entities.Message.create({ thread_id: "stage-1", sender: "control", text: body, sender_name: "Control" });
    } catch (e) { setText(body); }
  };

  return (
    <div className="flex flex-col gap-4 h-full">
      {/* connection panel */}
      <div className="rounded-xl border border-border bg-surface p-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Radio size={16} className="text-signal" />
            <span className="font-display font-semibold text-sm">Target Device</span>
          </div>
          <span className="flex items-center gap-1.5 text-[11px] font-body text-signal">
            <span className="h-2 w-2 rounded-full bg-signal led-pulse" /> CONNECTED
          </span>
        </div>
        <div className="flex items-center gap-3 rounded-lg bg-muted/40 p-3">
          <div className="h-10 w-10 rounded-lg bg-amber/15 border border-amber/30 flex items-center justify-center">
            <Users size={18} className="text-amber" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="font-body text-sm font-semibold">PROP-01</div>
            <div className="text-[11px] text-muted-foreground font-body">channel stage-1 · OS mode</div>
          </div>
          <div className="text-right">
            <div className="text-[11px] text-muted-foreground font-body">CALL STATE</div>
            <div className={cn("text-xs font-body font-semibold uppercase",
              callState === "active" && "text-signal",
              callState === "ringing" && "text-amber amber-pulse",
              callState === "ended" && "text-alert",
              callState === "idle" && "text-muted-foreground")}>
              {callState}
            </div>
          </div>
        </div>
      </div>

      {/* call trigger pad */}
      <div className="rounded-xl border border-border bg-surface p-4">
        <div className="text-[11px] uppercase tracking-wider text-muted-foreground font-body mb-3">Call Trigger</div>
        <div className="flex items-center gap-2 mb-3">
          <select value={contact.id} onChange={(e) => setContact(mockContacts.find((c) => c.id === +e.target.value))}
            className="flex-1 bg-muted/40 border border-border rounded-lg px-3 py-2 text-sm font-body outline-none">
            {mockContacts.map((c) => <option key={c.id} value={c.id}>{c.name} · {c.number}</option>)}
          </select>
        </div>
        <div className="grid grid-cols-2 gap-2">
          <button onClick={() => triggerCall("call_incoming")} disabled={callState !== "idle" || busy}
            className="flex flex-col items-center gap-1.5 rounded-lg border border-signal/40 bg-signal/10 py-3 text-signal disabled:opacity-40 hover:bg-signal/20 transition">
            <PhoneIncoming size={20} />
            <span className="text-[11px] font-body">Call</span>
          </button>
          <button onClick={endCall} disabled={callState === "idle"}
            className="flex flex-col items-center gap-1.5 rounded-lg border border-alert/40 bg-alert/10 py-3 text-alert disabled:opacity-40 hover:bg-alert/20 transition">
            <PhoneOff size={20} />
            <span className="text-[11px] font-body">End</span>
          </button>
        </div>
      </div>

      {/* message console */}
      <div className="rounded-xl border border-border bg-surface p-4 flex-1 flex flex-col min-h-0">
        <div className="text-[11px] uppercase tracking-wider text-muted-foreground font-body mb-3">Message Push Console</div>
        <div ref={scrollRef} className="flex-1 overflow-auto no-scrollbar space-y-2 mb-3 min-h-[120px]">
          {messages.length === 0 && <div className="text-center text-muted-foreground text-xs py-6 font-body">No messages. Push one to the prop phone.</div>}
          {messages.map((m) => {
            const mine = m.sender === "control";
            return (
              <div key={m.id} className={cn("flex", mine ? "justify-end" : "justify-start")}>
                <div className={cn("max-w-[80%] rounded-lg px-3 py-2 text-sm",
                  mine ? "bg-amber/15 border border-amber/30 text-foreground" : "bg-signal/10 border border-signal/30 text-foreground")}>
                  {!mine && <div className="text-[10px] text-signal font-body mb-0.5">PHONE</div>}
                  <div className="font-body">{m.text}</div>
                </div>
              </div>
            );
          })}
        </div>
        <div className="flex items-center gap-2">
          <input value={text} onChange={(e) => setText(e.target.value)} onKeyDown={(e) => e.key === "Enter" && sendMessage()}
            placeholder="Type message to push…" className="flex-1 bg-muted/40 border border-border rounded-lg px-3 py-2 text-sm font-body outline-none focus:border-signal" />
          <button onClick={sendMessage} disabled={!text.trim()}
            className="h-9 w-9 rounded-lg bg-signal text-background flex items-center justify-center disabled:opacity-40 hover:brightness-110 transition">
            <Send size={16} />
          </button>
        </div>
      </div>
    </div>
  );
}