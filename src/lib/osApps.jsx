import {
  Phone, MessageSquare, Mail, Clock, Contact, Settings,
  Calculator, CalendarDays, StickyNote, Aperture,
} from "lucide-react";
import { mockApps, categories } from "@/lib/mockAppCatalog";

export const coreApps = [
  { id: "phone", label: "Phone", Icon: Phone, bg: "#34C759" },
  { id: "messages", label: "Messages", Icon: MessageSquare, bg: "#34C759" },
  { id: "email", label: "Mail", Icon: Mail, bg: "#0A84FF" },
  { id: "clock", label: "Clock", Icon: Clock, bg: "#FF9F0A" },
  { id: "contacts", label: "Contacts", Icon: Contact, bg: "#5A5D6B" },
  { id: "settings", label: "Settings", Icon: Settings, bg: "#636366" },
  { id: "calculator", label: "Calculator", Icon: Calculator, bg: "#1C1C1E" },
  { id: "calendar", label: "Calendar", Icon: CalendarDays, bg: "#FF3B30" },
  { id: "notes", label: "Notes", Icon: StickyNote, bg: "#FFC800", tile: { type: "gloss", fg: "#7A5900" } },
  { id: "camera", label: "Camera", Icon: Aperture, bg: "#2C2C2E" },
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