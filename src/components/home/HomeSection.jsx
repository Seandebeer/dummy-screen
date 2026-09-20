import React, { useState } from "react";
import { ChevronDown } from "lucide-react";
import { cn } from "@/lib/utils";

export default function HomeSection({ icon: Icon, title, subtitle, children, open: openProp, onOpenChange }) {
  const [openState, setOpenState] = useState(false);
  const open = openProp !== undefined ? openProp : openState;
  const toggle = () => (onOpenChange ? onOpenChange(!open) : setOpenState((o) => !o));
  return (
    <div className="rounded-2xl border border-border/70 bg-surface/80 shadow-[0_8px_28px_rgba(0,0,0,0.25)] backdrop-blur-xl transition hover:border-amber/30">
      <button onClick={toggle} className="w-full flex items-center gap-3.5 p-4">
        <span className="h-10 w-10 rounded-xl bg-gradient-to-b from-amber/20 to-amber/5 ring-1 ring-inset ring-amber/20 text-amber flex items-center justify-center">
          <Icon size={18} />
        </span>
        <span className="flex-1 text-left">
          <span className="block font-display font-bold text-base leading-none">{title}</span>
          <span className="block text-[11px] text-muted-foreground font-body mt-1">{subtitle}</span>
        </span>
        <ChevronDown size={18} className={cn("text-muted-foreground transition-transform", open && "rotate-180")} />
      </button>
      {open && <div className="px-4 pb-4 pt-1 border-t border-border/60">{children}</div>}
    </div>
  );
}