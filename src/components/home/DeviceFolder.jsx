import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Trash2, Crosshair, Monitor } from "lucide-react";
import { listSaved, deleteConfig } from "@/lib/savedConfigs";
import { SYNC_EVENT } from "@/lib/cloudSync";
import { openSavedEntry } from "@/lib/openSaved";
import ConfirmDeleteDialog from "@/components/home/ConfirmDeleteDialog";

// DeviceFolder - the screens and UI marker layouts saved while this device
// was the active one (chosen at save time)
export default function DeviceFolder({ device }) {
  const [items, setItems] = useState(listSaved);
  const [confirmDel, setConfirmDel] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    const onSync = () => setItems(listSaved());
    window.addEventListener(SYNC_EVENT, onSync);
    return () => window.removeEventListener(SYNC_EVENT, onSync);
  }, []);

  const mine = items.filter((s) => s.device_id === device.id && (s.kind === "screen" || s.kind === "markers"));

  return (
    <div>
      {mine.length === 0 ? (
        <p className="py-2 text-center text-[11px] font-body text-muted-foreground">
          Nothing saved to {device.name} yet - screens and marker layouts saved to this device appear here.
        </p>
      ) : (
        <div className="flex flex-col gap-1.5">
          {mine.map((s) => (
            <div key={s.id} className="flex items-center gap-2.5 rounded-lg bg-muted/20 px-2.5 py-2">
              <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-muted/60 text-muted-foreground">
                {s.kind === "markers" ? <Crosshair size={13} /> : <Monitor size={13} />}
              </span>
              <button onClick={() => openSavedEntry(s, navigate)}
                className="min-w-0 flex-1 text-left transition hover:opacity-80">
                <div className="truncate text-[13px] font-body">{s.name}</div>
                <div className="text-[9px] uppercase tracking-wider text-muted-foreground font-body">
                  {s.kind === "markers" ? "UI markers" : "Screen"}
                </div>
              </button>
              <button onClick={() => setConfirmDel(s)} title="Delete"
                className="text-muted-foreground transition hover:text-alert">
                <Trash2 size={13} />
              </button>
            </div>
          ))}
        </div>
      )}
      <ConfirmDeleteDialog
        open={Boolean(confirmDel)}
        onOpenChange={(o) => !o && setConfirmDel(null)}
        name={confirmDel?.name}
        onConfirm={() => { deleteConfig(confirmDel.id); setItems(listSaved()); setConfirmDel(null); }}
      />
    </div>
  );
}