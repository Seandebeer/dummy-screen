import React, { useState } from "react";
import { ChevronDown } from "lucide-react";
import { cn } from "@/lib/utils";

export default function HomeSection({ icon: Icon, title, subtitle, children }) {
  const [open, setOpen] = useState(false);
  return (
    <div className="rounded-2xl border border-border bg-surface">
      <button onClick={() => setOpen((o) => !o)} className="w-full flex items-center gap-2.5 p-4">
        <span className="h-9 w-9 rounded-lg bg-amber/15 text-amber flex items-center justify-center">
          <Icon size={18} />
        </span>
        <span className="flex-1 text-left">
          <span className="block font-display font-bold text-base leading-none">{title}</span>
          <span className="block text-[11px] text-muted-foreground font-body mt-1">{subtitle}</span>
        </span>
        <ChevronDown size={18} className={cn("text-muted-foreground transition-transform", open && "rotate-180")} />
      </button>
      {open && <div className="px-4 pb-4 pt-1 border-t border-border">{children}</div>}
    </div>
  );
}