import React from "react";
import { Phone, MessageSquare, Mail, Clock, Contact } from "lucide-react";
import { cn } from "@/lib/utils";

const apps = [
  { id: "phone", label: "Phone", Icon: Phone, bg: "#34C759" },
  { id: "messages", label: "Messages", Icon: MessageSquare, bg: "#34C759" },
  { id: "email", label: "Mail", Icon: Mail, bg: "#0A84FF" },
  { id: "clock", label: "Clock", Icon: Clock, bg: "#FF9F0A" },
  { id: "contacts", label: "Contacts", Icon: Contact, bg: "#5A5D6B" },
];

export default function Homescreen({ onOpen }) {
  const now = new Date();
  const time = now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  const date = now.toLocaleDateString([], { weekday: "long", month: "long", day: "numeric" });

  return (
    <div className="h-full flex flex-col text-white relative overflow-hidden"
      style={{ background: "linear-gradient(160deg, #1a1d2e 0%, #0a0b14 60%, #000 100%)" }}>
      <div className="grid-backdrop absolute inset-0 opacity-30" />
      <div className="relative flex flex-col items-center pt-10 pb-4">
        <div className="font-display text-6xl font-bold tracking-tight">{time}</div>
        <div className="text-sm text-white/60 mt-1">{date}</div>
      </div>
      <div className="relative flex-1 grid grid-cols-4 gap-y-5 gap-x-3 px-5 content-start pt-4">
        {apps.map((a) => (
          <button key={a.id} onClick={() => onOpen(a.id)}
            className="flex flex-col items-center gap-1.5 active:scale-95 transition">
            <span className="h-14 w-14 rounded-2xl flex items-center justify-center shadow-lg"
              style={{ background: a.bg }}>
              <a.Icon size={26} className="text-white" />
            </span>
            <span className="text-[11px] text-white/80">{a.label}</span>
          </button>
        ))}
      </div>
      <div className="relative flex justify-center pb-6">
        <div className="h-32 w-32 rounded-3xl bg-white/5 border border-white/10 flex items-center justify-center text-white/30 text-xs">Swipe up</div>
      </div>
    </div>
  );
}