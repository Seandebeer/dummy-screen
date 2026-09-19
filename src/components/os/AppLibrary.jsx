import React from "react";
import { X, Eye, EyeOff } from "lucide-react";
import { allApps } from "@/lib/osApps";
import IconTile from "./IconTile";
import { cn } from "@/lib/utils";

export default function AppLibrary({ order, onToggle, onClose }) {
  return (
    <div className="absolute inset-0 z-30 bg-black/75 backdrop-blur-sm flex flex-col" onClick={(e) => e.stopPropagation()}>
      <div className="flex items-center justify-between px-5 pt-4 pb-1">
        <div className="text-white font-display font-bold">Apps</div>
        <button onClick={onClose} className="text-white/70 hover:text-white"><X size={18} /></button>
      </div>
      <p className="px-5 pb-3 text-[10px] text-white/40 font-body uppercase tracking-wider">Toggle apps on the home screen · drag icons to rearrange</p>
      <div className="flex-1 overflow-y-auto no-scrollbar px-4 pb-4 grid grid-cols-2 gap-2 content-start">
        {allApps.map((a) => {
          const visible = order.includes(a.id);
          return (
            <div key={a.id}
              className={cn("flex items-center gap-2.5 rounded-xl px-2.5 py-2 border transition",
                visible ? "border-white/15 bg-white/10" : "border-white/5 bg-white/[0.03] opacity-50")}>
              <IconTile app={a} size="sm" />
              <span className="flex-1 text-[12px] text-white truncate">{a.label}</span>
              <button onClick={() => onToggle(a.id)}
                className={cn("flex items-center justify-center h-7 w-7 rounded-full shrink-0",
                  visible ? "bg-white/20 text-white" : "bg-white/5 text-white/50")}>
                {visible ? <Eye size={14} /> : <EyeOff size={14} />}
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
}