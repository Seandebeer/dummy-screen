import { X } from "lucide-react";
import { NOTIF_APPS } from "@/lib/osNotifications";
import { cn } from "@/lib/utils";

// drop-down notification banner shown over the home screen / open apps
export default function NotificationBanner({ notif, light, onOpen, onDismiss }) {
  if (!notif) return null;
  const meta = NOTIF_APPS[notif.app] || NOTIF_APPS.messages;
  return (
    <div className="absolute top-2 inset-x-2 z-30">
      <button onClick={() => onOpen?.(notif)}
        className={cn("w-full flex items-center gap-2.5 rounded-2xl px-3 py-2.5 text-left border shadow-xl backdrop-blur-md",
          light ? "bg-white/85 border-black/10" : "bg-[#2C2C2E]/90 border-white/15")}>
        <span className="h-9 w-9 rounded-lg flex items-center justify-center shrink-0" style={{ background: meta.bg }}>
          <meta.Icon size={18} className="text-white" />
        </span>
        <span className="flex-1 min-w-0">
          <span className={cn("flex items-baseline justify-between gap-2", light ? "text-black" : "text-white")}>
            <span className="text-[13px] font-semibold truncate">{notif.title}</span>
            <span className="text-[10px] font-body opacity-50 shrink-0">{notif.time}</span>
          </span>
          <span className={cn("block text-[12px] leading-snug line-clamp-2", light ? "text-black/60" : "text-white/60")}>{notif.body}</span>
        </span>
      </button>
      <button onClick={onDismiss} aria-label="Dismiss"
        className="absolute -top-1.5 -right-1.5 h-5 w-5 rounded-full bg-black/70 text-white flex items-center justify-center shadow-md">
        <X size={11} />
      </button>
    </div>
  );
}