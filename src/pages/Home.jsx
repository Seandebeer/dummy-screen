import React from "react";
import ProjectsPanel from "@/components/home/ProjectsPanel";
import DevicesPanel from "@/components/home/DevicesPanel";

export default function Home() {
  return (
    <div className="min-h-dvh bg-background grid-backdrop">
      <header className="border-b border-border px-8 py-5 flex items-center justify-between">
        <div>
          <h1 className="font-display font-bold text-2xl tracking-wide">HOME</h1>
          <p className="text-[11px] text-muted-foreground font-body uppercase tracking-wider">Projects &amp; devices</p>
        </div>
        <div className="flex items-center gap-4 text-[11px] font-body">
          <span className="flex items-center gap-1.5 text-signal"><span className="h-2 w-2 rounded-full bg-signal led-pulse" /> SYNC LIVE</span>
          <span className="text-muted-foreground hidden sm:inline">CHANNEL stage-1</span>
        </div>
      </header>
      <div className="p-4 sm:p-6 max-w-[1400px] mx-auto grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6 items-start">
        <ProjectsPanel />
        <DevicesPanel />
      </div>
    </div>
  );
}