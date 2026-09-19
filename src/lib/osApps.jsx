import {
  Phone, MessageSquare, Mail, Clock, Contact, Settings,
  Croissant, Carrot, Leaf, Megaphone, Pizza, Key,
} from "lucide-react";

export const coreApps = [
  { id: "phone", label: "Phone", Icon: Phone, bg: "#34C759" },
  { id: "messages", label: "Messages", Icon: MessageSquare, bg: "#34C759" },
  { id: "email", label: "Mail", Icon: Mail, bg: "#0A84FF" },
  { id: "clock", label: "Clock", Icon: Clock, bg: "#FF9F0A" },
  { id: "contacts", label: "Contacts", Icon: Contact, bg: "#5A5D6B" },
  { id: "settings", label: "Settings", Icon: Settings, bg: "#636366" },
];

// mock ("downloaded") apps — plain flat tiles only
export const mockApps = [
  { id: "snacc", label: "Snacc", Icon: Croissant, bg: "#FF9F0A", tile: { type: "flat" } },
  { id: "turnip", label: "Turnip", Icon: Carrot, bg: "#FF6B35", tile: { type: "flat" } },
  { id: "mossy", label: "Mossy", Icon: Leaf, bg: "#30D158", tile: { type: "flat" } },
  { id: "honk", label: "Honk", Icon: Megaphone, bg: "#FF375F", tile: { type: "flat" } },
  { id: "slice", label: "Slice", Icon: Pizza, bg: "#FF453A", tile: { type: "flat" } },
  { id: "keyring", label: "Keyring", Icon: Key, bg: "#FBBF24", tile: { type: "flat" } },
];

export const allApps = [...coreApps, ...mockApps];

export const allAppsById = Object.fromEntries(allApps.map((a) => [a.id, a]));