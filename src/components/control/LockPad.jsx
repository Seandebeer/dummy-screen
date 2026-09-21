import React, { useEffect, useRef, useState } from "react";
import { Lock, LockOpen } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { getScreenId } from "@/lib/deviceLink";
import { cn } from "@/lib/utils";

// Trackpad-style pad: a 3-finger tap anywhere on it toggles the target
// phone's takeover lock - the same gesture the prop screen itself uses.
export default function LockPad({ channel = "stage-1" }) {
  const [flash, setFlash] = useState(null); // "sent" | "error"
  // every screen_lock command flips the target screen's lock - track the
  // parity of commands on this channel so the pad shows the live state
  const [locked, setLocked] = useState(false);
  const lastFire = useRef(0);
  const clicks = useRef(0);
  const clickTimer = useRef(null);

  const fire = async () => {
    const now = Date.now();
    if (now - lastFire.current < 1000) return; // one toggle per gesture
    lastFire.current = now;
    clicks.current = 0;
    setFlash("sent");
    setTimeout(() => setFlash(null), 900);
    try {
      await base44.entities.Command.create({
        channel, type: "screen_lock", status: "pending",
        payload: JSON.stringify({ action: "toggle", source: getScreenId() }),
      });
    } catch {
      setFlash("error");
      setTimeout(() => setFlash(null), 900);
    }
  };

  // load parity of past toggles, then keep flipping on every new one
  useEffect(() => {
    let mounted = true;
    base44.entities.Command.filter({ channel, type: "screen_lock" }, "created_date", 500)
      .then((d) => { if (mounted) setLocked(d.length % 2 === 1); })
      .catch(() => {});
    const unsub = base44.entities.Command.subscribe((e) => {
      if (e.type === "create" && e.data?.type === "screen_lock" && e.data.channel === channel) {
        setLocked((v) => !v);
      }
    });
    return () => { mounted = false; unsub(); };
  }, [channel]);

  const onTouch = (e) => { if (e.touches.length >= 3) fire(); };

  // desktop fallback: three quick clicks do the same
  const onClick = () => {
    clicks.current += 1;
    clearTimeout(clickTimer.current);
    if (clicks.current >= 3) { clicks.current = 0; fire(); return; }
    clickTimer.current = setTimeout(() => { clicks.current = 0; }, 600);
  };

  return (
    <div className="rounded-[20px] border border-border/70 bg-surface/60 backdrop-blur-2xl shadow-[0_10px_32px_rgba(0,0,0,0.28)] p-5">
      <div className="mb-3 flex items-center gap-2">
        <LockOpen size={16} className="text-amber" />
        <span className="font-display font-semibold text-[15px] tracking-tight">Screen Lock Pad</span>
      </div>
      <button
        onTouchStart={onTouch} onClick={onClick}
        aria-label="Toggle target phone lock"
        className={cn("relative flex h-44 w-full select-none items-center justify-center overflow-hidden rounded-xl border bg-surface/40 grid-backdrop transition",
          flash === "error" ? "border-alert/60" : flash === "sent" ? "border-amber/50" : "border-border")}>
        {/* live target lock state */}
        <div className="flex flex-col items-center gap-3">
          {locked
            ? <Lock size={28} className="text-amber" />
            : <LockOpen size={28} className="text-muted-foreground" />}
          <div className="text-center">
            <div className="font-display text-sm font-semibold">{locked ? "Screen locked" : "Screen unlocked"}</div>
            <div className="text-[10px] font-body text-muted-foreground">3-finger tap to toggle</div>
          </div>
        </div>
        {flash === "sent" && (
          <span className="absolute inset-x-0 bottom-2 text-center text-[10px] font-body text-amber">Lock toggled</span>
        )}
        {flash === "error" && (
          <span className="absolute inset-x-0 bottom-2 text-center text-[10px] font-body text-alert">Failed to send</span>
        )}
      </button>
    </div>
  );
}