import React, { useRef, useState } from "react";
import { LockOpen } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { getScreenId } from "@/lib/deviceLink";
import { cn } from "@/lib/utils";

// Trackpad-style pad: a 3-finger tap anywhere on it toggles the target
// phone's takeover lock - the same gesture the prop screen itself uses.
export default function LockPad({ channel = "stage-1" }) {
  const [flash, setFlash] = useState(null); // "sent" | "error"
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

  const onTouch = (e) => { if (e.touches.length >= 3) fire(); };

  // desktop fallback: three quick clicks do the same
  const onClick = () => {
    clicks.current += 1;
    clearTimeout(clickTimer.current);
    if (clicks.current >= 3) { clicks.current = 0; fire(); return; }
    clickTimer.current = setTimeout(() => { clicks.current = 0; }, 600);
  };

  return (
    <div className="rounded-2xl border border-border/70 bg-surface/80 backdrop-blur-xl shadow-[0_8px_28px_rgba(0,0,0,0.2)] p-4">
      <div className="mb-3 flex items-center gap-2">
        <LockOpen size={16} className="text-amber" />
        <span className="font-display font-semibold text-sm">Screen Lock Pad</span>
      </div>
      <button
        onTouchStart={onTouch} onClick={onClick}
        aria-label="Toggle target phone lock"
        className={cn("relative flex h-44 w-full select-none items-center justify-center overflow-hidden rounded-xl border bg-surface/40 grid-backdrop transition",
          flash === "error" ? "border-alert/60" : flash === "sent" ? "border-amber/50" : "border-border")}>
        {/* three fingertip dots */}
        <div className="flex flex-col items-center gap-3">
          <div className="flex gap-2.5">
            {[0, 1, 2].map((i) => (
              <span key={i} className={cn("h-3.5 w-3.5 rounded-full border transition",
                flash === "sent" ? "border-amber bg-amber/40" : "border-muted-foreground/40 bg-muted/60")} />
            ))}
          </div>
          <div className="text-center">
            <div className="font-display text-sm font-semibold">3-finger tap</div>
            <div className="text-[10px] font-body text-muted-foreground">locks / unlocks the prop phone</div>
          </div>
        </div>
        {flash === "sent" && (
          <span className="absolute inset-x-0 bottom-2 text-center text-[10px] font-body text-amber">Lock toggled</span>
        )}
        {flash === "error" && (
          <span className="absolute inset-x-0 bottom-2 text-center text-[10px] font-body text-alert">Failed to send</span>
        )}
      </button>
      <div className="mt-2 text-[10px] font-body text-muted-foreground">
        Each tap flips every connected screen - same as a 3-finger tap on the phone itself (or three quick clicks here)
      </div>
    </div>
  );
}