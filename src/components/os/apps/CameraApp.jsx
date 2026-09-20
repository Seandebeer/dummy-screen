import React, { useEffect, useRef, useState } from "react";
import { Aperture, Film, Images, RefreshCw } from "lucide-react";
import { addPhoto, addVideo, getPhotos } from "@/lib/cameraRoll";
import ClipsGallery from "@/components/os/apps/camera/ClipsGallery";
import PhotosApp from "@/components/os/apps/PhotosApp";
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

  // the camera roll is the Apple-style Photos gallery, shared with the
  // standalone Photos app on the home screen
  if (mode === "roll") {
    return <PhotosApp onBack={() => setMode("camera")} />;
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