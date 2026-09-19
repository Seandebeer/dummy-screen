import React, { useState } from "react";
import { Link } from "react-router-dom";
import { ArrowLeft } from "lucide-react";
import UIMarkersApp from "@/components/os/apps/UIMarkersApp";
import useOsConfig from "@/hooks/useOsConfig";
import { cn } from "@/lib/utils";

export default function UIMarkers() {
  const { config, update } = useOsConfig();
  const [locked, setLocked] = useState(false);
  const light = config.theme === "light";

  return (
    <div className="relative h-dvh bg-background overflow-hidden">
      {/* page HUD floats over the stage and disappears when locked - the grid never moves */}
      {!locked && (
        <header className="absolute top-0 inset-x-0 z-10 flex items-center px-6 py-4 pointer-events-none">
          <Link to="/" className={cn("pointer-events-auto flex items-center gap-2 text-sm font-body", light ? "text-black/50 hover:text-black" : "text-white/50 hover:text-white")}>
            <ArrowLeft size={18} /> Back
          </Link>
        </header>
      )}
      <div className="absolute inset-0">
        <UIMarkersApp config={config} update={update} onLockChange={setLocked} />
      </div>
    </div>
  );
}