import React from "react";
import ControlPanel from "@/components/control/ControlPanel";

export default function Control() {
  return (
    <div className="min-h-dvh bg-background grid-backdrop flex flex-col">
      <header className="border-b border-border/60 px-6 sm:px-8 pb-5 pt-[calc(env(safe-area-inset-top)_+_1.25rem)] flex items-center justify-between">
        <div>
          <h1 className="font-display font-bold text-2xl tracking-[0.06em] leading-none">REMOTE CONTROL DECK</h1>
          <p className="text-[11px] text-muted-foreground font-body uppercase tracking-wider mt-1.5">Drive the prop phone - calls & messages</p>
        </div>
      </header>
      <div className="flex-1 p-5 sm:p-8 max-w-[860px] mx-auto w-full">
        <ControlPanel />
      </div>
    </div>
  );
}