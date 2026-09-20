import {
  Phone, MessageSquare, Mail, Clock, Contact, Settings,
  Calculator, CalendarDays, StickyNote, Aperture, Music, Map, ShoppingBag,
  ThumbsUp, Camera, Play, Music2, Globe, AppWindow, Newspaper, Building2, HeartPulse,
  Video, Images,
} from "lucide-react";
import { mockApps, categories } from "@/lib/mockAppCatalog";

export const coreApps = [
  { id: "phone", label: "Phone", Icon: Phone, bg: "#34C759" },
  { id: "messages", label: "Messages", Icon: MessageSquare, bg: "#34C759" },
  { id: "email", label: "Mail", Icon: Mail, bg: "#0A84FF" },
  { id: "clock", label: "Clock", Icon: Clock, bg: "#FF9F0A" },
  { id: "music", label: "Music", Icon: Music, bg: "#FC3C44" },
  { id: "contacts", label: "Contacts", Icon: Contact, bg: "#5A5D6B" },
  { id: "settings", label: "Settings", Icon: Settings, bg: "#636366" },
  { id: "calculator", label: "Calculator", Icon: Calculator, bg: "#1C1C1E" },
  { id: "calendar", label: "Calendar", Icon: CalendarDays, bg: "#FF3B30" },
  { id: "notes", label: "Notes", Icon: StickyNote, bg: "#FFC800", tile: { type: "flat", fg: "#7A5900" } },
  { id: "camera", label: "Camera", Icon: Aperture, bg: "#2C2C2E" },
  { id: "photos", label: "Photos", Icon: Images, bg: "#FF9500" },
  { id: "videocall", label: "Vidcall", Icon: Video, bg: "#32D74B" },
  { id: "maps", label: "Maps", Icon: Map, bg: "#00C7BE" },
  { id: "appstore", label: "App Library", Icon: ShoppingBag, bg: "#0A84FF" },
  { id: "facepage", label: "Grapevine", Icon: ThumbsUp, bg: "#1877F2", tile: { type: "gloss" } },
  { id: "photogram", label: "Lume", Icon: Camera, bg: "#833AB4", tile: { type: "duo", bg2: "#FD1D1D" } },
  { id: "vidtube", label: "Streamly", Icon: Play, bg: "#FF0000", tile: { type: "gloss" } },
  { id: "quicktok", label: "Flickdeck", Icon: Music2, bg: "#25F4EE", tile: { type: "dark" } },
  { id: "browser", label: "Browser", Icon: Globe, bg: "#0A84FF" },
  { id: "webdeck", label: "Webdeck", Icon: AppWindow, bg: "#FF9F0A", tile: { type: "duo", bg2: "#FFD60A" } },
  { id: "news", label: "Bulletin", Icon: Newspaper, bg: "#DC4A38", tile: { type: "flat" } },
  { id: "property", label: "Realty", Icon: Building2, bg: "#32D74B", tile: { type: "gradient", bg2: "#0E9F8C" } },
  { id: "fitness", label: "Pulse", Icon: HeartPulse, bg: "#FF375F", tile: { type: "gloss" } },
];

// mock ("downloaded") apps live in the category catalog - 20 categories,
// 10 apps each, browsable and addable from the App Library
export { mockApps, categories };

// default home screen - laid out the way Apple / Samsung ship their phones:
// the dock carries the daily drivers (Phone, Browser, Messages, Music), and
// page 1 groups the functional apps into category rows; page 2 holds the
// generic downloaded apps in matching category rows (4 icons per row)
export const defaultHomeOrder = [
  // page 1 · row 1: video calls, schedule & capture (FaceTime / Calendar / Photos / Camera)
  "videocall", "calendar", "photos", "camera",
  // page 1 · row 2: productivity (Mail / Notes / Contacts / Clock)
  "email", "notes", "contacts", "clock",
  // page 1 · row 3: utilities (Maps / App Store / Health / Calculator)
  "maps", "appstore", "fitness", "calculator",
  // page 1 · row 4: social & entertainment
  "facepage", "photogram", "vidtube", "quicktok",
  // page 1 · row 5: info & settings (Settings stays in the bottom row)
  "webdeck", "news", "property", "settings",
  // page 2 · row 1: social & streaming
  "ping", "buzz", "visage", "flixiq",
  // page 2 · row 2: media & daily info
  "waveform", "questly", "headlines24", "skycast",
  // page 2 · row 3: shopping, rides, travel & food
  "findit", "zippyride", "wandermap", "recipebox",
  // page 2 · row 4: health & finance
  "flexr", "walletto",
];

export const allApps = [...coreApps, ...mockApps];

export const allAppsById = Object.fromEntries(allApps.map((a) => [a.id, a]));