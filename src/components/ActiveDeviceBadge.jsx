import React, { useEffect, useState } from "react";
import { useLocation } from "react-router-dom";
import { DEVICE_EVENT, getLinkedDeviceId } from "@/lib/deviceLink";

const NAME_KEY = "takeover-device-name";

// pill showing which prop phone this screen is currently linked to -
// renders nothing until a device layout has been loaded (or QR-connected)
export default function ActiveDeviceBadge({ className }) {
  const location = useLocation();
  const [name, setName] = useState(null);

  useEffect(() => {
    const read = () => {
      try {
        setName(getLinkedDeviceId() ? (localStorage.getItem(NAME_KEY) || "") : "");
      } catch { setName(""); }
    };
    read();
    window.addEventListener(DEVICE_EVENT, read);
    return () => window.removeEventListener(DEVICE_EVENT, read);
  }, [location.pathname]);

  if (!name) return null;

  return (
    <span className={className || "inline-flex max-w-full items-center gap-1.5 rounded-full border border-amber/30 bg-amber/10 px-2.5 py-1 text-[9px] font-medium font-body text-amber"}>
      <span className="h-1 w-1 shrink-0 rounded-full bg-amber led-pulse" />
      <span className="truncate">{name}</span>
    </span>
  );
}