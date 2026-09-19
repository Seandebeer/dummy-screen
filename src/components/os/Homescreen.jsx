import React, { useState, useRef, useEffect } from "react";
import { LayoutGrid } from "lucide-react";
import { allApps } from "@/lib/osApps";
import { bgPresets } from "@/hooks/useOsConfig";
import IconTile from "./IconTile";
import AppLibrary from "./AppLibrary";
import ClockEditor from "./ClockEditor";
import { cn } from "@/lib/utils";

export default function Homescreen({ config, update, onOpen }) {
  const [library, setLibrary] = useState(false);
  const [clockEdit, setClockEdit] = useState(false);
  const [drag, setDrag] = useState(null);
  const dragRef = useRef(null);
  const holdTimer = useRef(null);
  const pointerStart = useRef(null);
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
    const blockScroll = (e) => e.preventDefault();
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", stop);
    window.addEventListener("pointercancel", stop);
    document.addEventListener("touchmove", blockScroll, { passive: false });
    return () => {
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", stop);
      window.removeEventListener("pointercancel", stop);
      document.removeEventListener("touchmove", blockScroll);
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

      {/* app grid */}
      <div className="relative flex-1 overflow-y-auto no-scrollbar">
        {apps.length === 0 ? (
          <p className={cn("pt-12 text-center text-xs font-body", light ? "text-black/40" : "text-white/40")}>No apps — open Apps to add some</p>
        ) : (
          <div className="grid grid-cols-4 gap-y-5 gap-x-3 px-5 content-start pt-3 pb-4">
            {apps.map((a) => (
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