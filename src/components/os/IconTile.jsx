import React from "react";
import { cn } from "@/lib/utils";

export default function IconTile({ app, size = "md" }) {
  const { Icon, bg } = app;
  return (
    <span
      className={cn(
        "flex items-center justify-center rounded-2xl border border-white/30 backdrop-blur-sm",
        "shadow-[0_8px_24px_rgba(0,0,0,0.45),inset_0_1px_2px_rgba(255,255,255,0.5),inset_0_-2px_6px_rgba(0,0,0,0.25)]",
        size === "sm" ? "h-9 w-9" : "h-14 w-14"
      )}
      style={{
        background: `linear-gradient(145deg, rgba(255,255,255,0.45) 0%, rgba(255,255,255,0.1) 42%, rgba(255,255,255,0) 60%), ${bg}`,
      }}
    >
      <Icon size={size === "sm" ? 16 : 26} className="text-white drop-shadow-[0_1px_2px_rgba(0,0,0,0.45)]" />
    </span>
  );
}