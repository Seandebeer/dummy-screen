import React from "react";
import { Cloud } from "lucide-react";

// Android Holo home-screen clock + weather widget card
export default function HoloClockWidget({ clock }) {
  const now = new Date();
  const time = clock.mode === "custom" && clock.time
    ? clock.time
    : now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  const date = clock.mode === "custom" && clock.date
    ? clock.date
    : now.toLocaleDateString([], { weekday: "short", month: "short", day: "numeric" }).toUpperCase();

  return (
    <div className="overflow-hidden rounded-lg border border-[#2a5d99]/70 bg-black/30">
      <div className="flex items-stretch">
        <div className="flex-1 p-3">
          <div className="text-[10px] font-medium tracking-widest text-[#5fa6e5]">{date}</div>
          <div className="mt-0.5 text-[34px] font-light leading-none text-white">{time}</div>
          <div className="my-2 h-px bg-[#2a5d99]/70" />
          <div className="flex items-center gap-1.5 text-[11px] text-white/85">
            <Cloud size={13} className="text-[#5fa6e5]" />
            <span>San Francisco · 16°C</span>
          </div>
        </div>
        <div
          className="w-20 shrink-0"
          style={{ backgroundImage: "linear-gradient(180deg, #16304d 0%, #0c1828 60%, #060c14 100%)" }}
        />
      </div>
    </div>
  );
}