import React, { useState } from "react";
import { ChevronDown } from "lucide-react";
import { cn } from "@/lib/utils";

// collapsible control-deck card - collapsed by default so the deck stays tidy;
// the header toggles open, and an optional badge (e.g. call state) stays visible
export default function ControlCard({ icon: Icon, title, badge, iconClass = "text-signal", children, defaultOpen = false }) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <div className="rounded-[20px] border border-white/[0.07] bg-surface/60 backdrop-blur-2xl shadow-[0_10px_32px_rgba(0,0,0,0.28)]">
      <div role="button" tabIndex={0} onClick={() => setOpen((o) => !o)}
        onKeyDown={(e) => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); setOpen((o) => !o); } }}
        className="flex w-full cursor-pointer select-none items-center justify-between px-5 py-4">
        <span className="flex items-center gap-2">
          <Icon size={16} className={iconClass} />
          <span className="font-display font-semibold text-[15px] tracking-tight">{title}</span>
        </span>
        <span className="flex items-center gap-2">
          {badge}
          <ChevronDown size={15} className={cn("text-muted-foreground transition-transform", open && "rotate-180")} />
        </span>
      </div>
      {open && <div className="px-5 pb-5">{children}</div>}
    </div>
  );
}