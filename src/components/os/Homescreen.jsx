import React, { useState, useRef, useEffect } from "react";
import { EyeOff, LayoutGrid } from "lucide-react";
import { allApps, allAppsById } from "@/lib/osApps";
import { bgPresets } from "@/hooks/useOsConfig";
import { uiFor } from "@/lib/osLanguages";
import IconTile from "./IconTile";
import { skinOf } from "@/lib/osSkins";
import { formatBadge, normalizeBadge } from "@/lib/osNotifications";
import AppLibrary from "./AppLibrary";
import ClockEditor from "./ClockEditor";
import { cn } from "@/lib/utils";

const PAGE_SIZE = 20;
const DOCK_SLOTS = [0, 1, 2, 3];
const BADGE_APPS = ["phone", "messages", "email"];

export default function Homescreen({ config, update, onOpen }) {
  const [library, setLibrary] = useState(false);
  const [clockEdit, setClockEdit] = useState(false);
  const [drag, setDrag] = useState(null);
  const [menu, setMenu] = useState(null);
  const rootRef = useRef(null);
  const [page, setPage] = useState(0);
  const [swipeOffset, setSwipeOffset] = useState(0);
  const dragRef = useRef(null);
  const holdTimer = useRef(null);
  const pointerStart = useRef(null);
  const swipeStart = useRef(null);
  const suppressClick = useRef(false);
  const lastDrop = useRef(null);

  const light = config.theme === "light";
  const skin = skinOf(config);
  const t = uiFor(config.language);
  const now = new Date();
  const time = config.clock.mode === "custom" && config.clock.time
    ? config.clock.time
    : now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  const date = config.clock.mode === "custom" && config.clock.date
    ? config.clock.date
    : now.toLocaleDateString([], { weekday: "long", month: "long", day: "numeric" });

  const dockIds = config.dock || [];
  const gridIds = config.order.filter((id) => !dockIds.includes(id));
  const apps = gridIds.map((id) => allApps.find((a) => a.id === id)).filter(Boolean);
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

  // pick up an icon for dragging - closes any open menu, cancels any swipe
  const startDrag = (id, x, y) => {
    suppressClick.current = true;
    setMenu(null);
    swipeStart.current = null;
    setSwipeOffset(0);
    setDragging(id, x, y);
  };

  // remove an app from the home screen + dock without opening the library
  const hideApp = (id) => update((c) => ({
    order: c.order.filter((x) => x !== id),
    dock: (c.dock || []).filter((x) => x !== id),
  }));

  // hold an icon still to open its menu (hide it right on the home screen);
  // moving while the menu is open picks the icon up and drags it instead
  const openMenu = (id, px, py) => {
    const rect = rootRef.current?.getBoundingClientRect();
    if (!rect) return;
    setMenu({
      id, px, py,
      left: Math.min(Math.max(px - rect.left, 90), rect.width - 90),
      top: Math.min(Math.max(py - rect.top - 86, 68), rect.height - 116),
    });
  };

  useEffect(() => {
    if (!menu) return;
    const move = (e) => {
      if (e.pointerType === "mouse" && e.buttons === 0) return;
      if (Math.hypot(e.clientX - menu.px, e.clientY - menu.py) > 14) {
        startDrag(menu.id, e.clientX, e.clientY);
      }
    };
    window.addEventListener("pointermove", move);
    return () => window.removeEventListener("pointermove", move);
  }, [menu]);

  // live reorder + dock<->grid moves while an icon is held & dragged
  useEffect(() => {
    if (!drag) return;
    const move = (e) => {
      const d = dragRef.current;
      if (!d) return;
      dragRef.current = { ...d, x: e.clientX, y: e.clientY };
      setDrag({ ...d, x: e.clientX, y: e.clientY });
      const el = document.elementFromPoint(e.clientX, e.clientY);
      const slotEl = el?.closest?.("[data-dock-slot]");
      if (slotEl) {
        const slot = Number(slotEl.dataset.dockSlot);
        if (lastDrop.current !== `dock:${d.id}:${slot}`) {
          lastDrop.current = `dock:${d.id}:${slot}`;
          update((c) => {
            const dock = [...(c.dock || [])];
            const order = [...c.order];
            const from = dock.indexOf(d.id);
            if (from === slot) return {};
            if (from !== -1) {
              const [m] = dock.splice(from, 1);
              dock.splice(slot, 0, m);
            } else {
              const displaced = dock[slot];
              dock[slot] = d.id;
              const oi = order.indexOf(d.id);
              if (oi !== -1) {
                if (displaced) order[oi] = displaced; else order.splice(oi, 1);
              } else if (displaced) order.push(displaced);
            }
            return { dock, order };
          });
        }
        return;
      }
      const targetId = el?.closest?.("[data-app-id]")?.dataset?.appId;
      if (targetId && targetId !== d.id && lastDrop.current !== `grid:${d.id}:${targetId}`) {
        lastDrop.current = `grid:${d.id}:${targetId}`;
        update((c) => {
          const order = [...c.order];
          const fromDock = (c.dock || []).indexOf(d.id);
          const to = order.indexOf(targetId);
          if (to === -1) return {};
          if (fromDock !== -1) {
            order.splice(to, 0, d.id);
            return { dock: (c.dock || []).filter((x) => x !== d.id), order };
          }
          const from = order.indexOf(d.id);
          if (from === -1) return {};
          const [m] = order.splice(from, 1);
          order.splice(order.indexOf(targetId) === -1 ? to : order.indexOf(targetId), 0, m);
          return { order };
        });
      }
      // dragging a dock app over the grid pulls it out of the dock
      const gridEl = el?.closest?.("[data-grid]");
      if (gridEl && !slotEl && lastDrop.current !== `offdock:${d.id}`) {
        lastDrop.current = `offdock:${d.id}`;
        update((c) => {
          const dock = c.dock || [];
          if (!dock.includes(d.id)) return {};
          return { dock: dock.filter((x) => x !== d.id), order: [...c.order, d.id] };
        });
      }
    };
    const stop = () => {
      dragRef.current = null;
      setDrag(null);
      lastDrop.current = null;
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
    pointerStart.current = { id, x: e.clientX, y: e.clientY, t: Date.now() };
    clearTimeout(holdTimer.current);
    holdTimer.current = setTimeout(() => {
      const start = pointerStart.current;
      if (!start) return;
      suppressClick.current = true;
      pointerStart.current = null;
      openMenu(start.id, start.x, start.y);
    }, 300);
  };

  const onTilePointerMove = (e) => {
    const start = pointerStart.current;
    if (!start || dragRef.current) return;
    if (Math.hypot(e.clientX - start.x, e.clientY - start.y) <= 14) return;
    clearTimeout(holdTimer.current);
    pointerStart.current = null;
    // a quick flick swipes pages; press, brief pause, then move = pick up & drag
    if (Date.now() - start.t >= 180) startDrag(start.id, e.clientX, e.clientY);
  };

  const cancelHold = () => {
    clearTimeout(holdTimer.current);
    pointerStart.current = null;
  };

  const onTileClick = (id) => {
    if (suppressClick.current) { suppressClick.current = false; return; }
    onOpen(id);
  }

  // unread badges on the phone / messages / mail icons - hold the number to
  // set it manually (0 - 1,000,000)
  const badgeKey = (id) => (id === "email" ? "mail" : id);
  const badgeCount = (id) => (config.badges || {})[badgeKey(id)] || 0;
  const badgeHold = useRef(null);
  const cancelBadgeHold = () => clearTimeout(badgeHold.current);
  const onBadgeDown = (e, app) => {
    e.stopPropagation();
    clearTimeout(badgeHold.current);
    badgeHold.current = setTimeout(() => {
      suppressClick.current = true;
      const raw = window.prompt(`Unread number for ${app.label} (0 - 1,000,000):`, badgeCount(app.id));
      if (raw === null) return;
      update((c) => ({ badges: { ...(c.badges || {}), [badgeKey(app.id)]: normalizeBadge(raw) } }));
    }, 550);
  };
  const iconWithBadge = (app) => {
    const badge = BADGE_APPS.includes(app.id) ? badgeCount(app.id) : 0;
    return (
      <span className="relative block">
        <IconTile app={app} />
        {badge > 0 && (
          <span
            onPointerDown={(e) => onBadgeDown(e, app)}
            onPointerUp={cancelBadgeHold}
            onPointerLeave={cancelBadgeHold}
            onPointerCancel={cancelBadgeHold}
            onContextMenu={(e) => e.preventDefault()}
            className="absolute -top-1 -right-2 z-10 flex h-[18px] min-w-[18px] items-center justify-center rounded-full bg-[#FF3B30] px-1 text-[10px] font-semibold font-body text-white shadow-md">
            {formatBadge(badge)}
          </span>
        )}
      </span>
    );
  };;

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
    if (dragRef.current || menu) { setSwipeOffset(0); return; }
    if (!s || !s.active) { setSwipeOffset(0); return; }
    suppressClick.current = true;
    if (swipeOffset < -50 && page < pages.length - 1) setPage(page + 1);
    else if (swipeOffset > 50 && page > 0) setPage(page - 1);
    setSwipeOffset(0);
  };

  const toggleApp = (id) => {
    update((c) => {
      if (c.order.includes(id)) {
        return { order: c.order.filter((x) => x !== id), dock: (c.dock || []).filter((x) => x !== id) };
      }
      return { order: [...c.order, id] };
    });
  };

  const tileButton = (a) => (
    <button
      data-app-id={a.id}
      onPointerDown={(e) => onTilePointerDown(e, a.id)}
      onPointerMove={onTilePointerMove}
      onPointerUp={cancelHold}
      onPointerCancel={cancelHold}
      onContextMenu={(e) => e.preventDefault()}
      onClick={() => onTileClick(a.id)}
      className={cn("flex touch-none flex-col items-center gap-1.5 active:scale-95 transition select-none",
        drag?.id === a.id && "opacity-30")}
    >
      {iconWithBadge(a)}
      <span className={cn("text-[11px]", light ? "text-black/85" : "text-white/95")}>{a.label}</span>
    </button>
  );

  return (
    <div ref={rootRef} dir={config.language === "ar" ? "rtl" : "ltr"} className="h-full flex flex-col relative overflow-hidden" style={backgroundStyle}>

      {/* clock - tap to edit · apps library top-right */}
      <div className={cn("relative flex flex-col items-center pt-9 pb-2", light ? "text-black/85" : "text-white")}>
        <button onClick={() => setClockEdit(true)} className="flex flex-col items-center">
          <div
            className={cn("font-display text-[52px] leading-none tracking-[-0.02em]",
              skin.id === "aqua" ? "font-bold" : skin.id === "android" ? "font-light" : "font-semibold")}
            style={skin.id === "aqua" ? { textShadow: "0 1px 2px rgba(0,0,0,0.45)" } : undefined}>{time}</div>
          <div className="text-[13px] mt-1 font-medium opacity-55">{date}</div>
        </button>
        <button onClick={() => setLibrary(true)}
          className={cn("absolute right-3.5 top-8 flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-[10px] font-body uppercase tracking-wider backdrop-blur transition",
            light ? "bg-black/10 border-black/15 text-black/70 hover:bg-black/20" : "bg-white/10 border-white/15 text-white/80 hover:bg-white/20")}>
          <LayoutGrid size={12} /> {t.apps}
        </button>
      </div>

      {clockEdit && (
        <div className="absolute top-28 inset-x-0 z-20 px-4">
          <ClockEditor clock={config.clock}
            onSave={(clock) => { update({ clock }); setClockEdit(false); }}
            onClose={() => setClockEdit(false)} />
        </div>
      )}

      {/* paged app grid - swipe left / right */}
      <div
        data-grid
        className="relative flex-1 overflow-hidden"
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
            <div key={pi} className="h-full w-full shrink-0 px-5 pt-1.5">
              {pageApps.length === 0 ? (
                <p className={cn("pt-10 text-center text-xs font-body", light ? "text-black/40" : "text-white/40")}>No apps - open Apps to add some</p>
              ) : (
                <div className="grid grid-cols-4 gap-y-5 gap-x-4 content-start">
                  {pageApps.map((a) => (
                    <div key={a.id} className="flex justify-center">{tileButton(a)}</div>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* page dots */}
      {pages.length > 1 && (
        <div className="relative flex justify-center gap-1.5 pb-1.5">
          {pages.map((_, i) => (
            <button key={i} onClick={() => setPage(i)}
              className={cn("h-1.5 rounded-full transition-all",
                light
                  ? i === page ? "w-4 bg-black/70" : "w-1.5 bg-black/25"
                  : i === page ? "w-4 bg-white/80" : "w-1.5 bg-white/30")} />
          ))}
        </div>
      )}

      {/* dock - hold & drag apps in / out */}
      <div className={cn("relative mx-4 mb-3 flex items-center justify-around gap-1 px-2 py-2.5",
        skin.id === "aqua" && "rounded-2xl border border-white/40 bg-gradient-to-b from-[#e2e6ef]/95 to-[#9aa5ba]/95 shadow-[0_2px_8px_rgba(0,0,0,0.35)]",
        skin.id === "android" && "rounded-[1.6rem] border border-white/10 bg-[#16212b]/80 backdrop-blur-2xl",
        skin.id === "modern" && "rounded-[1.9rem] backdrop-blur-2xl",
        skin.id === "modern" && (light ? "bg-white/35" : "bg-white/15"))}>
        {DOCK_SLOTS.map((slot) => {
          const appId = dockIds[slot];
          const app = appId ? allAppsById[appId] : null;
          return (
            <div key={slot} data-dock-slot={slot} className="flex-1 flex justify-center">
              {app ? (
                <button
                  onPointerDown={(e) => onTilePointerDown(e, app.id)}
                  onPointerMove={onTilePointerMove}
                  onPointerUp={cancelHold}
                  onPointerCancel={cancelHold}
                  onContextMenu={(e) => e.preventDefault()}
                  onClick={() => onTileClick(app.id)}
                  className={cn("touch-none active:scale-95 transition select-none", drag?.id === app.id && "opacity-30")}>
                  {iconWithBadge(app)}
                </button>
              ) : (
                <span className={cn("h-14 w-14 rounded-[23%] border border-dashed", light ? "border-black/15" : "border-white/15")} />
              )}
            </div>
          );
        })}
      </div>

      {/* dragged icon ghost */}
      {dragApp && (
        <div className="fixed z-50 pointer-events-none" style={{ left: drag.x, top: drag.y, transform: "translate(-50%, -55%) scale(1.12)" }}>
          <div className="flex flex-col items-center gap-1 opacity-90">
            <IconTile app={dragApp} />
            <span className={cn("text-[11px] font-body", light ? "text-black/85" : "text-white/95")}>{dragApp.label}</span>
          </div>
        </div>
      )}

      {/* long-press menu: hide an app straight from the home screen */}
      {menu && (() => {
        const app = allAppsById[menu.id];
        if (!app) return null;
        return (
          <>
            <div className="absolute inset-0 z-40" onPointerDown={(e) => { e.stopPropagation(); setMenu(null); }} />
            <div
              className={cn("absolute z-50 -translate-x-1/2 w-44 overflow-hidden rounded-2xl border shadow-2xl backdrop-blur-xl",
                light ? "border-black/10 bg-white/85" : "border-white/15 bg-[#1c1c1e]/90")}
              style={{ left: menu.left, top: menu.top }}>
              <div className={cn("px-3 py-1.5 text-[10px] font-body truncate", light ? "text-black/45" : "text-white/45")}>{app.label}</div>
              <button onClick={() => { hideApp(menu.id); setMenu(null); }}
                className="flex w-full items-center gap-2 px-3 py-2 text-[12px] font-body transition hover:bg-white/10">
                <EyeOff size={13} className={light ? "text-black/55" : "text-white/60"} /> Hide App
              </button>
              <button onClick={() => setMenu(null)}
                className={cn("flex w-full items-center gap-2 border-t px-3 py-2 text-[12px] font-body transition hover:bg-white/10",
                  light ? "border-black/10 text-black/65" : "border-white/10 text-white/65")}>
                Cancel
              </button>
            </div>
          </>
        );
      })()}

      {library && <AppLibrary order={config.order} onToggle={toggleApp} onClose={() => setLibrary(false)} />}
    </div>
  );
}