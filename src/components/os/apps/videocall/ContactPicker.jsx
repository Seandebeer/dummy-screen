import React from "react";
import { Video as VideoIcon } from "lucide-react";

const initials = (name) =>
  (name || "?").trim().split(/\s+/).map((w) => w[0]).slice(0, 2).join("").toUpperCase();

// FaceTime-style contact list - tap someone to set up a video call with them
export default function ContactPicker({ contacts, onSelect }) {
  return (
    <div className="absolute inset-0 flex flex-col bg-[#0a0a0c] text-white">
      <div className="px-4 pb-2 pt-4 text-center">
        <div className="font-display text-[17px] font-semibold">FaceTime</div>
        <div className="text-[10px] font-body text-white/40">Choose someone to call</div>
      </div>
      <div className="no-scrollbar flex-1 overflow-y-auto px-3 pb-3">
        {(contacts || []).length === 0 && (
          <p className="pt-10 text-center text-[11px] font-body text-white/40">No contacts yet</p>
        )}
        {(contacts || []).map((c) => (
          <button key={String(c.id ?? c.number ?? c.name)} onClick={() => onSelect(c)}
            className="flex w-full items-center gap-3 rounded-xl px-2 py-2.5 transition hover:bg-white/5 active:bg-white/10">
            <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-gradient-to-b from-[#3a3a3c] to-[#2c2c2e] font-display text-[13px] font-semibold text-white/90">
              {initials(c.name)}
            </span>
            <span className="min-w-0 flex-1 text-left">
              <span className="block truncate text-[14px] font-body">{c.name || "Unknown"}</span>
              <span className="block truncate text-[10px] font-body text-white/40">{c.number || ""}</span>
            </span>
            <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-[#34C759] text-white transition active:scale-90">
              <VideoIcon size={16} />
            </span>
          </button>
        ))}
      </div>
    </div>
  );
}