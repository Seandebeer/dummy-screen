import React from "react";
import { Zap } from "lucide-react";

// stylised 80s-band-style wordmark for the app name - chrome letters with a
// lightning bolt between the words, like a vintage metal album logo
export default function DummyPhoneWordmark() {
  return (
    <div className="flex items-center gap-2 select-none" aria-label="Dummy Phone">
      <span className="band-wordmark text-[30px] leading-none">DUMMY</span>
      <Zap size={20} className="shrink-0 text-amber amber-pulse" fill="currentColor" />
      <span className="band-wordmark text-[30px] leading-none">PHONE</span>
    </div>
  );
}