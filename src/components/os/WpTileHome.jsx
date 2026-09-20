import React, { useRef, useState } from "react";
import {
  Users, Phone, MessageSquare, Mail, Calendar, Camera, ShoppingBag,
  Music, Map, Clock, Calculator, StickyNote, Settings, Video, EyeOff, LayoutGrid,
} from "lucide-react";
import { allAppsById } from "@/lib/osApps";
import { formatBadge } from "@/lib/osNotifications";
import { cn } from "@/lib/utils";

// Metro tile look per app - accent colour, glyph, and wide/square footprint
const TILE_STYLES = {
  contacts: { color: "#00a2e8", icon: Users, wide: true },
  phone: { color: "#ec008c", icon: Phone, badge: "phone" },
  messages: { color: "#60a917", icon: MessageSquare, badge: "messages" },
  email: { color: "#0072c6", icon: Mail, badge: "mail" },
  calendar: { color: "#f09609", icon: Calendar, date: true },
  camera: { color: "#e51400", icon: Camera, wide: true },
  appstore: { color: "#00a2e8", icon: ShoppingBag },
  music: { color: "#4c4c4c", icon: Music },
  maps: { color: "#4c4c4c", icon: Map },
  clock: { color: "#4c4c4c", icon: Clock },
  calculator: { color: "#4c4c4c", icon: Calculator },
  notes: { color: "#4c4c4c", icon: StickyNote },
  settings: { color: "#4c4c4c", icon: Settings },
  videos: { color: "#4c4c4c", icon: Video },
};

const FALLBACK_COLOR = "#4c4c4c";

export default function WpTileHome({ config, update, onOpen, ui }) {
  const [menu, setMenu] = useState(null);
  const hold = useRef(null);
  const suppressClick = useRef(false);
  const now = new Date();
  const dateShort = now.toLocaleDateString([], { weekday: "short", day: "numeric" });

  const cancelHold = () => clearTimeout(hold.current);
  const press = (e, app) => {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    suppressClick.current = false;
    cancelHold();
    hold.current = setTimeout(() => {
      suppressClick.current = true;
      setMenu(app.id);
    }, 380);
  };

  const hideApp = (id) => {
    setMenu(null);
    update((c) => ({
      order: c.order.filter((x) => x !== id),
      dock: (c.dock || []).filter((x) => x !== id),
    }));
  };

  const apps = config.order.map((id) => allAppsById[id]).filter(Boolean);

  const tile = (app) => {
    const st = TILE_STYLES[app.id] || {};
    const Icon = st.icon || LayoutGrid;
    const badge = st.badge ? (config.badges || {})[st.badge] || 0 : 0;
    const wide = !!st.wide;
    return (
      <button
        key={app.id}
        onPointerDown={(e) => press(e, app)}
        onPointerUp={cancelHold}
        onPointerLeave={cancelHold}
        onPointerCancel={cancelHold}
        onContextMenu={(e) => e.preventDefault()}
        onClick={() => {
          if (suppressClick.current) { suppressClick.current = false; return; }
          if (!menu) onOpen(app.id);
        }}
        style={{ background: st.color || FALLBACK_COLOR }}
        className={cn(
          "relative flex flex-col items-start justify-end p-2.5 text-left text-white transition select-none active:opacity-80",
          wide ? "w-full aspect-[2.1/1]" : "w-[calc(50%-3px)] aspect-square"
        )}
      >
        {badge > 0 && (
          <span className="absolute top-1.5 right-1.5 flex h-5 min-w-5 items-center justify-center rounded-full bg-[#9a9a9e] px-1 text-[11px] font-semibold">
            {formatBadge(badge)}
          </span>
        )}
        {st.date ? (
          <span className="mb-1 text-[22px] font-semibold leading-none">{dateShort}</span>
        ) : (
          <Icon size={30} strokeWidth={1.6} className="mb-1.5" />
        )}
        <span className="text-[11px] font-semibold tracking-wide">{app.label}</span>
      </button>
    );
  };

  return (
    <div className="h-full relative overflow-hidden" style={{ fontFamily: ui.font }}>
      {/* scrolling live-tile start screen */}
      <div className="no-scrollbar h-full overflow-y-auto px-3 pt-12 pb-16 flex flex-wrap content-start gap-1.5">
        {apps.map(tile)}
        {apps.length === 0 && (
          <p className="w-full pt-10 text-center text-xs text-white/50">No apps - open the App Library to add some</p>
        )}
      </div>

      {/* corner link into the full app list */}
      <div className="absolute bottom-6 right-3 z-30">
        <button onClick={() => onOpen("appstore")} aria-label="App list"
          className="flex h-8 w-8 items-center justify-center rounded-full border border-white/40 bg-black/30 transition hover:bg-white/15">
          <LayoutGrid size={14} className="text-white/85" />
        </button>
      </div>

      {/* long-press menu: hide a tile straight from the start screen */}
      {menu && (() => {
        const app = allAppsById[menu];
        return (
          <>
            <div className="absolute inset-0 z-40" onPointerDown={(e) => { e.stopPropagation(); setMenu(null); }} />
            <div className="absolute inset-x-4 top-1/2 z-50 -translate-y-1/2 overflow-hidden rounded-lg border border-white/15 bg-[#1c1c1e]/95 backdrop-blur-xl">
              <div className="px-3 py-1.5 text-[10px] font-body text-white/45">{app?.label}</div>
              <button onClick={() => hideApp(menu)}
                className="flex w-full items-center gap-2 px-3 py-2 text-[12px] font-body text-white transition hover:bg-white/10">
                <EyeOff size={13} /> Hide App
              </button>
              <button onClick={() => setMenu(null)}
                className="flex w-full items-center gap-2 border-t border-white/10 px-3 py-2 text-[12px] font-body text-white/65 transition hover:bg-white/10">
                Cancel
              </button>
            </div>
          </>
        );
      })()}
    </div>
  );
}