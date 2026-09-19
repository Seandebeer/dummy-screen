export const DIAL_CODES = ["082", "083", "084"];

export const mockContacts = [
  { id: "c1", name: "Sarah Chen", suffix: "555 0142", email: "sarah.chen@setmail.co", initials: "SC", color: "#00E5FF" },
  { id: "c2", name: "Marcus Webb", suffix: "555 0198", email: "marcus.webb@setmail.co", initials: "MW", color: "#FFB000" },
  { id: "c3", name: "Elena Frost", suffix: "555 0177", email: "elena.frost@setmail.co", initials: "EF", color: "#FF3B30" },
  { id: "c4", name: "David Park", suffix: "555 0123", email: "david.park@setmail.co", initials: "DP", color: "#8A92A6" },
  { id: "c5", name: "Nora Vega", suffix: "555 0156", email: "nora.vega@setmail.co", initials: "NV", color: "#00FF00" },
  { id: "c6", name: "Sam Ryder", suffix: "555 0119", email: "sam.ryder@setmail.co", initials: "SR", color: "#FFB000" },
];

export const contactNumber = (dialCode, suffix) => `${dialCode} ${suffix}`.trim();

export const makeDefaultContacts = (dialCode = "082") =>
  mockContacts.map((c) => ({ ...c, custom: false, number: contactNumber(dialCode, c.suffix) }));

export const remapContacts = (contacts = [], dialCode) =>
  contacts.map((c) => (c.custom || !c.suffix ? c : { ...c, number: contactNumber(dialCode, c.suffix) }));

export const mockEmails = [
  { id: 1, from: "Production Desk", subject: "Call sheet — Day 14", preview: "We're moving to the warehouse unit for the night shoot. Call time 18:00.", time: "9:41 AM", unread: true, body: "Crew,\n\nWe're relocating to the warehouse unit for the night shoot tonight. Call time 18:00 sharp. Parking is on the east lot — do not block the loading bay.\n\nThe VFX team will be running the chroma inserts after midnight, so keep the prop phones on the control channel until wrap.\n\n— Production" },
  { id: 2, from: "VFX Supervisor", subject: "Tracking marks — approved", preview: "Crosshair and L-bar marks cleared for the insert shots.", time: "8:02 AM", unread: true, body: "Tracking marks are cleared for the insert shots. Crosshair and L-bar are good to go. Skip the dot grid for the close-ups — it reads on the lens." },
  { id: 3, from: "Script", subject: "Revised pages — Scene 47", preview: "The phone call beats have been trimmed. New sides in your inbox.", time: "Yesterday", unread: false, body: "Revised pages attached. The phone call beats in Scene 47 have been trimmed — we lose the second ring and the voicemail. New sides are in your inbox." },
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