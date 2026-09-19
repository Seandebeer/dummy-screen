import React, { useState, useRef, useEffect } from "react";
import { LayoutGrid } from "lucide-react";
import { allApps } from "@/lib/osApps";
import { bgPresets } from "@/hooks/useOsConfig";
import IconTile from "./IconTile";
import AppLibrary from "./AppLibrary";
import ClockEditor from "./ClockEditor";
import { cn } from "@/lib/utils";

const PAGE_SIZE = 16;

export default function Homescreen({ config, update, onOpen }) {
  const [library, setLibrary] = useState(false);
  const [clockEdit, setClockEdit] = useState(false);
  const [drag, setDrag] = useState(null);
  const [page, setPage] = useState(0);
  const [swipeOffset, setSwipeOffset] = useState(0);
  const dragRef = useRef(null);
  const holdTimer = useRef(null);
  const pointerStart = useRef(null);
  const swipeStart = useRef(null);
  const suppressClick = useRef(false);

  const light = config.theme === "light";
  const now = new Date();
  const time = config.clock.mode === "custom" && config.clock.time
    ? config.clock.time
    : now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  const date = config.clock.mode === "custom" && config.clock.date
    ? config.clock.date
    : now.toLocaleDateString([], { weekday: "long", month: "long", day: "numeric" });

  const apps = config.order.map((id) => allApps.find((a) => a.id === id)).filter(Boolean);
  const pages = [];
  for (let i = 0; i < apps.length; i += PAGE_SIZE) pages.push(apps.slice(i, i + PAGE_SIZE));
  if (pages.length === 0) pages.push([]);

  useEffect(() => { setPage((p) => Math.min(p, pages.length - 1)); }, [pages.length]);

  const dragApp = drag ? allApps.find((a) => a.id === drag.id) : null;
  const hasImage = config.background.type === "image" && config.background.url;
  const preset = bgPresets.find((p) => p.id === (config.background.preset || "default")) || bgPresets[0];

  const backgroundStyle = hasImage
    ? { backgroundImage: `url(${config.background.url})`, backgroundSize: "cover", backgroundPosition: "center" }
    : { background: preset[light ? "light" : "dark"] };

  const setDragging = (id, x, y) => {
    dragRef.current = { id, x, y };
    setDrag({ id, x, y });
  };

  // live grid reorder while an icon is held & dragged
  useEffect(() => {
    if (!drag) return;
    const move = (e) => {
      const d = dragRef.current;
      if (!d) return;
      dragRef.current = { ...d, x: e.clientX, y: e.clientY };
      setDrag({ ...d, x: e.clientX, y: e.clientY });
      const el = document.elementFromPoint(e.clientX, e.clientY);
      const targetId = el?.closest?.("[data-app-id]")?.dataset?.appId;
      if (targetId && targetId !== d.id) {
        update((c) => {
          const order = [...c.order];
          const from = order.indexOf(d.id);
          const to = order.indexOf(targetId);
          if (from === -1 || to === -1) return {};
          const [moved] = order.splice(from, 1);
          order.splice(to, 0, moved);
          return { order };
        });
      }
    };
    const stop = () => {
      dragRef.current = null;
      setDrag(null);
    };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", stop);
    window.addEventListener("pointercancel", stop);
    return () => {
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", stop);
      window.removeEventListener("pointercancel", stop);
    };
  }, [drag && drag.id, update]);

  const onTilePointerDown = (e, id) => {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    suppressClick.current = false;
    pointerStart.current = { x: e.clientX, y: e.clientY };
    clearTimeout(holdTimer.current);
    holdTimer.current = setTimeout(() => {
      const start = pointerStart.current;
      if (!start) return;
      suppressClick.current = true;
      setDragging(id, start.x, start.y);
    }, 200);
  };

  const onTilePointerMove = (e) => {
    const start = pointerStart.current;
    if (!start || dragRef.current) return;
    if (Math.hypot(e.clientX - start.x, e.clientY - start.y) > 8) {
      clearTimeout(holdTimer.current);
      pointerStart.current = null;
    }
  };

  const cancelHold = () => {
    clearTimeout(holdTimer.current);
    pointerStart.current = null;
  };

  const onTileClick = (id) => {
    if (suppressClick.current) { suppressClick.current = false; return; }
    onOpen(id);
  };

  // page swiping
  const onViewportDown = (e) => { swipeStart.current = { x: e.clientX, active: false }; };
  const onViewportMove = (e) => {
    const s = swipeStart.current;
    if (!s || dragRef.current) return;
    if (!s.active && Math.abs(e.clientX - s.x) < 12) return;
    s.active = true;
    let dx = e.clientX - s.x;
    if ((page === 0 && dx > 0) || (page === pages.length - 1 && dx < 0)) dx *= 0.25;
    setSwipeOffset(dx);
  };
  const onViewportUp = () => {
    const s = swipeStart.current;
    swipeStart.current = null;
    if (!s || !s.active) { setSwipeOffset(0); return; }
    suppressClick.current = true;
    if (swipeOffset < -50 && page < pages.length - 1) setPage(page + 1);
    else if (swipeOffset > 50 && page > 0) setPage(page - 1);
    setSwipeOffset(0);
  };

  const toggleApp = (id) => {
    update({
      order: config.order.includes(id)
        ? config.order.filter((x) => x !== id)
        : [...config.order, id],
    });
  };

  const pill = cn("flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-[10px] font-body uppercase tracking-wider backdrop-blur transition",
    light ? "bg-black/10 border-black/15 text-black/70 hover:bg-black/20" : "bg-white/10 border-white/15 text-white/80 hover:bg-white/20");

  return (
    <div className="h-full flex flex-col relative overflow-hidden" style={backgroundStyle}>
      {!hasImage && <div className="grid-backdrop absolute inset-0 opacity-30 pointer-events-none" />}

      {/* clock — tap to edit */}
      <div className={cn("relative flex flex-col items-center pt-9 pb-2", light ? "text-black/85" : "text-white")}>
        <button onClick={() => setClockEdit(true)} className="flex flex-col items-center">
          <div className="font-display text-6xl font-bold tracking-tight">{time}</div>
          <div className="text-sm mt-1 opacity-60">{date}</div>
        </button>
      </div>

      {clockEdit && (
        <div className="absolute top-28 inset-x-0 z-20 px-4">
          <ClockEditor clock={config.clock}
            onSave={(clock) => { update({ clock }); setClockEdit(false); }}
            onClose={() => setClockEdit(false)} />
        </div>
      )}

      {/* paged app grid — swipe left / right */}
      <div
        className="relative flex-1 overflow-hidden touch-pan-y"
        onPointerDown={onViewportDown}
        onPointerMove={onViewportMove}
        onPointerUp={onViewportUp}
        onPointerCancel={onViewportUp}
      >
        <div
          className="flex h-full"
          style={{
            transform: `translateX(calc(${-page * 100}% + ${swipeOffset}px))`,
            transition: swipeOffset === 0 ? "transform 220ms ease-out" : "none",
          }}
        >
          {pages.map((pageApps, pi) => (
            <div key={pi} className="h-full w-full shrink-0 px-5 pt-2">
              {pageApps.length === 0 ? (
                <p className={cn("pt-12 text-center text-xs font-body", light ? "text-black/40" : "text-white/40")}>No apps — open Apps to add some</p>
              ) : (
                <div className="grid grid-cols-4 gap-y-5 gap-x-3 content-start">
                  {pageApps.map((a) => (
                    <button key={a.id}
                      data-app-id={a.id}
                      onPointerDown={(e) => onTilePointerDown(e, a.id)}
                      onPointerMove={onTilePointerMove}
                      onPointerUp={cancelHold}
                      onPointerCancel={cancelHold}
                      onContextMenu={(e) => e.preventDefault()}
                      onClick={() => onTileClick(a.id)}
                      className={cn("flex flex-col items-center gap-1.5 active:scale-95 transition select-none",
                        drag?.id === a.id && "opacity-30")}>
                      <IconTile app={a} />
                      <span className={cn("text-[11px]", light ? "text-black/80" : "text-white/80")}>{a.label}</span>
                    </button>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* page dots */}
      {pages.length > 1 && (
        <div className="relative flex justify-center gap-1.5 pb-3">
          {pages.map((_, i) => (
            <button key={i} onClick={() => setPage(i)}
              className={cn("h-1.5 rounded-full transition-all",
                light
                  ? i === page ? "w-4 bg-black/70" : "w-1.5 bg-black/25"
                  : i === page ? "w-4 bg-white/80" : "w-1.5 bg-white/30")} />
          ))}
        </div>
      )}

      {/* app library */}
      <div className="relative flex justify-center pb-4">
        <button onClick={() => setLibrary(true)} className={pill}><LayoutGrid size={13} /> Apps</button>
      </div>

      {/* dragged icon ghost */}
      {dragApp && (
        <div className="fixed z-50 pointer-events-none" style={{ left: drag.x, top: drag.y, transform: "translate(-50%, -55%) scale(1.12)" }}>
          <div className="flex flex-col items-center gap-1 opacity-90">
            <IconTile app={dragApp} />
            <span className={cn("text-[11px] font-body", light ? "text-black/80" : "text-white/80")}>{dragApp.label}</span>
          </div>
        </div>
      )}

      {library && <AppLibrary order={config.order} onToggle={toggleApp} onClose={() => setLibrary(false)} />}
    </div>
  );
}