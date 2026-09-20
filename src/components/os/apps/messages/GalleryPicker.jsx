import React, { useState } from "react";
import { Images, Play, X } from "lucide-react";
import { getPhotos } from "@/lib/cameraRoll";
import { cn } from "@/lib/utils";

// the device camera roll - pick a photo or clip to attach to the message
export default function GalleryPicker({ dark, onPick, onClose }) {
  const [items] = useState(getPhotos);
  return (
    <div className={cn("absolute inset-0 z-50 flex flex-col",
      dark ? "bg-[#0b0b0f] text-white" : "bg-white text-black")}>
      <div className={cn("flex items-center justify-between border-b px-3 py-2.5",
        dark ? "border-white/10" : "border-black/10")}>
        <button onClick={onClose} className="flex items-center gap-0.5 text-[#007AFF]">
          <X size={16} /> <span className="text-sm">Cancel</span>
        </button>
        <span className="text-[15px] font-semibold">Photos</span>
        <span className="w-14" />
      </div>
      <div className="flex-1 overflow-y-auto no-scrollbar p-1">
        {items.length === 0 ? (
          <div className="flex h-full flex-col items-center justify-center gap-2 px-8 text-center">
            <Images size={24} className="opacity-30" />
            <div className="text-xs opacity-50">No photos yet - capture some in the Camera app</div>
          </div>
        ) : (
          <div className="grid grid-cols-3 gap-1">
            {items.map((p) => (
              <button key={p.id} onClick={() => onPick(p)}
                className="relative aspect-square overflow-hidden rounded-lg">
                <img src={p.type === "video" ? p.poster : p.url} alt=""
                  className="h-full w-full object-cover" />
                {p.type === "video" && (
                  <span className="absolute inset-0 flex items-center justify-center bg-black/25">
                    <span className="rounded-full bg-black/55 p-1.5"><Play size={12} className="text-white" /></span>
                  </span>
                )}
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}