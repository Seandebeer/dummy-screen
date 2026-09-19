import { Phone, MessageSquare, Mail, Clock, Contact, Cloud, Waves, Croissant, Atom, Bug, Cat, Moon, Radar, Droplets, Rocket } from "lucide-react";

export const coreApps = [
  { id: "phone", label: "Phone", Icon: Phone, bg: "#34C759" },
  { id: "messages", label: "Messages", Icon: MessageSquare, bg: "#34C759" },
  { id: "email", label: "Mail", Icon: Mail, bg: "#0A84FF" },
  { id: "clock", label: "Clock", Icon: Clock, bg: "#FF9F0A" },
  { id: "contacts", label: "Contacts", Icon: Contact, bg: "#5A5D6B" },
];

export const mockApps = [
  { id: "nimbus", label: "Nimbus", Icon: Cloud, bg: "#5E5CE6", mock: true },
  { id: "bloop", label: "Bloop", Icon: Waves, bg: "#0A84FF", mock: true },
  { id: "snacc", label: "Snacc", Icon: Croissant, bg: "#FF6482", mock: true },
  { id: "quantum", label: "Quantum", Icon: Atom, bg: "#64D2FF", mock: true },
  { id: "womp", label: "Wompwomp", Icon: Bug, bg: "#FF453A", mock: true },
  { id: "chonk", label: "Chonk", Icon: Cat, bg: "#FFB340", mock: true },
  { id: "dozer", label: "Dozer", Icon: Moon, bg: "#7D7AFF", mock: true },
  { id: "blip", label: "Blip", Icon: Radar, bg: "#30D158", mock: true },
  { id: "gloop", label: "Gloop", Icon: Droplets, bg: "#00C7BE", mock: true },
  { id: "skrrt", label: "Skrrt", Icon: Rocket, bg: "#FF375F", mock: true },
];

export const allApps = [...coreApps, ...mockApps];

export const allAppsById = Object.fromEntries(allApps.map((a) => [a.id, a]));