import React from "react";
import { cn } from "@/lib/utils";

const BATTERY_STEPS = [5, 25, 50, 75, 100];

export default function PhoneFrame({ children, onHome, light = false, time: timeProp, status, onStatusChange, bare = false, className }) {
  const now = new Date();
  const time = timeProp || now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  const s = { battery: 75, signal: 4, wifi: 3, ...(status || {}) };
  const lowBattery = s.battery <= 10;
  const edit = !!onStatusChange;

  return (
    <div className={bare ? "absolute inset-0" : "relative mx-auto w-full max-w-[400px] aspect-[9/19.5]"}>
      {/* bezel */}
      <div className={cn("absolute inset-0 overflow-hidden bg-[#05060a]",
        bare ? "rounded-none p-0 border-0 shadow-none" : "rounded-[3rem] p-[10px] shadow-2xl border border-[#242936]")}>
        <div className={cn("relative h-full w-full overflow-hidden bg-black", bare ? "rounded-none" : "rounded-[2.5rem]", className)}>
          {/* status bar */}
          <div className={cn(
            "absolute top-0 inset-x-0 z-30 flex items-center justify-between px-7 pt-3 pb-1 text-[12px] font-semibold",
            light ? "text-black" : "text-white"
          )}>
            <span className="font-body">{time}</span>
            {/* mock camera notch - hidden in fullscreen takeover (real device has its own) */}
            {!bare && <div className="absolute left-1/2 top-2 -translate-x-1/2 h-6 w-24 rounded-full bg-black" />}
            <div className="flex items-center gap-2">
              {/* signal - tap to adjust strength */}
              <button
                onClick={edit ? () => onStatusChange({ signal: (s.signal + 1) % 5 }) : undefined}
                title="Signal strength"
                className="flex h-[11px] items-end gap-[2px]"
              >
                {[4, 6, 8, 11].map((h, i) => (
                  <span key={i} className={cn("w-[3px] rounded-[1px]", i < s.signal ? "bg-current" : "bg-current/25")} style={{ height: h }} />
                ))}
              </button>
              <span className="text-[10px]">{s.signal === 0 ? "-" : "5G"}</span>
              {/* wifi - tap to adjust strength */}
              <button
                onClick={edit ? () => onStatusChange({ wifi: (s.wifi + 1) % 4 }) : undefined}
                title="Wi-Fi strength"
                className="flex items-center"
              >
                <svg width="15" height="12" viewBox="0 0 16 12" fill="none" strokeLinecap="round">
                  <path d="M1.5 4.5a9.2 9.2 0 0 1 13 0" stroke="currentColor" strokeWidth="1.6" opacity={s.wifi >= 3 ? 1 : 0.25} />
                  <path d="M4 7a6 6 0 0 1 8 0" stroke="currentColor" strokeWidth="1.6" opacity={s.wifi >= 2 ? 1 : 0.25} />
                  <circle cx="8" cy="10" r="1.3" fill="currentColor" opacity={s.wifi >= 1 ? 1 : 0.25} />
                </svg>
              </button>
              {/* battery - tap to adjust level */}
              <button
                onClick={edit ? () => onStatusChange({ battery: BATTERY_STEPS[(BATTERY_STEPS.indexOf(s.battery) + 1) % BATTERY_STEPS.length] }) : undefined}
                title="Battery level"
                className="flex items-center gap-0.5"
              >
                <div className={cn("h-2.5 w-5 rounded-[2px] border relative", lowBattery ? "border-[#FF3B30]" : "border-current")}>
                  <div
                    className={cn("absolute top-0.5 bottom-0.5 left-0.5 rounded-[1px]", lowBattery ? "bg-[#FF3B30] animate-pulse" : "bg-current")}
                    style={{ width: `calc((100% - 4px) * ${Math.max(s.battery, 4)} / 100)` }}
                  />
                </div>
                <div className={cn("h-1 w-0.5 rounded-r", lowBattery ? "bg-[#FF3B30]" : "bg-current")} />
              </button>
            </div>
          </div>
          {/* screen content */}
          <div className="absolute inset-0">{children}</div>
          {/* home indicator */}
          {onHome && (
            <button
              onClick={onHome}
              className="absolute bottom-1.5 left-1/2 -translate-x-1/2 h-1.5 w-28 rounded-full bg-white/80 hover:bg-white transition"
              aria-label="Home"
            />
          )}
        </div>
      </div>
    </div>
  );
}