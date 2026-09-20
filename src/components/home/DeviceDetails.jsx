import React, { useRef, useState } from "react";
import { ImageUp, Loader2, Trash2 } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { Image } from "@/components/ui/image";

const FIELD = "flex-1 min-w-0 rounded-lg bg-muted/40 border border-border px-2.5 py-1.5 text-xs font-body outline-none focus:border-signal/50";

// physical prop details for a device - the actual phone's make, model, colour,
// serial number and a photo, stored with the device record for the whole team.
export default function DeviceDetails({ device, onChange }) {
  const [make, setMake] = useState(device.make || "");
  const [model, setModel] = useState(device.model || "");
  const [colour, setColour] = useState(device.colour || "");
  const [serial, setSerial] = useState(device.serial || "");
  const [photo, setPhoto] = useState(device.photo || "");
  const [busy, setBusy] = useState(false);
  const [uploading, setUploading] = useState(false);
  const fileRef = useRef(null);

  const save = async () => {
    setBusy(true);
    try {
      await base44.entities.Device.update(device.id, { make, model, colour, serial, photo });
      onChange();
    } finally {
      setBusy(false);
    }
  };

  const onFile = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setUploading(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
      setPhoto(file_url);
    } catch {}
    setUploading(false);
  };

  return (
    <div className="flex flex-col gap-2.5">
      <div className="grid grid-cols-2 gap-2">
        <input value={make} onChange={(e) => setMake(e.target.value)} placeholder="Make (e.g. Apple)" className={FIELD} />
        <input value={model} onChange={(e) => setModel(e.target.value)} placeholder="Model (e.g. iPhone 14)" className={FIELD} />
        <input value={colour} onChange={(e) => setColour(e.target.value)} placeholder="Colour" className={FIELD} />
        <input value={serial} onChange={(e) => setSerial(e.target.value)} placeholder="Serial number" className={FIELD} />
      </div>

      <div className="flex items-center gap-2">
        <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={onFile} />
        <button onClick={() => fileRef.current?.click()} disabled={uploading}
          className="flex items-center gap-1.5 rounded-lg bg-muted/40 border border-border px-2.5 py-1.5 text-[11px] font-body text-foreground/80 disabled:opacity-50">
          {uploading ? <Loader2 size={13} className="animate-spin" /> : <ImageUp size={13} />}
          {photo ? "Replace photo" : "Upload photo"}
        </button>
        {photo && (
          <>
            <Image src={photo} alt="Device" className="h-12 w-12 rounded-lg shrink-0" />
            <button onClick={() => setPhoto("")} title="Remove photo"
              className="text-muted-foreground hover:text-alert transition">
              <Trash2 size={13} />
            </button>
          </>
        )}
      </div>

      <button onClick={save} disabled={busy}
        className="self-start flex items-center gap-1.5 rounded-lg bg-signal text-background px-3 py-1.5 text-xs font-display font-semibold disabled:opacity-40">
        {busy ? <Loader2 size={13} className="animate-spin" /> : null} Save details
      </button>
    </div>
  );
}