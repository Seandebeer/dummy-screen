import React from "react";
import { cn } from "@/lib/utils";
import { skinUi } from "@/lib/osSkins";

const BATTERY_STEPS = [5, 25, 50, 75, 100];
const NETWORKS = ["5G", "LTE", "4G", "3G", "H", "EDGE", "No Service"];

// the home control changes shape with the skin's era
function HomeButton({ variant, onHome }) {
  if (variant === "aqua") {
    return (
      <button onClick={onHome} aria-label="Home"
        className="absolute bottom-1 left-1/2 -translate-x-1/2 flex h-5 w-5 items-center justify-center rounded-full bg-gradient-to-b from-[#2a2c30] to-[#0d0e10] shadow-[inset_0_1px_1px_rgba(255,255,255,0.25),0_1px_3px_rgba(0,0,0,0.5)] transition">
        <span className="h-2 w-2 rounded-[2px] border border-white/70 bg-white/10" />
      </button>
    );
  }
  if (variant === "android") {
    return (
      <button onClick={onHome} aria-label="Home"
        className="absolute bottom-1.5 left-1/2 -translate-x-1/2 h-1 w-24 rounded-full bg-white/70 hover:bg-white transition" />
    );
  }
  if (variant === "trackpad") {
    return (
      <button onClick={onHome} aria-label="Home"
        className="absolute bottom-1 left-1/2 -translate-x-1/2 h-4 w-12 rounded-full border border-white/25 bg-gradient-to-b from-[#2a3546] to-[#101822] shadow-[inset_0_1px_1px_rgba(255,255,255,0.18)] transition" />
    );
  }
  if (variant === "wp") {
    return (
      <div className="absolute bottom-1.5 inset-x-0 flex items-center justify-center gap-14 transition">
        <button onClick={onHome} aria-label="Back" className="flex items-center">
          <svg width="15" height="12" viewBox="0 0 15 12" fill="none" strokeLinecap="round" strokeLinejoin="round">
            <path d="M14 6H2M7 1L2 6l5 5" stroke="rgba(255,255,255,0.85)" strokeWidth="1.6" />
          </svg>
        </button>
        <button onClick={onHome} aria-label="Start" className="grid grid-cols-2 gap-[2px]">
          {[0, 1, 2, 3].map((i) => <span key={i} className="h-[7px] w-[7px] bg-white/85" />)}
        </button>
        <button onClick={onHome} aria-label="Search" className="flex items-center">
          <svg width="13" height="13" viewBox="0 0 13 13" fill="none" strokeLinecap="round">
            <circle cx="5.5" cy="5.5" r="4.2" stroke="rgba(255,255,255,0.85)" strokeWidth="1.6" />
            <path d="M8.7 8.7L12 12" stroke="rgba(255,255,255,0.85)" strokeWidth="1.6" />
          </svg>
        </button>
      </div>
    );
  }
  if (variant === "holo") {
    const glyphs = [
      <svg key="a" width="11" height="12" viewBox="0 0 11 12"><path d="M1.5 1.5 L9.5 6 L1.5 10.5 Z" fill="rgba(255,255,255,0.85)" /></svg>,
      <svg key="b" width="11" height="12" viewBox="0 0 11 12"><circle cx="5.5" cy="6" r="4.2" fill="none" stroke="rgba(255,255,255,0.85)" strokeWidth="1.6" /></svg>,
      <svg key="c" width="11" height="12" viewBox="0 0 11 12"><rect x="2" y="2.5" width="7" height="7" fill="none" stroke="rgba(255,255,255,0.85)" strokeWidth="1.6" /></svg>,
    ];
    return (
      <div className="absolute bottom-1.5 inset-x-0 flex justify-center gap-7">
        {glyphs.map((g, i) => (
          <button key={i} onClick={onHome} aria-label="Home" className="flex items-center transition">{g}</button>
        ))}
      </div>
    );
  }
  if (variant === "webos") {
    return (
      <button onClick={onHome} aria-label="Home"
        className="absolute bottom-0.5 left-1/2 -translate-x-1/2 h-[3px] w-16 rounded-full bg-white/25 shadow-[0_0_6px_rgba(255,255,255,0.35)] hover:bg-white/45 transition" />
    );
  }
  return (
    <button onClick={onHome} aria-label="Home"
      className="absolute bottom-1.5 left-1/2 -translate-x-1/2 h-1.5 w-28 rounded-full bg-white/80 hover:bg-white transition" />
  );
}

export default function PhoneFrame({ children, onHome, light = false, time: timeProp, status, onStatusChange, bare = false, className, skin = "modern" }) {
  const now = new Date();
  const time = timeProp || now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  const s = { battery: 75, signal: 4, wifi: 3, ...(status || {}) };
  const lowBattery = s.battery <= 10;
  const edit = !!onStatusChange;
  const ui = skinUi(skin);
  const st = ui.status || {};

  return (
    <div className={bare ? "absolute inset-0" : "relative mx-auto w-full max-w-[400px] aspect-[9/19.5]"}>
      {/* bezel */}
      <div className={cn("absolute inset-0 overflow-hidden bg-[#05060a]",
        bare ? "rounded-none p-0 border-0 shadow-none" : "rounded-[3rem] p-[10px] shadow-2xl border border-[#242936]")}>
        <div data-os-skin={skin} className={cn("relative h-full w-full overflow-hidden bg-black", bare ? "rounded-none" : "rounded-[2.5rem]", className)}>
          {/* status bar - styled by the active skin */}
          <div
            className={cn("absolute top-0 inset-x-0 z-30 flex items-center justify-between px-7 pt-3.5 pb-1 text-[13px]",
              light ? "text-black" : "text-white", st.className)}
            style={st.style}>
            {st.carrier && (
              <div className="flex items-center gap-1.5">
                <button
                  onClick={edit ? () => onStatusChange({ signal: (s.signal + 1) % 5 }) : undefined}
                  title="Signal strength"
                  className="flex h-[11px] items-end gap-[2px]"
                >
                  {[4, 6, 8, 11].map((h, i) => (
                    <span key={i} className={cn("w-[3px] rounded-[1px]", i < s.signal ? "bg-current" : "bg-current/25")} style={{ height: h }} />
                  ))}
                </button>
                <button
                  onClick={edit ? () => onStatusChange({ network: NETWORKS[(NETWORKS.indexOf(s.network || "5G") + 1) % NETWORKS.length] }) : undefined}
                  title="Carrier"
                  className="text-[13px] font-body"
                >
                  {s.signal === 0 ? "-" : (s.network || "5G")}
                </button>
              </div>
            )}
            <span className={cn("font-body", st.timeCenter && "absolute left-1/2 -translate-x-1/2")}>{time}</span>
            {/* centered screen hub pill - hidden in fullscreen takeover (real device has its own) */}
            {!bare && skin === "modern" && <div className="absolute left-1/2 top-[9px] -translate-x-1/2 h-[25px] w-[90px] rounded-full bg-black" />}
            <div className="flex items-center gap-2">
              {/* signal - tap to adjust strength */}
              {!st.carrier && (
                <>
                  <button
                    onClick={edit ? () => onStatusChange({ signal: (s.signal + 1) % 5 }) : undefined}
                    title="Signal strength"
                    className="flex h-[11px] items-end gap-[2px]"
                  >
                    {[4, 6, 8, 11].map((h, i) => (
                      <span key={i} className={cn("w-[3px] rounded-[1px]", i < s.signal ? "bg-current" : "bg-current/25")} style={{ height: h }} />
                    ))}
                  </button>
                  <button
                    onClick={edit ? () => onStatusChange({ network: NETWORKS[(NETWORKS.indexOf(s.network || "5G") + 1) % NETWORKS.length] }) : undefined}
                    title="Network type"
                    className="text-[10px] font-body"
                  >
                    {s.signal === 0 ? "-" : (s.network || "5G")}
                  </button>
                </>
              )}
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
              {st.batteryPct && <span className="text-[11px] font-body">{s.battery}%</span>}
            </div>
          </div>
          {/* screen content */}
          <div className="absolute inset-0">{children}</div>
          {/* home indicator */}
          {onHome && <HomeButton variant={ui.home} onHome={onHome} />}
        </div>
      </div>
    </div>
  );
}