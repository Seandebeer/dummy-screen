import React, { useState } from "react";
import { Delete, Phone, PhoneIncoming, PhoneMissed, PhoneOutgoing } from "lucide-react";
import { cn } from "@/lib/utils";
import { LANGUAGES } from "@/lib/osLanguages";

const keypad = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"];

const TYPE_META = {
  missed: { Icon: PhoneMissed, color: "#FF3B30" },
  incoming: { Icon: PhoneIncoming, color: "#34C759" },
  outgoing: { Icon: PhoneOutgoing, color: "#8E8E93" },
};

export default function PhoneApp({ onCall, recents = [], language = "en" }) {
  const [number, setNumber] = useState("");
  const [tab, setTab] = useState("recents");
  const t = LANGUAGES.find((l) => l.code === language)?.phone || LANGUAGES[0].phone;

  return (
    <div className="h-full bg-black text-white flex flex-col">
      <div className="flex border-b border-white/10">
        {["recents", "keypad"].map((k) => (
          <button key={k} onClick={() => setTab(k)}
            className={cn("flex-1 py-2.5 text-sm", tab === k ? "text-[#34C759] border-b-2 border-[#34C759]" : "text-white/40")}>
            {k === "recents" ? t.recents : t.keypad}
          </button>
        ))}
      </div>

      {tab === "recents" ? (
        <div className="flex-1 overflow-auto no-scrollbar px-4">
          {recents.length === 0 && <div className="text-center text-white/30 py-10 text-sm">{t.noCalls}</div>}
          {recents.map((r, i) => {
            const meta = TYPE_META[r.type] || TYPE_META.outgoing;
            return (
              <div key={i} className="flex items-center justify-between py-3 border-b border-white/5">
                <div className="min-w-0">
                  <div className={cn("font-medium truncate", r.type === "missed" && "text-[#FF3B30]")}>
                    {r.name || r.number || "Unknown"}
                  </div>
                  <div className="flex items-center gap-1.5 text-xs text-white/40 font-body">
                    <meta.Icon size={12} style={{ color: meta.color }} className="shrink-0" />
                    <span className="truncate">{[r.number, t[r.type], r.time].filter(Boolean).join(" · ")}</span>
                  </div>
                </div>
                <button onClick={() => onCall?.({ name: r.name, number: r.number })} className="text-[#34C759] shrink-0">
                  <Phone size={18} />
                </button>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="flex-1 flex flex-col items-center justify-between py-4">
          <div className="font-display text-4xl font-light min-h-[3rem] tracking-wide">{number || <span className="text-white/20">Enter number</span>}</div>
          <div className="grid grid-cols-3 gap-3">
            {keypad.map((k) => (
              <button key={k} onClick={() => setNumber((n) => n + k)}
                className="h-14 w-14 rounded-full bg-white/10 text-2xl font-display font-light active:bg-white/20">{k}</button>
            ))}
          </div>
          <div className="flex items-center gap-8">
            <div className="w-12" />
            <button onClick={() => number && onCall?.({ name: number, number })}
              className="h-14 w-14 rounded-full bg-[#34C759] flex items-center justify-center"><Phone size={24} className="text-black" /></button>
            <button onClick={() => setNumber((n) => n.slice(0, -1))} className="w-12 text-white/60"><Delete size={22} /></button>
          </div>
        </div>
      )}
    </div>
  );
}