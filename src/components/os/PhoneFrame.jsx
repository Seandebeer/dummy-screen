import React from "react";
import { cn } from "@/lib/utils";

export default function PhoneFrame({ children, onHome, light = false, statusBarDark = false, className }) {
  const now = new Date();
  const time = now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  return (
    <div className="relative mx-auto w-full max-w-[400px] aspect-[9/19.5]">
      {/* bezel */}
      <div className="absolute inset-0 rounded-[3rem] bg-[#05060a] p-[10px] shadow-2xl border border-[#242936]">
        <div className={cn("relative h-full w-full overflow-hidden rounded-[2.5rem] bg-black", className)}>
          {/* status bar */}
          <div className={cn(
            "absolute top-0 inset-x-0 z-30 flex items-center justify-between px-7 pt-3 pb-1 text-[12px] font-semibold",
            light ? "text-black" : "text-white"
          )}>
            <span className="font-body">{time}</span>
            {/* notch */}
            <div className="absolute left-1/2 top-2 -translate-x-1/2 h-6 w-24 rounded-full bg-black" />
            <div className="flex items-center gap-1.5">
              <span className="text-[10px]">●●●</span>
              <span className="text-[10px]">5G</span>
              <div className="flex items-center gap-0.5">
                <div className="h-2.5 w-5 rounded-[2px] border border-current relative">
                  <div className="absolute inset-0.5 bg-current rounded-[1px]" style={{ width: "75%" }} />
                </div>
                <div className="h-1 w-0.5 bg-current rounded-r" />
              </div>
            </div>
          </div>
          {/* screen content */}
          <div className="absolute inset-0 pt-9">{children}</div>
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