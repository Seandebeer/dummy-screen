import React, { useState } from "react";
import { Smartphone, Clapperboard, Settings2 } from "lucide-react";
import HomeSection from "@/components/home/HomeSection";
import ProjectsPanel from "@/components/home/ProjectsPanel";
import DevicesPanel from "@/components/home/DevicesPanel";
import AppSettingsPanel from "@/components/home/AppSettingsPanel";

export default function Home() {
  const [deviceName, setDeviceName] = useState(() => localStorage.getItem("takeover-device-name") || "");

  return (
    <div className="min-h-dvh bg-background grid-backdrop">
      <header className="border-b border-border px-8 py-4 flex items-center justify-between">
        <h1 className="font-display font-bold text-2xl tracking-wide">HOME</h1>
        {deviceName && (
          <span className="rounded-full border border-amber/40 bg-amber/10 px-2.5 py-1 text-[10px] font-body text-amber">{deviceName}</span>
        )}
      </header>

      <div className="p-4 sm:p-6 max-w-[1400px] mx-auto flex flex-col gap-4">
        <HomeSection icon={Smartphone} title="Devices" subtitle="Prop devices & stage sync">
          <DevicesPanel />
        </HomeSection>
        <HomeSection icon={Clapperboard} title="Projects" subtitle="Production projects">
          <ProjectsPanel />
        </HomeSection>
        <HomeSection icon={Settings2} title="Settings" subtitle="Deck & mock OS preferences">
          <AppSettingsPanel onNameChange={setDeviceName} />
        </HomeSection>
      </div>
    </div>
  );
}