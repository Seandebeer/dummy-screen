import React from "react";
import { Link } from "react-router-dom";
import { ArrowLeft } from "lucide-react";
import UIMarkersApp from "@/components/os/apps/UIMarkersApp";
import useOsConfig from "@/hooks/useOsConfig";

export default function UIMarkers() {
  const { config, update } = useOsConfig();

  return (
    <div className="h-dvh bg-background flex flex-col">
      <header className="flex items-center justify-between px-6 py-4 border-b border-border">
        <Link to="/" className="flex items-center gap-2 text-muted-foreground hover:text-foreground text-sm font-body">
          <ArrowLeft size={18} /> Deck
        </Link>
        <div className="font-display font-bold text-lg tracking-wide">UI MARKERS</div>
        <div className="flex items-center gap-2 text-xs font-body text-signal">
          <span className="h-2 w-2 rounded-full bg-signal led-pulse" /> SYNC LIVE
        </div>
      </header>
      <div className="flex-1 min-h-0">
        <UIMarkersApp config={config} update={update} />
      </div>
    </div>
  );
}