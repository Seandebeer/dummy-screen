import React from "react";
import { Outlet, NavLink } from "react-router-dom";
import { Monitor, Grid2x2, Radio, Home } from "lucide-react";
import { cn } from "@/lib/utils";
import { useIsMobile } from "@/hooks/use-mobile";

const navItems = [
  { to: "/", label: "Home", icon: Home },
  { to: "/os", label: "OS", icon: Monitor },
  { to: "/vfx", label: "VFX", icon: Grid2x2 },
  { to: "/control", label: "Control", icon: Radio },
];

export default function Layout() {
  const isMobile = useIsMobile();

  if (isMobile) {
    return (
      <div className="min-h-dvh bg-background">
        <main className="pb-20">
          <Outlet />
        </main>
        <nav className="fixed bottom-0 inset-x-0 z-40 border-t border-border bg-surface/95 backdrop-blur">
          <div className="flex items-stretch justify-around">
            {navItems.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                end={item.to === "/"}
                className={({ isActive }) =>
                  cn(
                    "flex flex-1 flex-col items-center gap-1 py-2.5 text-[10px] font-body transition",
                    isActive ? "text-amber" : "text-muted-foreground"
                  )
                }
              >
                {({ isActive }) => (
                  <>
                    <item.icon size={20} className={cn(isActive && "drop-shadow-[0_0_6px_hsl(var(--amber))]")} />
                    <span className="uppercase tracking-wider">{item.label}</span>
                  </>
                )}
              </NavLink>
            ))}
          </div>
        </nav>
      </div>
    );
  }

  return (
    <div className="min-h-dvh flex bg-background">
      <nav className="w-16 shrink-0 border-r border-border bg-surface flex flex-col items-center py-6 gap-2">
        <div className="mb-6 h-10 w-10 rounded-lg bg-amber flex items-center justify-center text-background font-display font-bold text-lg">T</div>
        {navItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.to === "/"}
            className={({ isActive }) =>
              cn(
                "group relative flex h-11 w-11 items-center justify-center rounded-lg transition",
                isActive ? "bg-amber/15 text-amber" : "text-muted-foreground hover:text-foreground hover:bg-muted"
              )
            }
          >
            {({ isActive }) => (
              <>
                <item.icon size={20} />
                {isActive && <span className="absolute -left-2 top-1/2 -translate-y-1/2 h-6 w-1 rounded-full bg-amber amber-pulse" />}
                <span className="absolute left-14 whitespace-nowrap rounded bg-surface border border-border px-2 py-1 text-[11px] font-body opacity-0 group-hover:opacity-100 transition pointer-events-none">{item.label}</span>
              </>
            )}
          </NavLink>
        ))}
      </nav>
      <main className="flex-1 min-w-0 overflow-auto">
        <Outlet />
      </main>
    </div>
  );
}