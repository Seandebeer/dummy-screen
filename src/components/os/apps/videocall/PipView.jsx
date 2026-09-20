import React, { useEffect, useRef, useState } from "react";
import { VideoOff } from "lucide-react";
import { cn } from "@/lib/utils";

// the self-view picture in picture - draggable anywhere on the screen,
// snapping to the nearest corner on release, tap-aware like FaceTime
export default function PipView({ containerRef, videoRef, camError, facing, onTap }) {
  const pipRef = useRef(null);
  const dragRef = useRef(null);
  const [pos, setPos] = useState(null); // px top-left; null = default corner
  const [dragging, setDragging] = useState(false);

  const startDrag = (e) => {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    const c = containerRef?.current, p = pipRef.current;
    if (!c || !p) return;
    const crect = c.getBoundingClientRect(), prect = p.getBoundingClientRect();
    dragRef.current = {
      sx: e.clientX, sy: e.clientY,
      orig: { x: prect.left - crect.left, y: prect.top - crect.top },
      w: prect.width, h: prect.height, cw: crect.width, ch: crect.height,
      moved: false,
    };
    setDragging(true);
  };

  useEffect(() => {
    if (!dragging) return undefined;
    const move = (e) => {
      const d = dragRef.current;
      if (!d) return;
      const dx = e.clientX - d.sx, dy = e.clientY - d.sy;
      if (!d.moved && Math.hypot(dx, dy) > 5) d.moved = true;
      setPos({
        x: Math.max(4, Math.min(d.cw - d.w - 4, d.orig.x + dx)),
        y: Math.max(4, Math.min(d.ch - d.h - 4, d.orig.y + dy)),
      });
    };
    const up = () => {
      const d = dragRef.current;
      setDragging(false);
      if (!d) return;
      if (d.moved) {
        // FaceTime style: settle into the nearest corner
        const xs = [4, d.cw - d.w - 4], ys = [4, d.ch - d.h - 4];
        setPos((p) => ({
          x: Math.abs(p.x - xs[0]) < Math.abs(p.x - xs[1]) ? xs[0] : xs[1],
          y: Math.abs(p.y - ys[0]) < Math.abs(p.y - ys[1]) ? ys[0] : ys[1],
        }));
      } else onTap?.();
    };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
    window.addEventListener("pointercancel", up);
    return () => {
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", up);
      window.removeEventListener("pointercancel", up);
    };
  }, [dragging]);

  return (
    <div ref={pipRef} onPointerDown={startDrag}
      style={pos ? { left: pos.x, top: pos.y } : undefined}
      className={cn("absolute z-20 aspect-[3/4] w-[28%] touch-none select-none overflow-hidden rounded-2xl border border-white/25 bg-black/70 shadow-xl",
        !pos && "bottom-20 right-2",
        dragging ? "cursor-grabbing" : "cursor-grab")}>
      {camError ? (
        <div className="flex h-full w-full flex-col items-center justify-center gap-1 text-center">
          <VideoOff size={16} className="text-white/40" />
          <span className="px-1 text-[8px] font-body text-white/40">Camera unavailable</span>
        </div>
      ) : (
        <video ref={videoRef} autoPlay playsInline muted
          className={cn("h-full w-full object-cover", facing === "user" && "scale-x-[-1]")} />
      )}
    </div>
  );
}