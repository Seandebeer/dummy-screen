import React, { useState } from "react";
import { Smartphone, Clapperboard, Settings2, Bookmark, User as UserIcon } from "lucide-react";
import HomeSection from "@/components/home/HomeSection";
import ProjectsPanel from "@/components/home/ProjectsPanel";
import DevicesPanel from "@/components/home/DevicesPanel";
import AppSettingsPanel from "@/components/home/AppSettingsPanel";
import SavedPanel from "@/components/home/SavedPanel";
import ProfilePanel from "@/components/home/ProfilePanel";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription, SheetTrigger } from "@/components/ui/sheet";
import { Image } from "@/components/ui/image";
import { useAuth } from "@/lib/AuthContext";

export default function Home() {
  const [deviceName, setDeviceName] = useState(() => localStorage.getItem("takeover-device-name") || "");
  const { user, isAuthenticated } = useAuth();
  const initials = (user?.full_name || user?.email || "?")
    .split(/[\s@.]+/).filter(Boolean).slice(0, 2).map((w) => w[0].toUpperCase()).join("") || "?";

  return (
    <div className="min-h-dvh bg-background grid-backdrop">
      <header className="border-b border-border/60 px-6 sm:px-8 py-5 flex items-center justify-between">
        <div>
          <div className="text-[10px] uppercase tracking-[0.35em] text-muted-foreground/80 font-body">PropScreen</div>
          <h1 className="font-display font-bold text-2xl tracking-[0.18em] leading-none mt-1.5">HOME</h1>
        </div>
        <div className="flex items-center gap-3">
          {deviceName && (
            <span className="hidden sm:inline-flex items-center gap-1.5 rounded-full border border-amber/30 bg-amber/10 px-3 py-1.5 text-[10px] font-medium font-body text-amber"><span className="h-1.5 w-1.5 rounded-full bg-amber led-pulse" />{deviceName}</span>
          )}
          <Sheet>
            <SheetTrigger asChild>
              <button title="Profile & saved layouts"
                className="h-10 w-10 rounded-full overflow-hidden border border-amber/30 bg-amber/10 flex items-center justify-center transition hover:border-amber hover:bg-amber/20">
                {isAuthenticated && user?.image ? (
                  <Image src={user.image} alt="" className="h-full w-full" fittingType="fill" />
                ) : isAuthenticated ? (
                  <span className="font-display font-bold text-xs text-amber">{initials}</span>
                ) : (
                  <UserIcon size={18} className="text-amber" />
                )}
              </button>
            </SheetTrigger>
            <SheetContent side="right" className="w-[85vw] p-0">
              <SheetHeader className="px-5 pt-5 pb-3 border-b border-border">
                <SheetTitle className="font-display font-bold text-base text-left">Profile</SheetTitle>
                <SheetDescription className="sr-only">Sign in and manage your saved OS layouts</SheetDescription>
              </SheetHeader>
              <div className="p-4 h-[calc(100dvh-88px)] overflow-y-auto">
                <ProfilePanel />
              </div>
            </SheetContent>
          </Sheet>
        </div>
      </header>

      <div className="p-5 sm:p-8 max-w-[1280px] mx-auto flex flex-col gap-5">
        <HomeSection icon={Smartphone} title="Devices" subtitle="Prop devices & stage sync">
          <DevicesPanel />
        </HomeSection>
        <HomeSection icon={Clapperboard} title="Projects" subtitle="Production projects">
          <ProjectsPanel />
        </HomeSection>
        <HomeSection icon={Settings2} title="Settings" subtitle="Deck & mock OS preferences">
          <AppSettingsPanel onNameChange={setDeviceName} />
        </HomeSection>
        <HomeSection icon={Bookmark} title="Saved" subtitle="Saved marker & screen configurations">
          <SavedPanel />
        </HomeSection>
      </div>
    </div>
  );
}