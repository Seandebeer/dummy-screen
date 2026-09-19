import {
  Phone, MessageSquare, Mail, Clock, Contact, Settings,
  Cloud, Waves, Croissant, Atom, Bug, Cat, Moon, Radar, Droplets, Rocket,
  Flame, Sparkles, Carrot, Fish, Music, Footprints, Grid3x3, Tv, Egg, Leaf,
  Mountain, Zap, Pencil, FlaskConical, Megaphone, TreePine, Cherry, Orbit, Drum, Gamepad2,
} from "lucide-react";

export const coreApps = [
  { id: "phone", label: "Phone", Icon: Phone, bg: "#34C759" },
  { id: "messages", label: "Messages", Icon: MessageSquare, bg: "#34C759" },
  { id: "email", label: "Mail", Icon: Mail, bg: "#0A84FF" },
  { id: "clock", label: "Clock", Icon: Clock, bg: "#FF9F0A" },
  { id: "contacts", label: "Contacts", Icon: Contact, bg: "#5A5D6B" },
  { id: "settings", label: "Settings", Icon: Settings, bg: "#636366" },
];

// mock ("downloaded") apps — each with its own tile style
export const mockApps = [
  { id: "nimbus", label: "Nimbus", Icon: Cloud, bg: "#5E5CE6", tile: { type: "duo", bg2: "#A78BFA" } },
  { id: "bloop", label: "Bloop", Icon: Waves, bg: "#38BDF8", tile: { type: "ring", bg2: "#0EA5E9" } },
  { id: "snacc", label: "Snacc", Icon: Croissant, bg: "#FF9F0A", tile: { type: "flat" } },
  { id: "quantum", label: "Quantum", Icon: Atom, bg: "#22D3EE", tile: { type: "outline" } },
  { id: "womp", label: "Wompwomp", Icon: Bug, bg: "#FF453A", tile: { type: "dark" } },
  { id: "chonk", label: "Chonk", Icon: Cat, bg: "#FFB340", tile: { type: "gloss" } },
  { id: "dozer", label: "Dozer", Icon: Moon, bg: "#7C3AED", tile: { type: "mono" } },
  { id: "blip", label: "Blip", Icon: Radar, bg: "#16A34A", tile: { type: "stripes", bg2: "#166534" } },
  { id: "gloop", label: "Gloop", Icon: Droplets, bg: "#00C7BE", tile: { type: "dots", bg2: "#FFFFFF" } },
  { id: "skrrt", label: "Skrrt", Icon: Rocket, bg: "#FF375F", tile: { type: "gloss" } },
  { id: "glowstick", label: "Glowstick", Icon: Flame, bg: "#FF6B00", tile: { type: "dark" } },
  { id: "fizz", label: "Fizz", Icon: Sparkles, bg: "#EC4899", tile: { type: "dots", bg2: "#FFFFFF" } },
  { id: "turnip", label: "Turnip", Icon: Carrot, bg: "#FF6B35", tile: { type: "flat" } },
  { id: "sardines", label: "Sardines", Icon: Fish, bg: "#0E7490", tile: { type: "stripes", bg2: "#155E75" } },
  { id: "kazoo", label: "Kazoo", Icon: Music, bg: "#8B5CF6", tile: { type: "duo", bg2: "#D946EF" } },
  { id: "puddles", label: "Puddles", Icon: Footprints, bg: "#60A5FA", tile: { type: "outline" } },
  { id: "waffle", label: "Waffle", Icon: Grid3x3, bg: "#F97316", tile: { type: "mono" } },
  { id: "static", label: "Static", Icon: Tv, bg: "#4ADE80", tile: { type: "dark" } },
  { id: "cluck", label: "Cluck", Icon: Egg, bg: "#FDE68A", tile: { type: "gloss", fg: "#92400E" } },
  { id: "mossy", label: "Mossy", Icon: Leaf, bg: "#30D158", tile: { type: "flat" } },
  { id: "rubble", label: "Rubble", Icon: Mountain, bg: "#78716C", tile: { type: "duo", bg2: "#A8A29E" } },
  { id: "zaplet", label: "Zaplet", Icon: Zap, bg: "#FFD60A", tile: { type: "ring", bg2: "#FF9F0A", fg: "#783509" } },
  { id: "doodle", label: "Doodle", Icon: Pencil, bg: "#F472B6", tile: { type: "stripes", bg2: "#FBCFE8" } },
  { id: "beaker", label: "Beaker", Icon: FlaskConical, bg: "#06B6D4", tile: { type: "dots", bg2: "#FFFFFF" } },
  { id: "honk", label: "Honk", Icon: Megaphone, bg: "#FF375F", tile: { type: "flat" } },
  { id: "lumber", label: "Lumber", Icon: TreePine, bg: "#166534", tile: { type: "duo", bg2: "#22C55E" } },
  { id: "squish", label: "Squish", Icon: Cherry, bg: "#FF6482", tile: { type: "gloss" } },
  { id: "orbit", label: "Orbit", Icon: Orbit, bg: "#818CF8", tile: { type: "ring", bg2: "#C7D2FE" } },
  { id: "rumble", label: "Rumble", Icon: Drum, bg: "#B45309", tile: { type: "stripes", bg2: "#FCD34D", fg: "#451A03" } },
  { id: "pixel", label: "Pixel", Icon: Gamepad2, bg: "#A78BFA", tile: { type: "dark" } },
];

export const allApps = [...coreApps, ...mockApps];

export const allAppsById = Object.fromEntries(allApps.map((a) => [a.id, a]));