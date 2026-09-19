import React, { useState } from "react";
import { Lock } from "lucide-react";
import PasscodePad from "./PasscodePad";
import PatternPad from "./PatternPad";
import FaceScan from "./FaceScan";
import FingerprintSensor from "./FingerprintSensor";
import SwipeUpUnlock from "./SwipeUpUnlock";
import LockNotifications from "./LockNotifications";
import { bgPresets } from "@/hooks/useOsConfig";
import { cn } from "@/lib/utils";

export default function LockScreen({ config, update, onUnlock, notifications = [], onOpenNotification }) {
  const lock = config.lockscreen || {};
  const method = lock.type || "none";
  const light = config.theme === "light";

  const [entry, setEntry] = useState("");
  const [stage, setStage] = useState(
    method === "passcode" ? (config.passcode ? "unlock" : "set")
      : method === "pattern" ? (config.pattern ? "unlock" : "set")
      : "unlock"
  );
  const [first, setFirst] = useState("");
  const [message, setMessage] = useState("");
  const [shake, setShake] = useState(0);

  const now = new Date();
  const time = config.clock.mode === "custom" && config.clock.time
    ? config.clock.time
    : now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  const date = config.clock.mode === "custom" && config.clock.date
    ? config.clock.date
    : now.toLocaleDateString([], { weekday: "long", month: "long", day: "numeric" });

  // lock screen background: custom image > custom preset > follow home background
  const lb = lock.background || {};
  const lockHasImage = lb.type === "image" && lb.url;
  const lockPreset = lb.preset && lb.preset !== "default" ? bgPresets.find((p) => p.id === lb.preset) : null;
  const homeHasImage = config.background.type === "image" && config.background.url;
  const hasImage = lockHasImage || (!lockPreset && homeHasImage);
  const preset = lockPreset || bgPresets.find((p) => p.id === config.background.preset) || bgPresets[0];
  const backgroundStyle = hasImage
    ? { backgroundImage: `url(${lockHasImage ? lb.url : config.background.url})`, backgroundSize: "cover", backgroundPosition: "center" }
    : { background: preset[light ? "light" : "dark"] };

  const fail = (msg) => {
    setMessage(msg);
    setShake((n) => n + 1);
    setEntry("");
  };

  const submitPasscode = (code) => {
    if (stage === "unlock") {
      if (code === config.passcode) onUnlock();
      else fail("Wrong passcode - try again");
    } else if (stage === "set") {
      setFirst(code);
      setStage("confirm");
      setEntry("");
    } else if (first === code) {
      update({ passcode: code });
      onUnlock();
    } else {
      setStage("set");
      setFirst("");
      fail("Passcodes didn't match - try again");
    }
  };

  const press = (d) => {
    if (entry.length >= 4) return;
    setMessage("");
    const next = entry + d;
    setEntry(next);
    if (next.length === 4) setTimeout(() => submitPasscode(next), 150);
  };

  const completePattern = (code) => {
    if (stage === "unlock") {
      if (code === config.pattern) onUnlock();
      else fail("Wrong pattern - try again");
    } else if (stage === "set") {
      setFirst(code);
      setStage("confirm");
    } else if (first === code) {
      update({ pattern: code });
      onUnlock();
    } else {
      setStage("set");
      setFirst("");
      fail("Patterns didn't match - try again");
    }
  };

  const heading =
    method === "passcode"
      ? stage === "unlock" ? "Enter Passcode" : stage === "set" ? "Choose a Passcode" : "Confirm Passcode"
      : method === "pattern"
        ? stage === "unlock" ? "Draw Pattern" : stage === "set" ? "Draw a Pattern" : "Confirm Pattern"
        : method === "face" ? "Face Scan" : "Fingerprint";

  return (
    <div className="h-full flex flex-col items-center relative overflow-hidden" style={backgroundStyle}>
      <div className={cn("relative flex flex-col items-center pt-12", light ? "text-black/85" : "text-white")}>
        <Lock size={14} className="opacity-70 mb-5" />
        <div className="text-[15px] font-medium opacity-70">{date}</div>
        <div className="font-display text-[72px] leading-[1.02] tracking-[-0.03em] mt-0.5">{time}</div>
      </div>

      <LockNotifications notifications={notifications} light={light} onOpen={onOpenNotification} />

      <div className={cn("relative flex flex-col items-center gap-3 mt-8 w-full", light ? "text-black/85" : "text-white")}>
        {method !== "none" && <div className="text-[13px] font-body opacity-80">{heading}</div>}
        {method === "passcode" && (
          <div key={shake} className={cn("flex items-center gap-4 h-4", shake > 0 && "shake")}>
            {[0, 1, 2, 3].map((i) => (
              <span key={i} className={cn("h-3 w-3 rounded-full border transition",
                i < entry.length
                  ? light ? "bg-black/80 border-black/80" : "bg-white border-white"
                  : light ? "border-black/30" : "border-white/40")} />
            ))}
          </div>
        )}
        <div className="h-4 text-[11px] font-body text-[#FF453A]">{message}</div>
      </div>

      <div className="relative mt-auto mb-6 w-full flex justify-center">
        {method === "passcode" && (
          <PasscodePad light={light} onPress={press} onDelete={() => setEntry((e) => e.slice(0, -1))} />
        )}
        {method === "pattern" && (
          <PatternPad light={light} clearKey={shake} onComplete={completePattern} />
        )}
        {method === "face" && <FaceScan light={light} onUnlock={onUnlock} />}
        {method === "fingerprint" && <FingerprintSensor light={light} onUnlock={onUnlock} />}
        {method === "none" && <SwipeUpUnlock light={light} onUnlock={onUnlock} />}
      </div>
    </div>
  );
}