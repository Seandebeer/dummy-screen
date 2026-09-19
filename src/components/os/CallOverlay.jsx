import React, { useState, useEffect } from "react";
import { Phone, PhoneOff, Mic, MicOff, Volume2, Grid2x2 } from "lucide-react";
import { Image } from "@/components/ui/image";
import { cn } from "@/lib/utils";

export default function CallOverlay({ call, onAccept, onEnd }) {
  const [duration, setDuration] = useState(0);
  const [muted, setMuted] = useState(false);
  const [speaker, setSpeaker] = useState(false);

  useEffect(() => {
    if (call?.phase === "active") {
      const start = call.startTime || Date.now();
      const id = setInterval(() => setDuration(Math.floor((Date.now() - start) / 1000)), 1000);
      return () => clearInterval(id);
    }
  }, [call?.phase, call?.startTime]);

  if (!call) return null;
  const { phase, contact } = call;
  const name = contact?.name || "Unknown";
  const number = contact?.number || "";
  const mm = String(Math.floor(duration / 60)).padStart(2, "0");
  const ss = String(duration % 60).padStart(2, "0");

  return (
    <div className="absolute inset-0 z-40 flex flex-col items-center justify-between py-16 px-6 text-white"
      style={{ background: "linear-gradient(180deg, #1a1d2e 0%, #0a0b14 100%)" }}>
      <div className="flex flex-col items-center mt-6">
        <div className="h-28 w-28 rounded-full bg-white/10 flex items-center justify-center font-display text-4xl font-bold mb-4 overflow-hidden">
          {contact?.image
            ? <Image src={contact.image} alt={name} className="h-full w-full" fittingType="fill" />
            : (name[0]?.toUpperCase() || "?")}
        </div>
        <div className="font-display text-3xl font-semibold">{name}</div>
        <div className="text-white/50 font-body text-sm mt-1">
          {phase === "incoming" && "incoming call…"}
          {phase === "outgoing" && "calling…"}
          {phase === "active" && `${mm}:${ss}`}
        </div>
        {number && <div className="text-white/40 text-xs font-body mt-0.5">{number}</div>}
      </div>

      {phase === "incoming" ? (
        <div className="flex items-center gap-16">
          <button onClick={onEnd} className="flex flex-col items-center gap-2">
            <span className="h-16 w-16 rounded-full bg-[#FF3B30] flex items-center justify-center"><PhoneOff size={26} className="text-white" /></span>
            <span className="text-xs text-white/60">Decline</span>
          </button>
          <button onClick={onAccept} className="flex flex-col items-center gap-2">
            <span className="h-16 w-16 rounded-full bg-[#34C759] flex items-center justify-center animate-pulse"><Phone size={26} className="text-black" /></span>
            <span className="text-xs text-white/60">Accept</span>
          </button>
        </div>
      ) : (
        <div className="flex flex-col items-center gap-6 w-full">
          <div className="grid grid-cols-3 gap-5 w-full max-w-[260px]">
            <button onClick={() => setMuted((m) => !m)} className={cn("flex flex-col items-center gap-1.5")}>
              <span className={cn("h-14 w-14 rounded-full flex items-center justify-center", muted ? "bg-white text-black" : "bg-white/15")}>
                {muted ? <MicOff size={22} /> : <Mic size={22} />}
              </span>
              <span className="text-[11px] text-white/60">mute</span>
            </button>
            <button onClick={() => setSpeaker((s) => !s)} className="flex flex-col items-center gap-1.5">
              <span className={cn("h-14 w-14 rounded-full flex items-center justify-center", speaker ? "bg-white text-black" : "bg-white/15")}>
                <Volume2 size={22} />
              </span>
              <span className="text-[11px] text-white/60">speaker</span>
            </button>
            <button className="flex flex-col items-center gap-1.5">
              <span className="h-14 w-14 rounded-full bg-white/15 flex items-center justify-center"><Grid2x2 size={22} /></span>
              <span className="text-[11px] text-white/60">keypad</span>
            </button>
          </div>
          <button onClick={onEnd} className="h-16 w-16 rounded-full bg-[#FF3B30] flex items-center justify-center">
            <PhoneOff size={28} className="text-white" />
          </button>
        </div>
      )}
    </div>
  );
}