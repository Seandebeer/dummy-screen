import React from "react";
import { Link } from "react-router-dom";
import { Phone, MessageSquare, Mail, Clock, Contact, ArrowUpRight } from "lucide-react";

const apps = [
  { Icon: Phone, bg: "#34C759" },
  { Icon: MessageSquare, bg: "#34C759" },
  { Icon: Mail, bg: "#0A84FF" },
  { Icon: Clock, bg: "#FF9F0A" },
  { Icon: Contact, bg: "#5A5D6B" },
];

export default function PhoneMirror() {
  const now = new Date();
  const time = now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <div className="text-[11px] uppercase tracking-wider text-muted-foreground font-body">Active Mirror</div>
        <span className="flex items-center gap-1.5 text-[11px] font-body text-signal">
          <span className="h-2 w-2 rounded-full bg-signal led-pulse" /> SYNC
        </span>
      </div>
      <div className="mx-auto w-full max-w-[230px] aspect-[9/19] rounded-[2rem] bg-[#05060a] p-1.5 border border-border shadow-2xl">
        <div className="relative h-full w-full rounded-[1.7rem] overflow-hidden"
          style={{ background: "linear-gradient(160deg, #1a1d2e 0%, #0a0b14 60%, #000 100%)" }}>
          <div className="absolute top-0 inset-x-0 flex justify-between px-4 pt-1.5 text-[9px] text-white/80 font-body">
            <span>{time}</span><span>●● 5G ▮</span>
          </div>
          <div className="absolute top-0 left-1/2 -translate-x-1/2 h-3 w-12 rounded-b-lg bg-black" />
          <div className="pt-7 px-3 flex flex-col items-center">
            <div className="font-display text-2xl font-bold text-white">{time}</div>
            <div className="text-[8px] text-white/50">{now.toLocaleDateString([], { weekday: "short" })}</div>
          </div>
          <div className="grid grid-cols-4 gap-2 px-3 pt-3">
            {apps.map((a, i) => (
              <div key={i} className="flex flex-col items-center gap-0.5">
                <span className="h-8 w-8 rounded-xl flex items-center justify-center" style={{ background: a.bg }}>
                  <a.Icon size={14} className="text-white" />
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
      <Link to="/os" className="w-full rounded-lg border border-amber/40 bg-amber/10 text-amber font-display font-bold py-2.5 text-sm flex items-center justify-center gap-2 hover:bg-amber/20 transition">
        Launch OS <ArrowUpRight size={16} />
      </Link>
    </div>
  );
}