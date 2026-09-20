import React, { useEffect, useRef, useState } from "react";
import { Loader2, Lock, Mic, MicOff, Monitor, PhoneOff, RefreshCw, SlidersHorizontal, Upload, Video as VideoIcon } from "lucide-react";
import { base44 } from "@/api/base44Client";
import PipView from "@/components/os/apps/videocall/PipView";
import VfxCallControls from "@/components/os/apps/videocall/VfxCallControls";
import { TrackingMarks } from "@/components/vfx/TrackingMarks";
import ThreeFingerHint from "@/components/os/ThreeFingerHint";
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

  const [inCall, setInCall] = useState(false);
  const [secs, setSecs] = useState(0);
  const [muted, setMuted] = useState(false);
  const [facing, setFacing] = useState("user");
  const [ended, setEnded] = useState(false);
  const [controlsOpen, setControlsOpen] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [camError, setCamError] = useState(false);
  const [locked, setLocked] = useState(false);
  const [controlsVisible, setControlsVisible] = useState(true);
  const [hint, setHint] = useState(false);
  const pipVideoRef = useRef(null);
  const streamRef = useRef(null);
  const fileRef = useRef(null);
  const rootRef = useRef(null);

  // own-camera picture-in-picture - the "person calling" viewpoint
  useEffect(() => {
    let alive = true;
    setCamError(false);
    navigator.mediaDevices?.getUserMedia({ video: { facingMode: facing }, audio: false })
      .then((stream) => {
        if (!alive) { stream.getTracks().forEach((tr) => tr.stop()); return; }
        streamRef.current = stream;
        if (pipVideoRef.current) pipVideoRef.current.srcObject = stream;
      })
      .catch(() => { if (alive) setCamError(true); });
    return () => {
      alive = false;
      streamRef.current?.getTracks().forEach((tr) => tr.stop());
      streamRef.current = null;
    };
  }, [facing]);

  // call duration
  useEffect(() => {
    if (!inCall || ended) return undefined;
    const t = setInterval(() => setSecs((s) => s + 1), 1000);
    return () => clearInterval(t);
  }, [inCall, ended]);

  // FaceTime style: the controls fade away on their own after a few seconds
  useEffect(() => {
    if (!inCall || ended || locked || !controlsVisible || controlsOpen) return undefined;
    const t = setTimeout(() => setControlsVisible(false), 4000);
    return () => clearTimeout(t);
  }, [inCall, ended, locked, controlsVisible, controlsOpen]);

  // 3-finger tap unlocks a locked call screen
  useEffect(() => {
    if (!locked) return undefined;
    const onTouch = (e) => {
      if (e.touches.length >= 3) {
        setLocked(false);
        setControlsVisible(true);
      }
    };
    window.addEventListener("touchstart", onTouch, { passive: true });
    return () => window.removeEventListener("touchstart", onTouch);
  }, [locked]);

  const startCall = () => {
    setEnded(false);
    setSecs(0);
    setInCall(true);
    setLocked(false);
    setControlsVisible(true);
  };
  const endCall = () => {
    setEnded(true);
    setLocked(false);
    setControlsVisible(false);
  };
  const lock = () => {
    setLocked(true);
    setControlsVisible(false);
    setHint(true);
    setTimeout(() => setHint(false), 2400);
  };

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
  const showUi = controlsVisible && !locked && !ended;
  const light = vc.source === "vfx" ? isLightHex(vfx.bgColor) : false;

  const tapScreen = () => {
    if (!inCall || ended || locked || controlsOpen) return;
    setControlsVisible((v) => !v);
  };

  const ctl = "flex h-10 w-10 items-center justify-center rounded-full text-white/90 transition active:scale-90";
  const pill = (active) => cn(
    "flex h-9 items-center gap-1.5 rounded-full px-3 text-[10px] font-body transition active:scale-95",
    active ? "bg-[#0A84FF]" : "text-white/80 hover:text-white");

  const sourceButtons = (
    <>
      <button onClick={() => save({ source: "vfx" })} className={pill(vc.source === "vfx")}>
        <Monitor size={15} /> VFX
      </button>
      <button onClick={() => save({ source: "video" })} className={pill(vc.source === "video")}>
        <VideoIcon size={15} /> Video
      </button>
    </>
  );
  const tuneButton = vc.source === "vfx" ? (
    <button onClick={() => setControlsOpen(true)} title="Screen options" className={ctl}>
      <SlidersHorizontal size={18} />
    </button>
  ) : (
    <button onClick={() => fileRef.current?.click()} disabled={uploading} title="Replace video"
      className={cn(ctl, "disabled:opacity-50")}>
      {uploading ? <Loader2 size={18} className="animate-spin" /> : <Upload size={18} />}
    </button>
  );

  return (
    <div ref={rootRef} className="relative h-full select-none overflow-hidden bg-black text-white">
      {/* the other end - uploaded video or a chroma screen with tracking marks */}
      <div className="absolute inset-0" onClick={tapScreen}>
        {vc.source === "video" ? (
          vc.videoUrl ? (
            <video key={vc.videoUrl} src={vc.videoUrl} autoPlay loop playsInline muted
              className="absolute inset-0 h-full w-full object-cover" />
          ) : (
            <div className="absolute inset-0 flex flex-col items-center justify-center gap-3 bg-[#111] px-8 text-center">
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
      </div>
      <input ref={fileRef} type="file" accept="video/*" className="hidden" onChange={uploadVideo} />

      {/* setup hint */}
      {!inCall && !ended && (
        <div className="absolute left-0 right-0 top-3 z-10 text-center text-[10px] font-body text-white/60 drop-shadow pointer-events-none">
          Set up the caller screen, then start the call
        </div>
      )}

      {/* FaceTime style header - caller + duration, only while the controls are on */}
      {inCall && showUi && (
        <div className="absolute left-0 right-0 top-3 z-10 flex flex-col items-center gap-0.5 pointer-events-none">
          <span className="text-[13px] font-display font-semibold drop-shadow">{caller}</span>
          <span className="text-[10px] font-body text-white/70 drop-shadow">{time}</span>
        </div>
      )}

      {/* own camera, draggable picture in picture */}
      <PipView containerRef={rootRef} videoRef={pipVideoRef} camError={camError} facing={facing}
        onTap={inCall && !ended ? tapScreen : undefined} />

      {/* control bar - always on while setting up; in-call it hides itself */}
      {!ended && (showUi || !inCall) && (
        <div className="absolute bottom-4 left-1/2 z-10 flex -translate-x-1/2 items-center gap-4 rounded-[2rem] bg-black/45 px-4 py-2.5 backdrop-blur-md">
          {sourceButtons}
          {tuneButton}
          {!inCall ? (
            <>
              <button onClick={() => setFacing((f) => (f === "user" ? "environment" : "user"))}
                title="Flip camera" className={ctl}><RefreshCw size={18} /></button>
              <button onClick={startCall} title="Start call"
                className={cn(ctl, "bg-[#34C759]")}><VideoIcon size={18} /></button>
            </>
          ) : (
            <>
              <button onClick={() => setMuted((m) => !m)} title={muted ? "Unmute" : "Mute"}
                className={cn(ctl, muted && "bg-white text-black")}>
                {muted ? <MicOff size={18} /> : <Mic size={18} />}
              </button>
              <button onClick={() => setFacing((f) => (f === "user" ? "environment" : "user"))}
                title="Flip camera" className={ctl}><RefreshCw size={18} /></button>
              <button onClick={lock} title="Lock screen" className={ctl}><Lock size={18} /></button>
              <button onClick={endCall} title="End call"
                className={cn(ctl, "bg-[#FF453A]")}><PhoneOff size={18} /></button>
            </>
          )}
        </div>
      )}

      {/* call ended overlay */}
      {ended && (
        <div className="absolute inset-0 z-30 flex flex-col items-center justify-center gap-2.5 bg-black/85">
          <span className="text-[15px] font-display font-semibold">Call ended</span>
          <span className="text-[11px] font-body text-white/50">Duration {time}</span>
          <button onClick={startCall} title="Call again"
            className="mt-2 flex h-16 w-16 items-center justify-center rounded-full bg-[#34C759] transition active:scale-95">
            <VideoIcon size={26} />
          </button>
          <span className="text-[12px] font-body text-white/70">Call Again</span>
        </div>
      )}

      {locked && hint && <ThreeFingerHint light={light} />}

      {/* VFX screen options */}
      {controlsOpen && vc.source === "vfx" && (
        <VfxCallControls vfx={vfx} onChange={saveVfx} onClose={() => setControlsOpen(false)} />
      )}
    </div>
  );
}