import React from "react";
import ControlPanel from "@/components/control/ControlPanel";

export default function Control() {
  return (
    <div className="min-h-dvh bg-background grid-backdrop flex flex-col">
      <header className="border-b border-border/60 px-6 sm:px-8 py-5 flex items-center justify-between">
        <div>
          <div className="text-[10px] uppercase tracking-[0.35em] text-muted-foreground/80 font-body">PropScreen</div>
          <h1 className="font-display font-bold text-2xl tracking-[0.06em] leading-none mt-1.5">REMOTE CONTROL DECK</h1>
          <p className="text-[11px] text-muted-foreground font-body uppercase tracking-wider mt-1.5">Drive the prop phone - calls & messages</p>
        </div>
      </header>
      <div className="flex-1 p-5 sm:p-8 max-w-[860px] mx-auto w-full">
        <ControlPanel />
      </div>
    </div>
  );
}