import React, { useEffect, useState } from "react";
import { Loader2, Phone, PhoneIncoming, PhoneMissed, PhoneOutgoing, RefreshCw } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { listTeamCalls } from "@/lib/callLog";
import { cn } from "@/lib/utils";
import { LANGUAGES } from "@/lib/osLanguages";

const TYPE_META = {
  missed: { Icon: PhoneMissed, color: "#FF3B30" },
  incoming: { Icon: PhoneIncoming, color: "#34C759" },
  outgoing: { Icon: PhoneOutgoing, color: "#8E8E93" },
};

const fmt = (at) => {
  const d = new Date(at);
  const time = d.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  return d.toDateString() === new Date().toDateString()
    ? `Today ${time}`
    : `${d.toLocaleDateString([], { month: "short", day: "numeric" })} ${time}`;
};

export default function CallHistoryScreen({ onCall, language = "en" }) {
  const [calls, setCalls] = useState(null);
  const [refreshing, setRefreshing] = useState(false);
  const t = LANGUAGES.find((l) => l.code === language)?.phone || LANGUAGES[0].phone;

  // load the shared team history, then keep it live as calls come in
  useEffect(() => {
    let alive = true;
    const load = () =>
      listTeamCalls()
        .then((h) => { if (alive) setCalls(h); })
        .catch(() => setCalls((cur) => cur ?? []));
    load();
    const unsub = base44.entities.CallLog.subscribe((e) => {
      if (e.type === "create" || e.type === "delete") load();
    });
    return () => { alive = false; unsub(); };
  }, []);

  const refresh = async () => {
    setRefreshing(true);
    try { setCalls(await listTeamCalls()); } catch {}
    setRefreshing(false);
  };

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      <div className="flex items-center justify-between px-4 py-2 border-b border-white/5">
        <div className="text-[11px] font-body text-white/40">
          Team history{calls ? ` · ${calls.length} call${calls.length === 1 ? "" : "s"}` : ""}
        </div>
        <button onClick={refresh} disabled={refreshing || !calls}
          className="flex items-center gap-1 text-xs font-body text-[#34C759] disabled:opacity-40">
          {refreshing ? <Loader2 size={13} className="animate-spin" /> : <RefreshCw size={13} />} Sync
        </button>
      </div>

      <div className="flex-1 overflow-auto no-scrollbar px-4">
        {calls === null ? (
          <div className="flex h-full items-center justify-center text-white/30">
            <Loader2 size={18} className="animate-spin" />
          </div>
        ) : calls.length === 0 ? (
          <div className="text-center text-white/30 py-10 text-sm">No team calls yet</div>
        ) : calls.map((c) => {
          const meta = TYPE_META[c.type] || TYPE_META.outgoing;
          const status = t[c.type] || c.type;
          return (
            <div key={c.id} className="flex items-center justify-between py-3 border-b border-white/5">
              <div className="min-w-0">
                <div className={cn("font-medium truncate", c.type === "missed" && "text-[#FF3B30]")}>
                  {c.name || c.number || "Unknown"}
                </div>
                <div className="flex items-center gap-1.5 text-xs text-white/40 font-body">
                  <meta.Icon size={12} style={{ color: meta.color }} className="shrink-0" />
                  <span className="truncate">{[status, fmt(c.at), c.device].filter(Boolean).join(" · ")}</span>
                </div>
              </div>
              <button onClick={() => onCall?.({ name: c.name, number: c.number })}
                className="text-[#34C759] shrink-0">
                <Phone size={18} />
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
}