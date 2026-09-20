import React, { useEffect, useState } from "react";
import { Check, CloudOff, Loader2 } from "lucide-react";
import { cn } from "@/lib/utils";
import { syncStatus, SYNC_EVENT } from "@/lib/cloudSync";

// tiny sync indicator for the saved library: synced with the team,
// syncing in the background, or working offline from the local copy
export default function SyncBadge() {
  const [status, setStatus] = useState(syncStatus);

  useEffect(() => {
    const update = () => setStatus(syncStatus());
    window.addEventListener(SYNC_EVENT, update);
    window.addEventListener("online", update);
    window.addEventListener("offline", update);
    return () => {
      window.removeEventListener(SYNC_EVENT, update);
      window.removeEventListener("online", update);
      window.removeEventListener("offline", update);
    };
  }, []);

  const map = {
    offline: { icon: <CloudOff size={11} />, label: "Offline · saved locally", cls: "text-amber/90" },
    queued: { icon: <Loader2 size={11} className="animate-spin" />, label: "Syncing…", cls: "text-muted-foreground" },
    synced: { icon: <Check size={11} />, label: "Synced with team", cls: "text-signal" },
  };
  const s = map[status] || map.synced;

  return (
    <span className={cn("flex items-center gap-1 text-[9px] uppercase tracking-wider font-body", s.cls)}>
      {s.icon} {s.label}
    </span>
  );
}