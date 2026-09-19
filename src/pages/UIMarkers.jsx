import React, { useState } from "react";
import { Link } from "react-router-dom";
import { ArrowLeft } from "lucide-react";
import UIMarkersApp from "@/components/os/apps/UIMarkersApp";
import useOsConfig from "@/hooks/useOsConfig";

export default function UIMarkers() {
  const { config, update } = useOsConfig();
  const [locked, setLocked] = useState(false);

  return (
    <div className="relative h-dvh bg-background overflow-hidden">
      {/* page HUD floats over the stage and disappears when locked — the grid never moves */}
      {!locked && (
        <header className="absolute top-0 inset-x-0 z-10 flex items-center justify-between px-6 py-4 pointer-events-none">
          <Link to="/" className="pointer-events-auto flex items-center gap-2 text-muted-foreground hover:text-foreground text-sm font-body">
            <ArrowLeft size={18} /> Deck
          </Link>
          <div className="font-display font-bold text-lg tracking-wide">UI MARKERS</div>
          <div className="flex items-center gap-2 text-xs font-body text-signal">
            <span className="h-2 w-2 rounded-full bg-signal led-pulse" /> SYNC LIVE
          </div>
        </header>
      )}
      <div className="absolute inset-0">
        <UIMarkersApp config={config} update={update} onLockChange={setLocked} />
      </div>
    </div>
  );
}