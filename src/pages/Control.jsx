import React from "react";
import ControlPanel from "@/components/control/ControlPanel";

export default function Control() {
  return (
    <div className="min-h-dvh bg-background grid-backdrop flex flex-col">
      <header className="border-b border-border px-8 py-5 flex items-center justify-between">
        <div>
          <h1 className="font-display font-bold text-2xl tracking-wide">REMOTE CONTROL DECK</h1>
          <p className="text-[11px] text-muted-foreground font-body uppercase tracking-wider">Drive the prop phone — calls & messages</p>
        </div>
        <span className="flex items-center gap-1.5 text-[11px] font-body text-signal">
          <span className="h-2 w-2 rounded-full bg-signal led-pulse" /> SYNC LIVE
        </span>
      </header>
      <div className="flex-1 p-6 max-w-[900px] mx-auto w-full">
        <ControlPanel />
      </div>
    </div>
  );
}