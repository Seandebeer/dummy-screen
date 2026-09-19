import { makeNames } from "./osLanguages";

export const DIAL_CODES = ["026", "034", "049"];

export const mockContacts = [
  { id: "c1", name: "Sarah Chen", suffix: "555 0142", email: "sarah.chen@setmail.co", initials: "SC", color: "#00E5FF" },
  { id: "c2", name: "Marcus Webb", suffix: "555 0198", email: "marcus.webb@setmail.co", initials: "MW", color: "#FFB000" },
  { id: "c3", name: "Elena Frost", suffix: "555 0177", email: "elena.frost@setmail.co", initials: "EF", color: "#FF3B30" },
  { id: "c4", name: "David Park", suffix: "555 0123", email: "david.park@setmail.co", initials: "DP", color: "#8A92A6" },
  { id: "c5", name: "Nora Vega", suffix: "555 0156", email: "nora.vega@setmail.co", initials: "NV", color: "#00FF00" },
  { id: "c6", name: "Sam Ryder", suffix: "555 0119", email: "sam.ryder@setmail.co", initials: "SR", color: "#FFB000" },
];

export const contactNumber = (dialCode, suffix) => `${dialCode} ${suffix}`.trim();

const AVATAR_COLORS = ["#00E5FF", "#FFB000", "#FF3B30", "#8A92A6", "#00FF00", "#5E5CE6", "#FF9F0A", "#34C759", "#FF2D55", "#0A84FF"];

export const initialsFor = (name) => {
  const words = (name || "").trim().split(/\s+/);
  if (words.length === 1) return words[0].slice(0, 2).toUpperCase();
  return words.slice(0, 2).map((w) => w[0]).join("").toUpperCase();
};

// stable pseudo-random 0..1 from a seed - numbers stay consistent across regenerations
const seeded = (n) => { const x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); };

// 100 localized default contacts - each number starts with one of the active
// dial codes (first 3 digits); the rest of the number is deterministically randomized
export const makeDefaultContacts = (codes = ["026", "034", "049"], lang = "en") =>
  makeNames(lang).map((name, i) => {
    const code = codes[Math.floor(seeded(i + 1) * codes.length)] ?? codes[0];
    const rest = String(Math.floor(seeded(i + 997) * 10000000)).padStart(7, "0");
    return {
      id: `d${i}`,
      name,
      suffix: rest,
      custom: false,
      number: `${code} ${rest.slice(0, 3)} ${rest.slice(3)}`,
      email: `user${String(i + 1).padStart(3, "0")}@setmail.co`,
      initials: initialsFor(name),
      color: AVATAR_COLORS[i % AVATAR_COLORS.length],
    };
  });

export const remapContacts = (contacts = [], dialCode) =>
  contacts.map((c) => (c.custom || !c.suffix ? c : { ...c, number: contactNumber(dialCode, c.suffix) }));

export const mockEmails = [
  { id: 1, from: "Production Desk", subject: "Call sheet - Day 14", preview: "We're moving to the warehouse unit for the night shoot. Call time 18:00.", time: "9:41 AM", unread: true, body: "Crew,\n\nWe're relocating to the warehouse unit for the night shoot tonight. Call time 18:00 sharp. Parking is on the east lot - do not block the loading bay.\n\nThe VFX team will be running the chroma inserts after midnight, so keep the prop phones on the control channel until wrap.\n\n- Production" },
  { id: 2, from: "VFX Supervisor", subject: "Tracking marks - approved", preview: "Crosshair and L-bar marks cleared for the insert shots.", time: "8:02 AM", unread: true, body: "Tracking marks are cleared for the insert shots. Crosshair and L-bar are good to go. Skip the dot grid for the close-ups - it reads on the lens." },
  { id: 3, from: "Script", subject: "Revised pages - Scene 47", preview: "The phone call beats have been trimmed. New sides in your inbox.", time: "Yesterday", unread: false, body: "Revised pages attached. The phone call beats in Scene 47 have been trimmed - we lose the second ring and the voicemail. New sides are in your inbox." },
  { id: 4, from: "Post", subject: "Playback reference uploaded", preview: "Reference clips for the prop screen inserts are ready.", time: "Yesterday", unread: false, body: "Reference clips for the prop screen inserts are ready to review. Link in the shared drive under /prop-screens/ref." },
  { id: 5, from: "Locations", subject: "Unit move confirmed", preview: "Company move at 16:30. Trucks roll at 16:00.", time: "Mon", unread: false, body: "Company move confirmed for 16:30. Trucks roll at 16:00. Everyone off the lot by 15:45." },
];

export const appList = [
  { id: "phone", label: "Phone", icon: "Phone", color: "#34C759" },
  { id: "messages", label: "Messages", icon: "MessageSquare", color: "#34C759" },
  { id: "email", label: "Mail", icon: "Mail", color: "#0A84FF" },
  { id: "clock", label: "Clock", icon: "Clock", color: "#FF9F0A" },
  { id: "contacts", label: "Contacts", icon: "Contact", color: "#8A92A6" },
];