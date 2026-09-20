import React, { useEffect, useRef, useState } from "react";
import { Loader2, Mic, MicOff, Monitor, Phone, PhoneOff, RefreshCw, SlidersHorizontal, Upload, Video as VideoIcon, VideoOff } from "lucide-react";
import { base44 } from "@/api/base44Client";
import VfxCallControls from "@/components/os/apps/videocall/VfxCallControls";
import { TrackingMarks } from "@/components/vfx/TrackingMarks";
import { defaultLayoutFor } from "@/hooks/useScreenMarks";
import { cn } from "@/lib/utils";

// the caller screen defaults to a chroma green cross-mark layout, ready for
// screen replacement
export const DEFAULT_CALL_VFX = { bgColor: "#00B140", markStyle: "cross", markColor: null, markSize: 1.1, markThick: 0.6, markRot: 0 };

const isLightHex = (hex) => {
  const m = /^#?([0-9a-f]{6})$/i.exec(hex || "");
  if (!m) return false;
  const n = parseInt(m[1], 16);
  return ((n >> 16) & 255) * 0.299 + ((n >> 8) & 255) * 0.587 + (n & 255) * 0.114 > 150;
};

export default function VideoCallApp({ config, update }) {
  const vc = { source: "vfx", videoUrl: "", ...(config.videocall || {}) };
  const vfx = { ...DEFAULT_CALL_VFX, ...(vc.vfx || {}) };

  const [secs, setSecs] = useState(0);
  const [muted, setMuted] = useState(false);
  const [facing, setFacing] = useState("user");
  const [ended, setEnded] = useState(false);
  const [controlsOpen, setControlsOpen] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [camError, setCamError] = useState(false);
  const pipRef = useRef(null);
  const streamRef = useRef(null);
  const fileRef = useRef(null);

  // call duration
  useEffect(() => {
    if (ended) return undefined;
    const t = setInterval(() => setSecs((s) => s + 1), 1000);
    return () => clearInterval(t);
  }, [ended]);

  // own-camera picture-in-picture - the "person calling" viewpoint
  useEffect(() => {
    let alive = true;
    setCamError(false);
    navigator.mediaDevices?.getUserMedia({ video: { facingMode: facing }, audio: false })
      .then((stream) => {
        if (!alive) { stream.getTracks().forEach((tr) => tr.stop()); return; }
        streamRef.current = stream;
        if (pipRef.current) pipRef.current.srcObject = stream;
      })
      .catch(() => { if (alive) setCamError(true); });
    return () => {
      alive = false;
      streamRef.current?.getTracks().forEach((tr) => tr.stop());
      streamRef.current = null;
    };
  }, [facing]);

  const save = (patch) => update((c) => ({
    videocall: {
      ...{ source: "vfx", videoUrl: "" }, ...(c.videocall || {}),
      ...(typeof patch === "function" ? patch(c.videocall || {}) : patch),
    },
  }));
  const saveVfx = (p) => save((v) => ({ vfx: { ...DEFAULT_CALL_VFX, ...(v.vfx || {}), ...p } }));

  const uploadVideo = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setUploading(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
      save({ videoUrl: file_url, source: "video" });
    } catch {}
    setUploading(false);
  };

  const time = `${Math.floor(secs / 60)}:${String(secs % 60).padStart(2, "0")}`;
  const markColor = vfx.markColor || (isLightHex(vfx.bgColor) ? "#000000" : "#FFFFFF");
  const markLayout = defaultLayoutFor(vfx.markStyle);
  const caller = config.contacts?.[0]?.name || "Jordan Reyes";
  const btn = "flex h-11 w-11 items-center justify-center rounded-full bg-black/50 backdrop-blur transition active:scale-95";

  return (
    <div className="relative h-full select-none overflow-hidden bg-black text-white">
      {/* the other end - uploaded video or a chroma screen with tracking marks */}
      {vc.source === "video" ? (
        vc.videoUrl ? (
          <video key={vc.videoUrl} src={vc.videoUrl} autoPlay loop playsInline muted
            className="absolute inset-0 h-full w-full object-cover" />
        ) : (
          <div className="absolute inset-0 flex flex-col items-center justify-center gap-3 px-8 text-center">
            <VideoIcon size={26} className="text-white/30" />
            <div className="text-sm font-body text-white/70">No video for the other end yet</div>
            <button onClick={() => fileRef.current?.click()} disabled={uploading}
              className="flex items-center gap-2 rounded-full bg-white/10 px-4 py-2 text-[12px] font-body transition hover:bg-white/20 disabled:opacity-50">
              {uploading ? <Loader2 size={14} className="animate-spin" /> : <Upload size={14} />}
              {uploading ? "Uploading…" : "Upload a video"}
            </button>
          </div>
        )
      ) : (
        <div className="absolute inset-0" style={{ background: vfx.bgColor }}>
          <TrackingMarks type={vfx.markStyle} color={markColor} opacity={0.9}
            size={vfx.markSize} thickness={vfx.markThick}
            markers={vfx.markRot
              ? markLayout.map((m) => ({ ...m, rot: (m.rot || 0) + vfx.markRot }))
              : markLayout} />
        </div>
      )}
      <input ref={fileRef} type="file" accept="video/*" className="hidden" onChange={uploadVideo} />

      {/* header - caller + live duration */}
      <div className="absolute left-3 top-3 z-10 flex flex-col gap-1">
        <span className="text-[13px] font-display font-semibold drop-shadow">{caller}</span>
        <span className="flex items-center gap-1 text-[10px] font-body text-white/60">
          <span className="h-1.5 w-1.5 rounded-full bg-[#34C759]" /> {time}
        </span>
      </div>

      {/* own camera, picture in picture */}
      <div className="absolute right-3 top-3 z-10 aspect-[3/4] w-[30%] overflow-hidden rounded-xl border border-white/25 bg-black/70 shadow-lg">
        {camError ? (
          <div className="flex h-full w-full flex-col items-center justify-center gap-1 text-center">
            <VideoOff size={16} className="text-white/40" />
            <span className="px-1 text-[8px] font-body text-white/40">Camera unavailable</span>
          </div>
        ) : (
          <video ref={pipRef} autoPlay playsInline muted
            className={cn("h-full w-full object-cover", facing === "user" && "scale-x-[-1]")} />
        )}
      </div>

      {/* control bar */}
      <div className="absolute bottom-4 left-1/2 z-10 flex -translate-x-1/2 items-center gap-2">
        <button onClick={() => setMuted((m) => !m)} title={muted ? "Unmute" : "Mute"}
          className={cn(btn, muted && "bg-[#FF453A]")}>
          {muted ? <MicOff size={17} /> : <Mic size={17} />}
        </button>
        <button onClick={() => save({ source: "vfx" })} title="VFX screen"
          className={cn("flex h-11 items-center gap-1.5 rounded-full px-3.5 text-[10px] font-body backdrop-blur transition active:scale-95",
            vc.source === "vfx" ? "bg-[#0A84FF]" : "bg-black/50 text-white/80")}>
          <Monitor size={15} /> VFX
        </button>
        <button onClick={() => save({ source: "video" })} title="Uploaded video"
          className={cn("flex h-11 items-center gap-1.5 rounded-full px-3.5 text-[10px] font-body backdrop-blur transition active:scale-95",
            vc.source === "video" ? "bg-[#0A84FF]" : "bg-black/50 text-white/80")}>
          <VideoIcon size={15} /> Video
        </button>
        {vc.source === "vfx" ? (
          <button onClick={() => setControlsOpen(true)} title="Screen options"
            className={btn}><SlidersHorizontal size={17} /></button>
        ) : (
          <button onClick={() => fileRef.current?.click()} disabled={uploading} title="Replace video"
            className={cn(btn, "disabled:opacity-50")}>
            {uploading ? <Loader2 size={17} className="animate-spin" /> : <Upload size={17} />}
          </button>
        )}
        <button onClick={() => setFacing((f) => (f === "user" ? "environment" : "user"))}
          title="Flip camera" className={btn}><RefreshCw size={17} /></button>
        <button onClick={() => setEnded(true)} title="End call"
          className={cn(btn, "bg-[#FF453A]")}><PhoneOff size={17} /></button>
      </div>

      {/* call ended overlay */}
      {ended && (
        <div className="absolute inset-0 z-30 flex flex-col items-center justify-center gap-2 bg-black/90">
          <span className="text-[15px] font-display font-semibold">Call ended</span>
          <span className="text-[11px] font-body text-white/50">Duration {time}</span>
          <button onClick={() => { setEnded(false); setSecs(0); }} title="Call again"
            className="mt-3 flex h-14 w-14 items-center justify-center rounded-full bg-[#34C759] transition active:scale-95">
            <Phone size={22} />
          </button>
        </div>
      )}

      {/* VFX screen options */}
      {controlsOpen && vc.source === "vfx" && (
        <VfxCallControls vfx={vfx} onChange={saveVfx} onClose={() => setControlsOpen(false)} />
      )}
    </div>
  );
}