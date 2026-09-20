import { Phone, MessageSquare, Mail } from "lucide-react";
import { allApps } from "@/lib/osApps";

// app metadata shared by notification cards & banners - every app in the
// library is a valid notification icon, on its own tile colour
export const NOTIF_APPS = {
  messages: { Icon: MessageSquare, bg: "#34C759" },
  mail: { Icon: Mail, bg: "#0A84FF" },
  phone: { Icon: Phone, bg: "#34C759" },
  ...Object.fromEntries(
    allApps.filter((a) => a.Icon).map((a) => [a.id, { Icon: a.Icon, bg: a.bg || "#5E5CE6" }])
  ),
};

export const MAX_BADGE = 1000000;

export function normalizeBadge(raw) {
  const n = Math.round(Number(String(raw ?? "").replace(/[^\d]/g, "")) || 0);
  return Math.max(0, Math.min(MAX_BADGE, n));
}

export function formatBadge(n) {
  const v = Number(n) || 0;
  if (v <= 0) return "";
  if (v <= 999) return String(v);
  if (v <= 9999) return `${(v / 1000).toFixed(1).replace(/\.0$/, "")}K`;
  if (v <= 999499) return `${Math.round(v / 1000)}K`;
  return "1M+";
}