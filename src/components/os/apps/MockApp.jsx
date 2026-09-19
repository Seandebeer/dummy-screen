import React from "react";
import IconTile from "../IconTile";

export default function MockApp({ app }) {
  if (!app) return null;
  return (
    <div className="h-full flex flex-col items-center justify-center gap-4 text-white"
      style={{ background: "linear-gradient(180deg, #14162a 0%, #050609 100%)" }}>
      <IconTile app={app} size="lg" />
      <div className="font-display text-2xl font-semibold">{app.label}</div>
      <div className="text-xs text-white/40 font-body tracking-widest uppercase">mock app · prop only</div>
      <div className="text-[11px] text-white/25 font-body mt-2">tap the home bar to return</div>
    </div>
  );
}