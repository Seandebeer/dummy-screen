import React from "react";
import { Delete } from "lucide-react";
import { cn } from "@/lib/utils";

const KEYS = [
  ["1", ""], ["2", "ABC"], ["3", "DEF"],
  ["4", "GHI"], ["5", "JKL"], ["6", "MNO"],
  ["7", "PQRS"], ["8", "TUV"], ["9", "WXYZ"],
];

export default function PasscodePad({ light, onPress, onDelete }) {
  const key = cn("flex flex-col items-center justify-center rounded-full h-20 w-20 active:scale-95 transition select-none",
    light ? "bg-black/10 text-black/85 active:bg-black/25" : "bg-white/10 text-white active:bg-white/25");

  return (
    <div className="w-full max-w-[280px] mx-auto">
      <div className="grid grid-cols-3 gap-x-5 gap-y-3 justify-items-center">
        {KEYS.map(([d, letters]) => (
          <button key={d} onClick={() => onPress(d)} className={key}>
            <span className="font-display text-3xl font-light leading-none">{d}</span>
            {letters && <span className="text-[9px] tracking-[0.18em] mt-0.5 opacity-60 font-body">{letters}</span>}
          </button>
        ))}
        <div />
        <button onClick={() => onPress("0")} className={key}>
          <span className="font-display text-3xl font-light leading-none">0</span>
          <span className="text-[9px] tracking-[0.18em] mt-0.5 opacity-60 font-body">+</span>
        </button>
        <button onClick={onDelete} className={cn(key, "justify-center")}>
          <Delete size={20} className="opacity-70" />
        </button>
      </div>
    </div>
  );
}