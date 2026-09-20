import React, { useState, useEffect, useRef } from "react";
import { Phone, PhoneOff, Mic, MicOff, Volume2, Grid2x2, AlarmClock, MessageSquare } from "lucide-react";
import { Image } from "@/components/ui/image";
import { cn } from "@/lib/utils";

// horizontal slide-to-answer pill, styled like the iOS incoming call screen
function SlideToAnswer({ onAccept }) {
  const trackRef = useRef(null);
  const [x, setX] = useState(0);
  const [dragging, setDragging] = useState(false);
  const start = useRef(null);

  const maxX = () => Math.max(0, (trackRef.current?.clientWidth || 0) - 56);
  const progress = maxX() ? x / maxX() : 0;

  const onDown = (e) => {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    start.current = e.clientX;
    setDragging(true);
  };
  const onMove = (e) => {
    if (start.current === null) return;
    const dx = e.clientX - start.current;
    start.current = e.clientX;
    setX((cur) => Math.max(0, Math.min(maxX(), cur + dx)));
  };
  const onUp = () => {
    if (start.current === null) return;
    start.current = null;
    setDragging(false);
    if (x >= maxX()) onAccept?.();
    else setX(0);
  };

  return (
    <div ref={trackRef} onPointerDown={onDown} onPointerMove={onMove} onPointerUp={onUp} onPointerCancel={onUp}
      onContextMenu={(e) => e.preventDefault()}
      className="relative h-14 w-full max-w-[300px] cursor-pointer touch-none select-none overflow-hidden rounded-full bg-[#e0e0e0]/90">
      <span className="absolute inset-0 flex items-center justify-center text-[15px] font-medium font-body text-[#505050]"
        style={{ opacity: 1 - progress }}>
        slide to answer
      </span>
      <span className="absolute left-1 top-1 flex h-12 w-12 items-center justify-center rounded-full bg-white shadow-md"
        style={{ transform: `translateX(${x}px)`, transition: dragging ? "none" : "transform 0.25s ease-out" }}>
        <Phone size={22} className="text-[#66D57A]" />
      </span>
    </div>
  );
}

export default function CallOverlay({ call, onAccept, onEnd, answerMode = "tap", speaker, onSpeakerChange, muted, onMutedChange }) {
  const [duration, setDuration] = useState(0);
  const [localMuted, setLocalMuted] = useState(false);
  const [localSpeaker, setLocalSpeaker] = useState(false);
  // mic + speaker lift to the OS when given, so the control deck can drive them
  const mic = typeof muted === "boolean" ? muted : localMuted;
  const toggleMuted = () => onMutedChange ? onMutedChange(!muted) : setLocalMuted((m) => !m);
  // speaker is lifted to the OS when onSpeakerChange is given (proximity needs it)
  const spk = typeof speaker === "boolean" ? speaker : localSpeaker;
  const toggleSpeaker = () => onSpeakerChange ? onSpeakerChange(!speaker) : setLocalSpeaker((s) => !s);

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
  const fullPhoto = call.photoMode === "full" && contact?.image;
  const mm = String(Math.floor(duration / 60)).padStart(2, "0");
  const ss = String(duration % 60).padStart(2, "0");

  return (
    <div className="absolute inset-0 z-40 flex flex-col items-center justify-between py-16 px-6 text-white"
      style={{ background: fullPhoto ? "#000" : "linear-gradient(180deg, #1a1d2e 0%, #0a0b14 100%)" }}>
      {fullPhoto && (
        <>
          <Image src={contact.image} alt={name} className="absolute inset-0 h-full w-full" fittingType="fill" />
          <div className="absolute inset-0 bg-gradient-to-b from-black/30 via-black/10 to-black/60" />
        </>
      )}
      <div className="relative flex flex-col items-center mt-6">
        {!fullPhoto && (
          <div className="h-28 w-28 rounded-full bg-white/10 flex items-center justify-center font-display text-4xl font-bold mb-4 overflow-hidden">
            {contact?.image
              ? <Image src={contact.image} alt={name} className="h-full w-full" fittingType="fill" />
              : (name[0]?.toUpperCase() || "?")}
          </div>
        )}
        <div className="font-display text-3xl font-semibold">{name}</div>
        <div className="text-white/50 font-body text-sm mt-1">
          {phase === "incoming" && "incoming call…"}
          {phase === "outgoing" && "calling…"}
          {phase === "ringing" && "ringing…"}
          {phase === "active" && `${mm}:${ss}`}
        </div>
        {number && <div className="text-white/40 text-xs font-body mt-0.5">{number}</div>}
      </div>

      {phase === "incoming" ? (
        answerMode === "swipe" ? (
          <div className="relative flex w-full flex-col items-center gap-8">
            <div className="flex items-center gap-20">
              <button onClick={onEnd} className="flex flex-col items-center gap-1.5 text-white/90">
                <span className="h-12 w-12 rounded-full bg-white/15 flex items-center justify-center"><AlarmClock size={22} /></span>
                <span className="text-xs">Remind Me</span>
              </button>
              <button onClick={onEnd} className="flex flex-col items-center gap-1.5 text-white/90">
                <span className="h-12 w-12 rounded-full bg-white/15 flex items-center justify-center"><MessageSquare size={22} /></span>
                <span className="text-xs">Message</span>
              </button>
            </div>
            <SlideToAnswer onAccept={onAccept} />
            <button onClick={onEnd} className="flex flex-col items-center gap-2">
              <span className="h-14 w-14 rounded-full bg-[#FF3B30] flex items-center justify-center"><PhoneOff size={24} className="text-white" /></span>
              <span className="text-xs text-white/60">Decline</span>
            </button>
          </div>
        ) : (
          <div className="relative flex items-center gap-16">
            <button onClick={onEnd} className="flex flex-col items-center gap-2">
              <span className="h-16 w-16 rounded-full bg-[#FF3B30] flex items-center justify-center"><PhoneOff size={26} className="text-white" /></span>
              <span className="text-xs text-white/60">Decline</span>
            </button>
            <button onClick={onAccept} className="flex flex-col items-center gap-2">
              <span className="h-16 w-16 rounded-full bg-[#34C759] flex items-center justify-center animate-pulse"><Phone size={26} className="text-black" /></span>
              <span className="text-xs text-white/60">Accept</span>
            </button>
          </div>
        )
      ) : (
        <div className="relative flex flex-col items-center gap-6 w-full">
          <div className="grid grid-cols-3 gap-5 w-full max-w-[260px]">
            <button onClick={toggleMuted} className={cn("flex flex-col items-center gap-1.5")}>
              <span className={cn("h-14 w-14 rounded-full flex items-center justify-center", mic ? "bg-white text-black" : "bg-white/15")}>
                {mic ? <MicOff size={22} /> : <Mic size={22} />}
              </span>
              <span className="text-[11px] text-white/60">mute</span>
            </button>
            <button onClick={toggleSpeaker} className="flex flex-col items-center gap-1.5">
              <span className={cn("h-14 w-14 rounded-full flex items-center justify-center", spk ? "bg-white text-black" : "bg-white/15")}>
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