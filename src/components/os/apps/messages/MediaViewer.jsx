import React, { useRef, useState } from "react";
import { Image } from "@/components/ui/image";

// full-screen photo / video viewer for message attachments - drag (swipe)
// the media in any direction and let go to drop back into the thread
export default function MediaViewer({ url, type, onClose }) {
  const [pos, setPos] = useState({ x: 0, y: 0 });
  const start = useRef(null);

  const onDown = (e) => { start.current = { x: e.clientX, y: e.clientY }; };
  const onMove = (e) => {
    if (!start.current) return;
    setPos({ x: e.clientX - start.current.x, y: e.clientY - start.current.y });
  };
  const onUp = () => {
    if (!start.current) return;
    start.current = null;
    if (Math.hypot(pos.x, pos.y) > 70) onClose();
    else setPos({ x: 0, y: 0 });
  };

  return (
    <div className="absolute inset-0 z-50 flex touch-none flex-col bg-black/95"
      onPointerDown={onDown} onPointerMove={onMove} onPointerUp={onUp} onPointerCancel={onUp}>
      <div className="flex flex-1 items-center justify-center overflow-hidden p-3"
        style={{ transform: `translate(${pos.x}px, ${pos.y}px)`, transition: start.current ? "none" : "transform 0.2s" }}>
        {type === "video"
          ? <video src={url} controls autoPlay playsInline className="max-h-full max-w-full rounded-xl" />
          : <Image src={url} alt="" fittingType="fit" className="h-full w-full" />}
      </div>
      <span className="pointer-events-none pb-5 text-center text-xs text-white/50">Swipe to close</span>
    </div>
  );
}