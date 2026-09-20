import React from "react";
import { X } from "lucide-react";
import { cn } from "@/lib/utils";

// contact chooser for sending gallery items into a Messages thread
export default function SendSheet({ contacts, light, count, onPick, onClose }) {
  return (
    <div className="absolute inset-0 z-50 flex items-end bg-black/40" onClick={onClose}>
      <div onClick={(e) => e.stopPropagation()}
        className={cn("w-full rounded-t-2xl border-t p-4 pb-5",
          light ? "border-black/10 bg-white text-black" : "border-white/10 bg-[#1C1C1E] text-white")}>
        <div className="mb-3 flex items-center justify-between">
          <span className="text-[13px] font-semibold">
            Send {count > 1 ? `${count} items` : "item"} via Messages
          </span>
          <button onClick={onClose} aria-label="Close"><X size={16} /></button>
        </div>
        <div className="max-h-52 overflow-y-auto no-scrollbar">
          {contacts.length === 0 && (
            <div className="py-3 text-center text-xs opacity-50">No contacts saved yet</div>
          )}
          {contacts.map((c) => (
            <button key={c.id} onClick={() => onPick(c)}
              className="flex w-full items-center gap-2.5 px-1 py-2 text-left active:opacity-60">
              <span className="flex h-9 w-9 shrink-0 items-center justify-center overflow-hidden rounded-full text-xs font-semibold"
                style={{ background: c.color || "#B9C1CB", color: "#000" }}>
                {c.initials || c.name.slice(0, 2).toUpperCase()}
              </span>
              <span className="text-sm font-medium">{c.name}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}