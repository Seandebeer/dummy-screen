import React, { useState } from "react";
import { Lock } from "lucide-react";
import PasscodePad from "./PasscodePad";
import { bgPresets } from "@/hooks/useOsConfig";
import { cn } from "@/lib/utils";

export default function LockScreen({ config, update, onUnlock }) {
  const [entry, setEntry] = useState("");
  const [stage, setStage] = useState(config.passcode ? "unlock" : "set");
  const [first, setFirst] = useState("");
  const [message, setMessage] = useState("");
  const [shake, setShake] = useState(0);

  const light = config.theme === "light";
  const now = new Date();
  const time = config.clock.mode === "custom" && config.clock.time
    ? config.clock.time
    : now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  const date = config.clock.mode === "custom" && config.clock.date
    ? config.clock.date
    : now.toLocaleDateString([], { weekday: "long", month: "long", day: "numeric" });

  const hasImage = config.background.type === "image" && config.background.url;
  const preset = bgPresets.find((p) => p.id === (config.background.preset || "default")) || bgPresets[0];
  const backgroundStyle = hasImage
    ? { backgroundImage: `url(${config.background.url})`, backgroundSize: "cover", backgroundPosition: "center" }
    : { background: preset[light ? "light" : "dark"] };

  const heading = stage === "unlock" ? "Enter Passcode" : stage === "set" ? "Choose a Passcode" : "Confirm Passcode";

  const fail = (msg) => {
    setMessage(msg);
    setShake((n) => n + 1);
    setEntry("");
  };

  const submit = (code) => {
    if (stage === "unlock") {
      if (code === config.passcode) onUnlock();
      else fail("Wrong passcode — try again");
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
      fail("Passcodes didn't match — try again");
    }
  };

  const press = (d) => {
    if (entry.length >= 4) return;
    setMessage("");
    const next = entry + d;
    setEntry(next);
    if (next.length === 4) setTimeout(() => submit(next), 150);
  };

  return (
    <div className="h-full flex flex-col items-center relative overflow-hidden" style={backgroundStyle}>
      {!hasImage && <div className="grid-backdrop absolute inset-0 opacity-30 pointer-events-none" />}
      <div className={cn("relative flex flex-col items-center pt-10", light ? "text-black/85" : "text-white")}>
        <Lock size={20} className="opacity-60 mb-3" />
        <div className="font-display text-6xl font-bold tracking-tight">{time}</div>
        <div className="text-sm mt-1 opacity-60">{date}</div>
      </div>

      <div className={cn("relative flex flex-col items-center gap-3 mt-8", light ? "text-black/85" : "text-white")}>
        <div className="text-[13px] font-body opacity-80">{heading}</div>
        <div key={shake} className={cn("flex items-center gap-4 h-4", shake > 0 && "shake")}>
          {[0, 1, 2, 3].map((i) => (
            <span key={i} className={cn("h-3 w-3 rounded-full border transition",
              i < entry.length
                ? light ? "bg-black/80 border-black/80" : "bg-white border-white"
                : light ? "border-black/30" : "border-white/40")} />
          ))}
        </div>
        <div className="h-4 text-[11px] font-body text-[#FF453A]">{message}</div>
      </div>

      <div className="relative mt-auto mb-8 w-full">
        <PasscodePad light={light} onPress={press} onDelete={() => setEntry((e) => e.slice(0, -1))} />
      </div>
    </div>
  );
}