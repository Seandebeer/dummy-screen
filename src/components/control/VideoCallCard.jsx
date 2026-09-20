import React, { useEffect, useRef, useState } from "react";
import { Film, Image as ImageIcon, Loader2, Mic, MicOff, Monitor, PhoneOff, Video, VideoOff } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { startControlVideo } from "@/lib/videoLink";
import { getScreenId } from "@/lib/deviceLink";
import { trackingMarks, vfxColors } from "@/lib/vfxData";
import { cn } from "@/lib/utils";
import ControlCard from "@/components/control/ControlCard";

// Remote-triggered mock video call: the operator starts a "video_call" command
// carrying the caller's content (live camera, VFX screen, uploaded video or
// photo), toggles their camera / mic, switches the far-end content mid-call
// and ends the call - the prop phone renders it live over the same channel.
const MODES = [
  { id: "live", label: "Live cam", Icon: Video },
  { id: "vfx", label: "VFX", Icon: Monitor },
  { id: "video", label: "Video", Icon: Film },
  { id: "photo", label: "Photo", Icon: ImageIcon },
];

export default function VideoCallCard({ contact, channel = "stage-1" }) {
  const [state, setState] = useState("idle"); // idle | ringing | active | ended
  const [cmdId, setCmdId] = useState(null);
  const [mode, setMode] = useState("live");
  const [camOn, setCamOn] = useState(true);
  const [micOn, setMicOn] = useState(true);
  const [photoUrl, setPhotoUrl] = useState("");
  const [videoUrl, setVideoUrl] = useState("");
  const [vfx, setVfx] = useState({ bgColor: "#00B140", markStyle: "cross" });
  const [photoMode, setPhotoMode] = useState(() => {
    try { return localStorage.getItem("takeover-video-photo-mode") || "circle"; } catch { return "circle"; }
  });
  const choosePhotoMode = (m) => {
    setPhotoMode(m);
    try { localStorage.setItem("takeover-video-photo-mode", m); } catch {}
  };
  const [live, setLive] = useState("off"); // off | on | denied | error
  const [uploading, setUploading] = useState(false);
  const [busy, setBusy] = useState(false);
  const linkRef = useRef(null);
  const fileRef = useRef(null);
  const payloadRef = useRef({});

  const push = async (patch) => {
    payloadRef.current = { ...payloadRef.current, ...patch };
    if (!cmdId) return;
    try {
      await base44.entities.Command.update(cmdId, { payload: JSON.stringify(payloadRef.current) });
    } catch {}
  };

  const finish = () => {
    linkRef.current?.stop();
    linkRef.current = null;
    setLive("off");
    setCmdId(null);
    payloadRef.current = {};
    setState("ended");
    setTimeout(() => setState((s) => (s === "ended" ? "idle" : s)), 1500);
  };

  // mirror the phone's call state (it marks the command active / completed)
  useEffect(() => {
    if (!cmdId) return undefined;
    const unsub = base44.entities.Command.subscribe((e) => {
      if (e.data?.id !== cmdId) return;
      if (e.type === "update" && e.data.status === "active") setState("active");
      if (e.type === "update" && e.data.status === "completed") finish();
    });
    return () => unsub();
  }, [cmdId]);

  const start = async () => {
    if (busy || state !== "idle" || !contact.name.trim()) return;
    setBusy(true);
    const payload = { mode, photoUrl, videoUrl, vfx, camOff: !camOn, photoMode, source: getScreenId() };
    payloadRef.current = payload;
    try {
      const rec = await base44.entities.Command.create({
        channel, type: "video_call",
        contact_name: contact.name.trim(),
        contact_number: contact.number.trim(),
        ...(contact.image ? { contact_image: contact.image } : {}),
        payload: JSON.stringify(payload), status: "pending",
      });
      setCmdId(rec.id);
      setState("ringing");
      if (mode === "live") linkRef.current = startControlVideo(rec.id, setLive, channel, { micOn });
    } catch {}
    setBusy(false);
  };

  const end = async () => {
    const id = cmdId;
    if (id) { try { await base44.entities.Command.update(id, { status: "completed" }); } catch {} }
    finish();
  };

  const switchMode = (m) => {
    setMode(m);
    push({ mode: m });
    if (m === "live" && cmdId && !linkRef.current) linkRef.current = startControlVideo(cmdId, setLive, channel, { micOn });
  };

  const toggleCam = () => {
    const v = !camOn;
    setCamOn(v);
    linkRef.current?.setCamOn(v);
    push({ camOff: !v });
  };
  // trigger-side only: the mic toggle gates your own audio on the live
  // link - nothing changes on the prop phone
  const toggleMic = () => {
    const v = !micOn;
    setMicOn(v);
    linkRef.current?.setMicOn(v);
  };

  const upload = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setUploading(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
      if (file.type.startsWith("video")) { setVideoUrl(file_url); push({ videoUrl: file_url }); }
      else { setPhotoUrl(file_url); push({ photoUrl: file_url }); }
    } catch {}
    setUploading(false);
  };

  const active = state === "ringing" || state === "active";
  const setVfxPatch = (patch) => {
    const v = { ...vfx, ...patch };
    setVfx(v);
    push({ vfx: v });
  };

  const toggle = (on, onClick, onIcon, offIcon, label) => (
    <button onClick={onClick}
      className={cn("flex items-center gap-1.5 rounded-lg border px-2.5 py-1.5 text-[10px] font-body transition",
        on ? "border-signal/40 bg-signal/10 text-signal" : "border-white/[0.08] text-muted-foreground")}>
      {on ? onIcon : offIcon} {label}
    </button>
  );

  return (
    <ControlCard icon={Video} title="Video Call Trigger"
      badge={
        <span className={cn("text-[11px] font-body font-semibold uppercase",
          state === "active" && "text-signal",
          state === "ringing" && "text-amber amber-pulse",
          state === "ended" && "text-alert",
          state === "idle" && "text-muted-foreground")}>
          {state}
        </span>
      }>

      {/* what the actor's screen shows as the far end */}
      <div className="mb-2 grid grid-cols-4 gap-1.5">
        {MODES.map((m) => (
          <button key={m.id} onClick={() => switchMode(m.id)}
            className={cn("flex flex-col items-center gap-1 rounded-xl border py-2.5 text-[10px] font-body transition",
              mode === m.id ? "border-signal/50 bg-signal/10 text-signal" : "border-white/[0.08] text-muted-foreground hover:text-foreground")}>
            <m.Icon size={16} /> {m.label}
          </button>
        ))}
      </div>

      {mode === "live" && (
        <div className="mb-2 flex flex-wrap items-center gap-2">
          {toggle(camOn, toggleCam, <Video size={13} />, <VideoOff size={13} />, "Camera")}
          {toggle(micOn, toggleMic, <Mic size={13} />, <MicOff size={13} />, "Mic")}
          <span className={cn("text-[10px] font-body", live === "on" ? "text-signal" : "text-muted-foreground")}>
            {live === "on" ? "Live camera streaming"
              : live === "denied" ? "Camera blocked - pick another mode"
              : live === "error" ? "Live link failed"
              : "Toggles control your live feed only"}
          </span>
        </div>
      )}

      {mode === "vfx" && (
        <div className="mb-2 flex flex-wrap items-center gap-2">
          {vfxColors.map((c) => (
            <button key={c.id} onClick={() => setVfxPatch({ bgColor: c.hex })} title={c.label}
              className={cn("h-6 w-6 rounded-full border border-white/[0.08]",
                vfx.bgColor === c.hex && "ring-1 ring-signal ring-offset-1 ring-offset-surface")}
              style={{ background: c.hex }} />
          ))}
          <label title="Custom colour" className="cursor-pointer">
            <input type="color" value={vfx.bgColor} onChange={(e) => setVfxPatch({ bgColor: e.target.value })}
              className="h-6 w-6 cursor-pointer rounded-full border border-white/[0.08] bg-transparent p-0" />
          </label>
          <select value={vfx.markStyle} onChange={(e) => setVfxPatch({ markStyle: e.target.value })}
            className="rounded-lg border border-white/[0.08] bg-white/[0.04] px-2 py-1.5 text-[10px] font-body text-foreground outline-none">
            {trackingMarks.map((m) => <option key={m.id} value={m.id}>{m.name}</option>)}
          </select>
        </div>
      )}

      {(mode === "video" || mode === "photo") && (
        <button onClick={() => fileRef.current?.click()} disabled={uploading}
          className="mb-2 flex w-full items-center justify-center gap-2 rounded-lg border border-white/[0.08] py-2 text-[11px] font-body text-muted-foreground transition hover:text-foreground disabled:opacity-50">
          {uploading ? <Loader2 size={13} className="animate-spin" /> : (
            <>
              {mode === "video" ? <Film size={13} /> : <ImageIcon size={13} />}
              {mode === "video" ? (videoUrl ? "Replace video clip" : "Upload video clip") : (photoUrl ? "Replace photo" : "Upload photo")}
            </>
          )}
        </button>
      )}
      <input ref={fileRef} type="file" accept="image/*,video/*" className="hidden" onChange={upload} />

      {/* how the caller's photo greets the actor before answering */}
      <div className="mb-2 flex items-center justify-between">
        <span className="text-[10px] font-body text-muted-foreground">Caller photo before answering</span>
        <div className="flex gap-1">
          {["circle", "full"].map((m) => (
            <button key={m} onClick={() => choosePhotoMode(m)}
              className={cn("rounded-lg border px-2 py-1 text-[10px] font-body transition",
                photoMode === m ? "border-signal/50 bg-signal/10 text-signal" : "border-white/[0.08] text-muted-foreground")}>
              {m === "circle" ? "Circle" : "Full screen"}
            </button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-2 gap-2">
        <button onClick={start} disabled={state !== "idle" || busy || !contact.name.trim()}
          className="flex flex-col items-center gap-1.5 rounded-2xl border border-signal/30 bg-signal/10 py-3.5 text-signal disabled:opacity-40 hover:bg-signal/20 transition">
          <Video size={20} />
          <span className="text-[11px] font-body">Video Call</span>
        </button>
        <button onClick={end} disabled={!active}
          className="flex flex-col items-center gap-1.5 rounded-2xl border border-alert/30 bg-alert/10 py-3.5 text-alert disabled:opacity-40 hover:bg-alert/20 transition">
          <PhoneOff size={20} />
          <span className="text-[11px] font-body">End</span>
        </button>
      </div>
      <div className="mt-2 text-[10px] font-body text-muted-foreground">
        {contact.name.trim()
          ? `Calls ${contact.name.trim()} on the prop phone - the phone can also start it from FaceTime`
          : "Set an on-screen contact name above to enable video calls"}
      </div>
    </ControlCard>
  );
}