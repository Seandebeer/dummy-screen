import React, { useEffect, useRef, useState } from "react";
import { Aperture, ChevronLeft, Film, Images, Play, RefreshCw, Trash2, X } from "lucide-react";
import { addPhoto, addVideo, deletePhoto, getClip, getPhotos } from "@/lib/cameraRoll";
import ClipsGallery from "@/components/os/apps/camera/ClipsGallery";
import { cn } from "@/lib/utils";

export default function CameraApp() {
  const videoRef = useRef(null);
  const streamRef = useRef(null);
  const recorderRef = useRef(null);
  const chunksRef = useRef([]);
  const recTimerRef = useRef(null);
  const [mode, setMode] = useState("camera"); // "camera" | "roll"
  const [lens, setLens] = useState("photo");   // "photo" | "video"
  const [facing, setFacing] = useState("environment");
  const [error, setError] = useState(false);
  const [flash, setFlash] = useState(false);
  const [recording, setRecording] = useState(false);
  const [recSecs, setRecSecs] = useState(0);
  const [photos, setPhotos] = useState(getPhotos);
  const [viewing, setViewing] = useState(null);
  const [clipUrl, setClipUrl] = useState(null);

  // live camera only while capturing - stopping the stream turns the lens off
  useEffect(() => {
    if (mode !== "camera") return undefined;
    let alive = true;
    setError(false);
    navigator.mediaDevices?.getUserMedia({ video: { facingMode: facing }, audio: false })
      .then((stream) => {
        if (!alive) { stream.getTracks().forEach((t) => t.stop()); return; }
        streamRef.current = stream;
        if (videoRef.current) videoRef.current.srcObject = stream;
      })
      .catch(() => { if (alive) setError(true); });
    return () => {
      alive = false;
      // stop any live recording before the lens goes dark
      if (recorderRef.current?.state === "recording") {
        try { recorderRef.current.stop(); } catch {}
      }
      clearInterval(recTimerRef.current);
      streamRef.current?.getTracks().forEach((t) => t.stop());
      streamRef.current = null;
    };
  }, [facing, mode]);

  // resolve a recorded clip from IndexedDB while it's being viewed
  useEffect(() => {
    if (viewing?.type !== "video") return undefined;
    let url = null;
    let dead = false;
    getClip(viewing.id).then((rec) => {
      if (dead || !rec?.blob) return;
      url = URL.createObjectURL(rec.blob);
      setClipUrl(url);
    });
    return () => {
      dead = true;
      if (url) URL.revokeObjectURL(url);
      setClipUrl(null);
    };
  }, [viewing?.id]);

  const capture = () => {
    const v = videoRef.current;
    if (!v || !v.videoWidth) return;
    const scale = Math.min(1, 720 / v.videoWidth);
    const canvas = document.createElement("canvas");
    canvas.width = Math.round(v.videoWidth * scale);
    canvas.height = Math.round(v.videoHeight * scale);
    canvas.getContext("2d").drawImage(v, 0, 0, canvas.width, canvas.height);
    setPhotos(addPhoto(canvas.toDataURL("image/jpeg", 0.72)));
    setFlash(true);
    setTimeout(() => setFlash(false), 160);
  };

  const startRecording = () => {
    const stream = streamRef.current;
    if (!stream || !window.MediaRecorder) return;
    let opts;
    for (const mt of ["video/webm;codecs=vp9", "video/webm", "video/mp4"]) {
      if (MediaRecorder.isTypeSupported?.(mt)) { opts = { mimeType: mt }; break; }
    }
    try {
      const rec = new MediaRecorder(stream, opts);
      chunksRef.current = [];
      rec.ondataavailable = (e) => { if (e.data?.size) chunksRef.current.push(e.data); };
      rec.onstop = () => saveRecording(rec.mimeType);
      recorderRef.current = rec;
      rec.start(500);
      setRecording(true);
      setRecSecs(0);
      recTimerRef.current = setInterval(() => setRecSecs((s) => s + 1), 1000);
    } catch {}
  };

  const stopRecording = () => {
    clearInterval(recTimerRef.current);
    if (recorderRef.current?.state === "recording") recorderRef.current.stop();
    setRecording(false);
  };

  const saveRecording = async (mimeType) => {
    const blob = new Blob(chunksRef.current, { type: mimeType || "video/webm" });
    chunksRef.current = [];
    if (!blob.size) return;
    // small poster frame so the roll thumbnail survives reloads
    let poster = "";
    try {
      const v = videoRef.current;
      if (v?.videoWidth) {
        const scale = Math.min(1, 360 / v.videoWidth);
        const canvas = document.createElement("canvas");
        canvas.width = Math.round(v.videoWidth * scale);
        canvas.height = Math.round(v.videoHeight * scale);
        canvas.getContext("2d").drawImage(v, 0, 0, canvas.width, canvas.height);
        poster = canvas.toDataURL("image/jpeg", 0.5);
      }
    } catch {}
    try { setPhotos(await addVideo(blob, poster)); } catch {}
  };

  const recTime = `${Math.floor(recSecs / 60)}:${String(recSecs % 60).padStart(2, "0")}`;

  if (mode === "clips") {
    return (
      <ClipsGallery
        clips={photos.filter((p) => p.type === "video")}
        onBack={() => setMode("camera")}
        onChange={setPhotos}
      />
    );
  }

  if (mode === "roll") {
    return (
      <div className="relative h-full flex flex-col bg-black text-white">
        <div className="flex items-center justify-between px-3 py-2 border-b border-white/10">
          <button onClick={() => setMode("camera")} className="flex items-center gap-1 text-sm font-body text-amber">
            <ChevronLeft size={16} /> Camera
          </button>
          <div className="flex items-center gap-3">
            <button onClick={() => setMode("clips")} className="flex items-center gap-1 text-xs font-body text-amber">
              <Film size={13} /> Clips
            </button>
            <div className="text-xs font-body text-white/60">{photos.length} item{photos.length === 1 ? "" : "s"}</div>
          </div>
        </div>
        <div className="flex-1 overflow-y-auto no-scrollbar p-1">
          {photos.length ? (
            <div className="grid grid-cols-3 gap-1">
              {photos.map((p) => (
                <button key={p.id} onClick={() => setViewing(p)} className="relative aspect-square overflow-hidden rounded-lg">
                  <img src={p.type === "video" ? p.poster : p.url} alt="Captured" className="h-full w-full object-cover" />
                  {p.type === "video" && (
                    <span className="absolute inset-0 flex items-center justify-center bg-black/25">
                      <span className="rounded-full bg-black/55 p-1.5"><Play size={12} /></span>
                    </span>
                  )}
                </button>
              ))}
            </div>
          ) : (
            <div className="h-full flex flex-col items-center justify-center gap-2 text-center px-8">
              <Images size={24} className="text-white/30" />
              <div className="text-xs font-body text-white/50">No photos or videos yet - capture from the camera</div>
            </div>
          )}
        </div>
        {viewing && (
          <div className="absolute inset-0 z-10 bg-black/95 flex flex-col">
            <div className="flex items-center justify-between px-3 py-2">
              <button onClick={() => setViewing(null)} className="h-9 w-9 flex items-center justify-center rounded-full bg-white/10"><X size={16} /></button>
              <button onClick={() => { setPhotos(deletePhoto(viewing.id)); setViewing(null); }}
                className="h-9 w-9 flex items-center justify-center rounded-full bg-white/10 text-red-400"><Trash2 size={16} /></button>
            </div>
            <div className="flex-1 flex items-center justify-center p-2">
              {viewing.type === "video" ? (
                clipUrl ? (
                  <video src={clipUrl} controls autoPlay playsInline className="max-h-full w-full rounded-xl" />
                ) : (
                  <div className="text-xs font-body text-white/50">Loading clip…</div>
                )
              ) : (
                <img src={viewing.url} alt="Captured" className="max-h-full max-w-full rounded-xl" />
              )}
            </div>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="relative h-full bg-black text-white overflow-hidden">
      {error ? (
        <div className="h-full flex flex-col items-center justify-center gap-2 px-8 text-center">
          <Aperture size={28} className="text-white/30" />
          <div className="text-sm font-body text-white/70">Camera unavailable</div>
          <div className="text-[11px] font-body text-white/35">Allow camera access in the browser to use the lens</div>
        </div>
      ) : (
        <video ref={videoRef} autoPlay playsInline muted className="h-full w-full object-cover" />
      )}
      {flash && <div className="absolute inset-0 bg-white/80 pointer-events-none" />}

      {recording && (
        <div className="absolute top-2 left-1/2 -translate-x-1/2 flex items-center gap-1.5 rounded-full bg-black/60 px-3 py-1 backdrop-blur">
          <span className="h-2 w-2 rounded-full bg-[#FF453A] animate-pulse" />
          <span className="text-[12px] font-body tabular-nums">{recTime}</span>
        </div>
      )}

      <div className="absolute top-2 inset-x-0 px-3 flex items-center justify-between">
        <button onClick={() => setMode("roll")} disabled={recording} title="Camera roll"
          className="relative flex h-9 w-9 items-center justify-center rounded-full bg-black/45 backdrop-blur disabled:opacity-40">
          <Images size={16} />
          {photos.length > 0 && (
            <span className="absolute -top-1 -right-1 rounded-full bg-amber px-1.5 text-[9px] font-body font-semibold text-black">{photos.length}</span>
          )}
        </button>
        <button onClick={() => setMode("clips")} disabled={recording} title="Clips"
          className="relative flex h-9 w-9 items-center justify-center rounded-full bg-black/45 backdrop-blur disabled:opacity-40">
          <Film size={16} />
          {photos.some((p) => p.type === "video") && (
            <span className="absolute -top-1 -right-1 rounded-full bg-[#FF453A] px-1.5 text-[9px] font-body font-semibold text-white">
              {photos.filter((p) => p.type === "video").length}
            </span>
          )}
        </button>
        <button onClick={() => setFacing((f) => (f === "environment" ? "user" : "environment"))}
          disabled={recording} title="Flip lens"
          className="flex h-9 w-9 items-center justify-center rounded-full bg-black/45 backdrop-blur disabled:opacity-40">
          <RefreshCw size={16} />
        </button>
      </div>

      {/* photo / video mode selector */}
      <div className="absolute bottom-24 inset-x-0 flex justify-center gap-7 text-[11px] font-semibold uppercase tracking-widest">
        <button onClick={() => setLens("photo")} disabled={recording}
          className={cn("transition disabled:opacity-40", lens === "photo" ? "text-amber" : "text-white/45")}>
          Photo
        </button>
        <button onClick={() => setLens("video")} disabled={recording}
          className={cn("transition disabled:opacity-40", lens === "video" ? "text-[#FF453A]" : "text-white/45")}>
          Video
        </button>
      </div>

      <div className="absolute bottom-4 inset-x-0 flex justify-center">
        {lens === "photo" ? (
          <button onClick={capture} disabled={error} title="Capture"
            className="h-16 w-16 rounded-full border-4 border-white/80 bg-white/20 backdrop-blur active:scale-95 transition disabled:opacity-40" />
        ) : (
          <button onClick={recording ? stopRecording : startRecording} disabled={error}
            title={recording ? "Stop recording" : "Record video"}
            className={cn("flex h-16 w-16 items-center justify-center rounded-full border-4 transition active:scale-95 disabled:opacity-40",
              recording ? "border-[#FF453A] bg-[#FF453A]/20" : "border-[#FF453A]/70 bg-[#FF453A]/15")}>
            <span className={cn("transition-all", recording ? "h-7 w-7 rounded-md bg-[#FF453A]" : "h-9 w-9 rounded-full bg-[#FF453A]")} />
          </button>
        )}
      </div>
    </div>
  );
}