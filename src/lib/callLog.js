import { base44 } from "@/api/base44Client";
import { getDeviceName } from "@/lib/deviceLink";

// Team-wide call history. Every call logged on any mock device is written to
// the shared CallLog entity, so the whole crew sees the same history. Reads
// are best-effort - the phone app falls back to its local recents offline.

export async function logTeamCall({ name, number, type, logged_at = Date.now() }) {
  if (!["incoming", "outgoing", "missed"].includes(type)) return;
  try {
    await base44.entities.CallLog.create({
      contact_name: name || "",
      contact_number: number || "",
      type,
      device_name: getDeviceName(),
      logged_at,
    });
  } catch {}
}

export async function listTeamCalls() {
  const records = await base44.entities.CallLog.list("-created_date", 200);
  return records
    .map((r) => ({
      id: r.id,
      name: r.contact_name || "",
      number: r.contact_number || "",
      type: r.type,
      device: r.device_name || "",
      at: Number(r.logged_at) || r.created_date,
    }))
    .sort((a, b) => b.at - a.at);
}