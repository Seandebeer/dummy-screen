import { NOTIF_APPS } from "@/lib/osNotifications";
import { cn } from "@/lib/utils";

// notification cards stacked on the lock screen - tap to open
export default function LockNotifications({ notifications = [], light, onOpen }) {
  if (!notifications.length) return null;
  return (
    <div className={cn("relative w-full px-3 mt-5 space-y-2 max-h-[40%] overflow-y-auto no-scrollbar",
      light ? "text-black" : "text-white")}>
      {notifications.map((n) => {
        const meta = NOTIF_APPS[n.app] || NOTIF_APPS.messages;
        return (
          <button key={n.id} onClick={() => onOpen?.(n)}
            className={cn("w-full flex items-start gap-2.5 rounded-2xl px-3 py-2.5 text-left border shadow-lg backdrop-blur-md",
              light ? "bg-white/75 border-black/10" : "bg-white/15 border-white/20")}>
            <span className="h-9 w-9 rounded-lg flex items-center justify-center shrink-0" style={{ background: meta.bg }}>
              <meta.Icon size={18} className="text-white" />
            </span>
            <span className="flex-1 min-w-0">
              <span className="flex items-baseline justify-between gap-2">
                <span className="text-[13px] font-semibold truncate">{n.title}</span>
                <span className="text-[10px] font-body opacity-50 shrink-0">{n.time}</span>
              </span>
              <span className="block text-[12px] leading-snug line-clamp-3 break-words opacity-65">{n.body}</span>
            </span>
          </button>
        );
      })}
    </div>
  );
}