import {
  Phone, MessageSquare, Mail, Clock, Contact, Settings,
  Calculator, CalendarDays, StickyNote, Aperture, Music, Map, ShoppingBag,
  ThumbsUp, Camera, Play, Music2,
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
  { id: "notes", label: "Notes", Icon: StickyNote, bg: "#FFC800", tile: { type: "gloss", fg: "#7A5900" } },
  { id: "camera", label: "Camera", Icon: Aperture, bg: "#2C2C2E" },
  { id: "maps", label: "Maps", Icon: Map, bg: "#00C7BE" },
  { id: "appstore", label: "App Store", Icon: ShoppingBag, bg: "#0A84FF", tile: { type: "gloss" } },
  { id: "facepage", label: "Facepage", Icon: ThumbsUp, bg: "#1877F2", tile: { type: "gloss" } },
  { id: "photogram", label: "Photogram", Icon: Camera, bg: "#833AB4", tile: { type: "duo", bg2: "#FD1D1D" } },
  { id: "vidtube", label: "VidTube", Icon: Play, bg: "#FF0000", tile: { type: "gloss" } },
  { id: "quicktok", label: "QuickTok", Icon: Music2, bg: "#25F4EE", tile: { type: "dark" } },
];

// mock ("downloaded") apps live in the category catalog - 20 categories,
// 10 apps each, browsable and addable from the App Library
export { mockApps, categories };

// default home screen - the functional apps fill page 1, a few generic
// downloaded apps spill onto page 2
export const defaultHomeOrder = [
  ...coreApps.map((a) => a.id),
  "ping", "buzz", "visage", "flixiq", "waveform", "questly",
  "headlines24", "skycast", "findit", "zippyride", "wandermap",
  "recipebox", "flexr", "walletto",
];

export const allApps = [...coreApps, ...mockApps];

export const allAppsById = Object.fromEntries(allApps.map((a) => [a.id, a]));