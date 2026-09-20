import React, { useEffect, useRef, useState } from "react";
import { ChevronLeft, Loader2, Lock, Mic, MicOff, Monitor, PhoneOff, RefreshCw, SlidersHorizontal, Upload, Video as VideoIcon, Image as ImageIcon } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { Image } from "@/components/ui/image";
import ContactPicker from "@/components/os/apps/videocall/ContactPicker";
import PipView from "@/components/os/apps/videocall/PipView";
import VfxCallControls from "@/components/os/apps/videocall/VfxCallControls";
import { TrackingMarks } from "@/components/vfx/TrackingMarks";
import ThreeFingerHint from "@/components/os/ThreeFingerHint";
import { startPhoneVideo } from "@/lib/videoLink";
import { defaultLayoutFor } from "@/hooks/useScreenMarks";
import { cn } from "@/lib/utils";

const DEFAULT_CALL_VFX = { bgColor: "#00B140", markStyle: "cross", markColor: null, markSize: 1.1, markThick: 0.6, markRot: 0 };

const isLightHex = (hex) => {
  const m = /^#?([0-9a-f]{6})$/i.exec(hex || "");
  if (!m) return false;
  const n = parseInt(m[1], 16);
  return ((n >> 16) & 255) * 0.299 + ((n >> 8) & 255) * 0.587 + (n & 255) * 0.114 > 150;
};
const keyOf = (c) => String(c?.id ?? c?.number ?? c?.name ?? "");
const initialsOf = (name) =>
  (name || "?").trim().split(/\s+/).map((w) => w[0]).slice(0, 2).join("").toUpperCase();

export default function VideoCallApp({ config, update, remote, onRemoteEnd }) {
  const store = { contacts: {}, ...(config.videocall || {}) };
  const [screen, setScreen] = useState("list"); // list | setup
  const [picked, setPicked] = useState(null);
  const [inCall, setInCall] = useState(false);
  const [secs, setSecs] = useState(0);
  const [muted, setMuted] = useState(false);
  const [facing, setFacing] = useState("user");
  const [ended, setEnded] = useState(false);
  const [answered, setAnswered] = useState(false);
  const [controlsOpen, setControlsOpen] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [camError, setCamError] = useState(false);
  const [locked, setLocked] = useState(false);
  const [controlsVisible, setControlsVisible] = useState(true);
  const [hint, setHint] = useState(false);
  const [liveOn, setLiveOn] = useState(false);
  const pipVideoRef = useRef(null);
  const liveVideoRef = useRef(null);
  const streamRef = useRef(null);
  const videoLinkRef = useRef(null);
  const fileRef = useRef(null);
  const rootRef = useRef(null);
  const wasRemoteRef = useRef(false);

  const remoteOn = !!remote;
  const rp = remote?.payload || {};
  const setKey = picked ? keyOf(picked) : "";
  const cset = (setKey && store.contacts[setKey]) || {};

  const manualMode = cset.mode || "vfx";
  const callMode = remoteOn ? (rp.mode || "vfx") : manualMode;
  const callVfx = { ...DEFAULT_CALL_VFX, ...(remoteOn ? rp.vfx : cset.vfx) };
  const callPhoto = remoteOn ? rp.photoUrl : cset.photoUrl;
  const callVideo = remoteOn ? rp.videoUrl : cset.videoUrl;
  const callerName = remoteOn ? (remote.contact?.name || "Video Call") : (picked?.name || "Video Call");
  const camOff = !!rp.camOff;
  const micOff = !!rp.micMuted;

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

  // keep the pip element attached to the stream whenever it (re)mounts
  useEffect(() => {
    if (pipVideoRef.current && streamRef.current) pipVideoRef.current.srcObject = streamRef.current;
  });

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

  // a control-deck call opens the app and rings until answered
  useEffect(() => {
    if (!remote) return;
    setAnswered(false);
    setEnded(false);
    setSecs(0);
    setLocked(false);
    setControlsVisible(true);
    setPicked(remote.contact ? { ...remote.contact } : null);
  }, [remote?.id]);

  // the control deck hung up - show the ended overlay
  useEffect(() => {
    if (!remoteOn && wasRemoteRef.current && inCall) setEnded(true);
    wasRemoteRef.current = remoteOn;
  }, [remoteOn, inCall]);

  // live feed from the control deck
  useEffect(() => {
    if (!inCall || !remote || callMode !== "live") return undefined;
    videoLinkRef.current?.stop();
    videoLinkRef.current = startPhoneVideo(remote.id, liveVideoRef.current, remote.channel || "stage-1");
    return () => {
      videoLinkRef.current?.stop();
      videoLinkRef.current = null;
      setLiveOn(false);
    };
  }, [inCall, remote?.id, callMode]);

  const saveStore = (patch) => update((c) => ({
    videocall: {
      contacts: {}, ...(c.videocall || {}),
      ...(typeof patch === "function" ? patch(c.videocall || {}) : patch),
    },
  }));
  const savePicked = (p) => {
    if (!setKey) return;
    saveStore((s) => ({
      contacts: { ...(s.contacts || {}), [setKey]: { mode: "vfx", ...(s.contacts?.[setKey] || {}), ...p } },
    }));
  };

  const uploadMedia = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file || !setKey) return;
    setUploading(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
      if (file.type.startsWith("video")) savePicked({ mode: "video", videoUrl: file_url });
      else savePicked({ mode: "photo", photoUrl: file_url });
    } catch {}
    setUploading(false);
  };

  const startCall = () => {
    setEnded(false);
    setSecs(0);
    setInCall(true);
    setLocked(false);
    setControlsVisible(true);
  };
  const endCall = () => {
    if (remoteOn) onRemoteEnd?.();
    else setEnded(true);
  };
  const acceptRemote = () => {
    setAnswered(true);
    setInCall(true);
    setSecs(0);
    setControlsVisible(true);
    if (remote) base44.entities.Command.update(remote.id, { status: "active" }).catch(() => {});
  };
  const lock = () => {
    setLocked(true);
    setControlsVisible(false);
    setControlsOpen(false);
    setHint(true);
    setTimeout(() => setHint(false), 2400);
  };
  const tapScreen = () => {
    if (!inCall || ended || locked || controlsOpen) return;
    setControlsVisible((v) => !v);
  };

  const time = `${Math.floor(secs / 60)}:${String(secs % 60).padStart(2, "0")}`;
  const markColor = callVfx.markColor || (isLightHex(callVfx.bgColor) ? "#000000" : "#FFFFFF");
  const markLayout = defaultLayoutFor(callVfx.markStyle);
  const showUi = controlsVisible && !locked && !ended;
  const light = callMode === "vfx" ? isLightHex(callVfx.bgColor) : false;
  const ctl = "flex h-10 w-10 items-center justify-center rounded-full text-white/90 transition active:scale-90";
  const pill = (active) => cn(
    "flex h-9 items-center gap-1.5 rounded-full px-3 text-[10px] font-body transition active:scale-95",
    active ? "bg-[#0A84FF]" : "text-white/80 hover:text-white");

  const placeholder = (text) => (
    <div className="absolute inset-0 flex flex-col items-center justify-center gap-2 bg-[#101012]">
      <div className="flex h-20 w-20 items-center justify-center rounded-full bg-white/10 font-display text-[22px] font-semibold text-white/90">
        {initialsOf(callerName)}
      </div>
      <span className="text-[11px] font-body text-white/50">{text}</span>
    </div>
  );

  // the far-end screen - live stream, uploaded video / photo or a VFX screen
  const bigArea = () => {
    if (callMode === "live") {
      return (
        <>
          <video ref={liveVideoRef} autoPlay playsInline onPlaying={() => setLiveOn(true)}
            className="absolute inset-0 h-full w-full object-cover" />
          {(camOff || !liveOn) && placeholder(camOff ? "Camera off" : "Connecting…")}
        </>
      );
    }
    if (callMode === "photo") {
      return callPhoto
        ? <Image src={callPhoto} alt="" className="absolute inset-0 h-full w-full" fittingType="fill" />
        : placeholder(`No photo for ${callerName}`);
    }
    if (callMode === "video") {
      return callVideo
        ? <video key={callVideo} src={callVideo} autoPlay loop playsInline muted
            className="absolute inset-0 h-full w-full object-cover" />
        : placeholder("No video for the other end yet");
    }
    return (
      <div className="absolute inset-0" style={{ background: callVfx.bgColor }}>
        <TrackingMarks type={callVfx.markStyle} color={markColor} opacity={0.9}
          size={callVfx.markSize} thickness={callVfx.markThick}
          markers={callVfx.markRot
            ? markLayout.map((m) => ({ ...m, rot: (m.rot || 0) + callVfx.markRot }))
            : markLayout} />
      </div>
    );
  };

  const tuneSetup = manualMode === "vfx" ? (
    <button onClick={() => setControlsOpen(true)} title="Screen options" className={ctl}>
      <SlidersHorizontal size={18} />
    </button>
  ) : (
    <button onClick={() => fileRef.current?.click()} disabled={uploading}
      title={manualMode === "photo" ? "Add photo" : "Add video"}
      className={cn(ctl, "disabled:opacity-50")}>
      {uploading ? <Loader2 size={18} className="animate-spin" /> : <Upload size={18} />}
    </button>
  );

  // ---- incoming control-deck video call - rings until answered ----
  if (remoteOn && !answered) {
    const ringPhoto = remote.contact?.image;
    const ringFull = rp.photoMode === "full" && ringPhoto;
    return (
      <div className="absolute inset-0 z-40 flex flex-col items-center justify-between overflow-hidden px-6 py-14 text-white"
        style={{ background: ringFull ? "#000" : "linear-gradient(180deg, #1a1d2e 0%, #0a0b14 100%)" }}>
        {ringFull && (
          <>
            <Image src={ringPhoto} alt={callerName} className="absolute inset-0 h-full w-full" fittingType="fill" />
            <div className="absolute inset-0 bg-gradient-to-b from-black/30 via-black/10 to-black/60" />
          </>
        )}
        <div className="relative mt-6 flex flex-col items-center">
          {!ringFull && (
            <div className="mb-4 flex h-28 w-28 items-center justify-center overflow-hidden rounded-full bg-white/10 font-display text-4xl font-bold">
              {ringPhoto
                ? <Image src={ringPhoto} alt={callerName} className="h-full w-full" fittingType="fill" />
                : initialsOf(callerName)}
            </div>
          )}
          <div className="font-display text-3xl font-semibold drop-shadow">{callerName}</div>
          <div className="mt-1 font-body text-sm text-white/60">wants to video chat…</div>
        </div>
        <div className="relative flex items-center gap-16">
          <button onClick={() => onRemoteEnd?.()} className="flex flex-col items-center gap-2">
            <span className="flex h-16 w-16 items-center justify-center rounded-full bg-[#FF3B30]"><PhoneOff size={26} className="text-white" /></span>
            <span className="font-body text-xs text-white/60">Decline</span>
          </button>
          <button onClick={acceptRemote} className="flex flex-col items-center gap-2">
            <span className="flex h-16 w-16 animate-pulse items-center justify-center rounded-full bg-[#34C759]"><VideoIcon size={26} className="text-black" /></span>
            <span className="font-body text-xs text-white/60">Accept</span>
          </button>
        </div>
      </div>
    );
  }

  // ---- contact picker + per-contact setup ----
  if (!inCall) {
    return (
      <div ref={rootRef} className="relative h-full select-none overflow-hidden bg-[#0a0a0c] text-white">
        {screen === "list" || !picked ? (
          <ContactPicker contacts={config.contacts || []}
            onSelect={(c) => { setPicked(c); setScreen("setup"); }} />
        ) : (
          <>
            <div className="absolute inset-0">{bigArea()}</div>
            <button onClick={() => setScreen("list")} aria-label="Back"
              className="absolute left-2 top-2 z-10 flex h-9 w-9 items-center justify-center rounded-full bg-black/45 backdrop-blur">
              <ChevronLeft size={18} />
            </button>
            <div className="pointer-events-none absolute left-0 right-0 top-3 z-10 text-center text-[13px] font-display font-semibold drop-shadow">
              {picked.name}
            </div>
            <PipView containerRef={rootRef} videoRef={pipVideoRef} camError={camError} facing={facing} />
            <div className="absolute bottom-4 left-1/2 z-10 flex max-w-[calc(100%-1.5rem)] -translate-x-1/2 flex-wrap items-center justify-center gap-3 rounded-[2rem] bg-black/45 px-3.5 py-2.5 backdrop-blur-md">
              {(["vfx", "photo", "video"]).map((m) => (
                <button key={m} onClick={() => savePicked({ mode: m })} className={pill(manualMode === m)}>
                  {m === "vfx" ? <Monitor size={15} /> : m === "photo" ? <ImageIcon size={15} /> : <VideoIcon size={15} />}
                  {m === "vfx" ? "VFX" : m === "photo" ? "Photo" : "Video"}
                </button>
              ))}
              {tuneSetup}
              <button onClick={() => setFacing((f) => (f === "user" ? "environment" : "user"))}
                title="Flip camera" className={ctl}><RefreshCw size={18} /></button>
              <button onClick={startCall} title="Start call"
                className={cn(ctl, "bg-[#34C759]")}><VideoIcon size={18} /></button>
            </div>
            <input ref={fileRef} type="file" accept="image/*,video/*" className="hidden" onChange={uploadMedia} />
            {controlsOpen && manualMode === "vfx" && (
              <VfxCallControls vfx={callVfx}
                onChange={(p) => savePicked({ vfx: { ...callVfx, ...p } })}
                onClose={() => setControlsOpen(false)} />
            )}
          </>
        )}
      </div>
    );
  }

  // ---- in call (manual or control-driven) ----
  return (
    <div ref={rootRef} className="relative h-full select-none overflow-hidden bg-black text-white">
      <div className="absolute inset-0" onClick={tapScreen}>{bigArea()}</div>

      {/* FaceTime style header - caller + duration while the controls are on */}
      {showUi && (
        <div className="pointer-events-none absolute left-0 right-0 top-3 z-10 flex flex-col items-center gap-0.5">
          <span className="text-[13px] font-display font-semibold drop-shadow">{callerName}</span>
          <span className="text-[10px] font-body text-white/70 drop-shadow">{time}</span>
          {micOff && <span className="text-[9px] font-body text-white/50">Caller muted</span>}
        </div>
      )}

      {/* own camera, draggable picture in picture */}
      <PipView containerRef={rootRef} videoRef={pipVideoRef} camError={camError} facing={facing}
        onTap={inCall && !ended ? tapScreen : undefined} />

      {!ended && showUi && (
        <div className="absolute bottom-4 left-1/2 z-10 flex max-w-[calc(100%-1.5rem)] -translate-x-1/2 flex-wrap items-center justify-center gap-3 rounded-[2rem] bg-black/45 px-3.5 py-2.5 backdrop-blur-md">
          <button onClick={() => setMuted((m) => !m)} title={muted ? "Unmute" : "Mute"}
            className={cn(ctl, muted && "bg-white text-black")}>
            {muted ? <MicOff size={18} /> : <Mic size={18} />}
          </button>
          <button onClick={() => setFacing((f) => (f === "user" ? "environment" : "user"))}
            title="Flip camera" className={ctl}><RefreshCw size={18} /></button>
          {!remoteOn && (callMode === "vfx" ? (
            <button onClick={() => setControlsOpen(true)} title="Screen options" className={ctl}>
              <SlidersHorizontal size={18} />
            </button>
          ) : (
            <button onClick={() => fileRef.current?.click()} disabled={uploading}
              title={callMode === "photo" ? "Replace photo" : "Replace video"}
              className={cn(ctl, "disabled:opacity-50")}>
              {uploading ? <Loader2 size={18} className="animate-spin" /> : <Upload size={18} />}
            </button>
          ))}
          <button onClick={lock} title="Lock screen" className={ctl}><Lock size={18} /></button>
          <button onClick={endCall} title="End call"
            className={cn(ctl, "bg-[#FF453A]")}><PhoneOff size={18} /></button>
        </div>
      )}
      <input ref={fileRef} type="file" accept="image/*,video/*" className="hidden" onChange={uploadMedia} />

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
          <button onClick={() => { setInCall(false); setScreen("list"); setEnded(false); }}
            className="mt-2 text-[11px] font-body text-white/50 underline underline-offset-2">
            Contacts
          </button>
        </div>
      )}

      {locked && hint && <ThreeFingerHint light={light} />}

      {controlsOpen && !locked && !remoteOn && callMode === "vfx" && (
        <VfxCallControls vfx={callVfx}
          onChange={(p) => savePicked({ vfx: { ...callVfx, ...p } })}
          onClose={() => setControlsOpen(false)} />
      )}
    </div>
  );
}