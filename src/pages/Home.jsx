import React, { useState } from "react";
import { MonitorSmartphone, Clapperboard, Bookmark, User as UserIcon } from "lucide-react";
import HomeSection from "@/components/home/HomeSection";
import ProjectsPanel from "@/components/home/ProjectsPanel";
import DevicesPanel from "@/components/home/DevicesPanel";
import AppSettingsPanel from "@/components/home/AppSettingsPanel";
import SavedPanel from "@/components/home/SavedPanel";
import ProfilePanel from "@/components/home/ProfilePanel";
import BrandLogo from "@/components/home/BrandLogo";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription, SheetTrigger } from "@/components/ui/sheet";
import { Image } from "@/components/ui/image";
import { useAuth } from "@/lib/AuthContext";

const SELECTED_KEY = "propscreen.selectedProject";

export default function Home() {
  const { user, isAuthenticated } = useAuth();
  // the chosen project stays selected while the app is open - it only clears
  // when you pick it off again or close the app
  const [selectedProject, setSelectedProject] = useState(() => {
    try { return JSON.parse(sessionStorage.getItem(SELECTED_KEY)) || null; } catch { return null; }
  });
  const [devicesOpen, setDevicesOpen] = useState(Boolean(selectedProject));
  const [projectsOpen, setProjectsOpen] = useState(false);
  const pickProject = (p) => {
    setSelectedProject(p);
    try {
      if (p) sessionStorage.setItem(SELECTED_KEY, JSON.stringify(p));
      else sessionStorage.removeItem(SELECTED_KEY);
    } catch {}
    if (p) setDevicesOpen(true);
  };
  const initials = (user?.full_name || user?.email || "?")
    .split(/[\s@.]+/).filter(Boolean).slice(0, 2).map((w) => w[0].toUpperCase()).join("") || "?";

  return (
    <div className="min-h-dvh bg-background grid-backdrop">
      <header className="border-b border-border/60 px-6 sm:px-8 py-5 flex items-center justify-between">
        <div>
          <BrandLogo />
          <h1 className="font-display font-bold text-3xl tracking-[-0.02em] leading-none mt-1.5">Home</h1>
        </div>
        <div className="flex items-center gap-3">
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
                <div className="mt-5">
                  <div className="mb-2 font-display font-bold text-base">Settings</div>
                  <AppSettingsPanel />
                </div>
              </div>
            </SheetContent>
          </Sheet>
        </div>
      </header>

      <div className="p-5 sm:p-8 max-w-[1280px] mx-auto flex flex-col gap-5">
        <HomeSection icon={Clapperboard} title="Projects" subtitle="Production projects" open={projectsOpen} onOpenChange={setProjectsOpen}>
          <ProjectsPanel selected={selectedProject?.id || null} onSelect={pickProject} />
        </HomeSection>
        <HomeSection icon={MonitorSmartphone} title="Devices" subtitle="Prop devices & stage sync" open={devicesOpen} onOpenChange={setDevicesOpen}>
          <DevicesPanel project={selectedProject} />
        </HomeSection>
        <HomeSection icon={Bookmark} title="Saved" subtitle="Saved marker & screen configurations">
          <SavedPanel />
        </HomeSection>
      </div>
    </div>
  );
}