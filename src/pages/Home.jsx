import React, { useState } from "react";
import { ChevronDown, Info } from "lucide-react";
import ProjectsPanel from "@/components/home/ProjectsPanel";
import DevicesPanel from "@/components/home/DevicesPanel";
import AppSettingsPanel from "@/components/home/AppSettingsPanel";
import { cn } from "@/lib/utils";

export default function Home() {
  const [infoOpen, setInfoOpen] = useState(false);
  const [deviceName, setDeviceName] = useState(() => localStorage.getItem("takeover-device-name") || "");

  return (
    <div className="min-h-dvh bg-background grid-backdrop">
      <header className="border-b border-border px-8 py-4 flex items-center justify-between">
        <h1 className="font-display font-bold text-2xl tracking-wide">HOME</h1>
        <div className="flex items-center gap-3">
          {deviceName && (
            <span className="rounded-full border border-amber/40 bg-amber/10 px-2.5 py-1 text-[10px] font-body text-amber">{deviceName}</span>
          )}
          <span className="text-[10px] text-muted-foreground/60 font-body uppercase tracking-wider hidden sm:inline">stage-1 · sync live</span>
        </div>
      </header>

      <div className="p-4 sm:p-6 max-w-[1400px] mx-auto flex flex-col gap-4 sm:gap-6">
        <AppSettingsPanel onNameChange={setDeviceName} />

        {/* production info — tucked away, expand when needed */}
        <div className="rounded-2xl border border-border bg-surface">
          <button onClick={() => setInfoOpen((o) => !o)} className="w-full flex items-center gap-2.5 p-4">
            <span className="h-9 w-9 rounded-lg bg-muted/60 text-muted-foreground flex items-center justify-center">
              <Info size={18} />
            </span>
            <span className="flex-1 text-left">
              <span className="block font-display font-bold text-base leading-none">Production Info</span>
              <span className="block text-[11px] text-muted-foreground font-body mt-1">Projects & devices</span>
            </span>
            <ChevronDown size={18} className={cn("text-muted-foreground transition-transform", infoOpen && "rotate-180")} />
          </button>
          {infoOpen && (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6 px-4 pb-4 pt-4 border-t border-border">
              <ProjectsPanel />
              <DevicesPanel />
            </div>
          )}
        </div>
      </div>
    </div>
  );
}