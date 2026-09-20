import React, { useState } from "react";
import { EMOJI_CATEGORIES } from "@/lib/emojiData";
import { cn } from "@/lib/utils";

// real Unicode emoji board with category tabs, like the phone's emoji keyboard
export default function EmojiPicker({ dark, onPick }) {
  const [cat, setCat] = useState(0);
  const emojis = EMOJI_CATEGORIES[cat].emojis;
  return (
    <div className={cn("absolute inset-x-0 bottom-[52px] z-30 flex h-56 flex-col rounded-t-2xl border-t shadow-2xl",
      dark ? "border-white/10 bg-[#1C1C1E]" : "border-black/10 bg-[#F2F2F7]")}>
      <div className={cn("flex gap-1 overflow-x-auto no-scrollbar border-b px-2 py-1.5",
        dark ? "border-white/10" : "border-black/10")}>
        {EMOJI_CATEGORIES.map((c, i) => (
          <button key={c.id} onClick={() => setCat(i)} aria-label={c.id}
            className={cn("shrink-0 rounded-lg px-2 py-1 text-[16px] leading-none",
              i === cat && (dark ? "bg-white/15" : "bg-black/10"))}>
            {c.icon}
          </button>
        ))}
      </div>
      <div className="grid flex-1 grid-cols-8 gap-0.5 overflow-y-auto p-2">
        {emojis.map((e) => (
          <button key={e} onClick={() => onPick(e)}
            className="rounded-lg py-1 text-center text-[22px] leading-none active:bg-black/10">
            {e}
          </button>
        ))}
      </div>
    </div>
  );
}