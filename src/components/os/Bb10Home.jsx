import React, { useRef, useState } from "react";
import {
  MessageSquare, Phone, Mail, Calendar, Camera, Settings, Music, Map, Clock,
  Calculator, StickyNote, Users, Video, Search, Mic, Battery, Signal,
  EyeOff, LayoutGrid, ChevronDown,
} from "lucide-react";
import { allAppsById } from "@/lib/osApps";
import { formatBadge } from "@/lib/osNotifications";
import { cn } from "@/lib/utils";

// white line-art glyph per app - BB10 icons sit on a transparent grid
const GRID_ICONS = {
  messages: MessageSquare,
  phone: Phone,
  email: Mail,
  calendar: Calendar,
  camera: Camera,
  settings: Settings,
  music: Music,
  maps: Map,
  clock: Clock,
  calculator: Calculator,
  notes: StickyNote,
  contacts: Users,
  videos: Video,
  appstore: LayoutGrid,
};

const BADGE_KEY = { messages: "messages", phone: "phone", email: "mail" };

export default function Bb10Home({ config, update, onOpen, ui }) {
  const [menu, setMenu] = useState(null);
  const hold = useRef(null);
  const suppressClick = useRef(false);
  const badges = config.badges || {};
  const hubCount = (badges.messages || 0) + (badges.mail || 0) + (badges.phone || 0);
  const now = new Date();
  const date = config.clock.mode === "custom" && config.clock.date
    ? config.clock.date
    : now.toLocaleDateString([], { month: "short", day: "numeric", weekday: "long" });

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

  return (
    <div className="relative h-full overflow-hidden text-[#D1D5DB]" style={{ fontFamily: ui.font }}>
      <div className="flex h-full flex-col">
        {/* top info section: carrier, date, missed calls / messages, hub */}
        <div className="px-5 pt-12">
          <div className="flex items-center justify-between text-[11px]">
            <div className="flex items-center gap-2">
              <Search size={13} className="opacity-70" />
              <span className="text-[13px] font-medium text-white">{config.status?.network || "4G"}</span>
            </div>
            <div className="flex items-center gap-1.5">
              <Calendar size={13} className="opacity-70" />
              <span>{date}</span>
            </div>
          </div>
          <div className="mt-2 flex items-center gap-5 text-[11px]">
            <span className="flex items-center gap-1.5">
              <Phone size={13} className="opacity-70" /> {badges.phone || 0} Missed Calls
            </span>
            <span className="flex items-center gap-1.5">
              <MessageSquare size={13} className="opacity-70" /> {badges.messages || 0} Messages
            </span>
          </div>
          <div className="mt-2.5 flex items-center justify-between border-b border-white/10 pb-1.5 text-[11px]">
            <span className="border-b-2 border-white/80 pb-1.5 -mb-[7px] font-medium text-white">
              Hub{hubCount > 0 ? ` • ${formatBadge(hubCount)} new` : ""}
            </span>
            <span className="flex items-center gap-1 opacity-70">All Accounts <ChevronDown size={12} /></span>
          </div>
        </div>

        {/* 4x4 line-art app grid */}
        <div className="no-scrollbar flex-1 overflow-y-auto px-4 pt-3 pb-1">
          <div className="grid grid-cols-4 content-start gap-x-3 gap-y-5">
            {apps.map((app) => {
              const Icon = GRID_ICONS[app.id] || LayoutGrid;
              const key = BADGE_KEY[app.id];
              const count = key ? badges[key] || 0 : 0;
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
                  className="relative flex select-none flex-col items-center gap-1.5 active:opacity-70"
                >
                  <span className="relative">
                    <Icon size={30} strokeWidth={1.4} className="text-[#D1D5DB]" />
                    {count > 0 && (
                      <span className="absolute -top-1.5 -right-2 flex h-[17px] min-w-[17px] items-center justify-center rounded-full bg-[#E11D48] px-1 text-[10px] font-semibold text-white">
                        {formatBadge(count)}
                      </span>
                    )}
                  </span>
                  <span className="text-[10px] text-[#D1D5DB]/85">{app.label}</span>
                </button>
              );
            })}
            {apps.length === 0 && (
              <p className="col-span-4 pt-10 text-center text-xs text-[#D1D5DB]/50">No apps - open the App Store to add some</p>
            )}
          </div>
        </div>

        {/* bottom utility dock */}
        <div className="border-t border-white/10 px-7 pb-8 pt-2">
          <div className="flex items-center justify-between">
            <button onClick={() => onOpen("messages")} aria-label="Hub"
              className="relative flex h-10 w-10 items-center justify-center text-[#D1D5DB] active:opacity-70">
              <MessageSquare size={19} strokeWidth={1.5} />
              {hubCount > 0 && (
                <span className="absolute right-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-[#E11D48] px-1 text-[9px] font-semibold text-white">
                  {formatBadge(hubCount)}
                </span>
              )}
            </button>
            <button onClick={() => onOpen("appstore")} aria-label="Search"
              className="flex h-10 w-10 items-center justify-center text-[#D1D5DB] active:opacity-70">
              <Search size={19} strokeWidth={1.5} />
            </button>
            <button aria-label="Voice control"
              className="flex h-10 w-10 items-center justify-center text-[#D1D5DB] active:opacity-70">
              <Mic size={19} strokeWidth={1.5} />
            </button>
            <button aria-label="Connections"
              className="flex h-10 w-10 items-center justify-center text-[#D1D5DB] active:opacity-70">
              <Signal size={19} strokeWidth={1.5} />
            </button>
            <button aria-label="Battery"
              className="flex h-10 w-10 items-center justify-center text-[#D1D5DB] active:opacity-70">
              <Battery size={19} strokeWidth={1.5} />
            </button>
          </div>
        </div>
      </div>

      {/* long-press menu: hide an app straight from the grid */}
      {menu && (() => {
        const app = allAppsById[menu];
        return (
          <>
            <div className="absolute inset-0 z-40" onPointerDown={(e) => { e.stopPropagation(); setMenu(null); }} />
            <div className="absolute inset-x-4 top-1/2 z-50 -translate-y-1/2 overflow-hidden rounded-lg border border-white/15 bg-[#161b22]/95 backdrop-blur-xl">
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