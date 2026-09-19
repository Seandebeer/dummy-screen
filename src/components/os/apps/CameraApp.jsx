import React, { useEffect, useRef, useState } from "react";
import { Aperture, ChevronLeft, Images, RefreshCw, Trash2, X } from "lucide-react";
import { addPhoto, deletePhoto, getPhotos } from "@/lib/cameraRoll";

export default function CameraApp() {
  const videoRef = useRef(null);
  const streamRef = useRef(null);
  const [mode, setMode] = useState("camera"); // "camera" | "roll"
  const [facing, setFacing] = useState("environment");
  const [error, setError] = useState(false);
  const [flash, setFlash] = useState(false);
  const [photos, setPhotos] = useState(getPhotos);
  const [viewing, setViewing] = useState(null);

  // live camera only while capturing — stopping the stream turns the lens off
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

  if (mode === "roll") {
    return (
      <div className="relative h-full flex flex-col bg-black text-white">
        <div className="flex items-center justify-between px-3 py-2 border-b border-white/10">
          <button onClick={() => setMode("camera")} className="flex items-center gap-1 text-sm font-body text-amber">
            <ChevronLeft size={16} /> Camera
          </button>
          <div className="text-xs font-body text-white/60">{photos.length} photo{photos.length === 1 ? "" : "s"}</div>
        </div>
        <div className="flex-1 overflow-y-auto no-scrollbar p-1">
          {photos.length ? (
            <div className="grid grid-cols-3 gap-1">
              {photos.map((p) => (
                <button key={p.id} onClick={() => setViewing(p)} className="aspect-square overflow-hidden rounded-lg">
                  <img src={p.url} alt="Captured" className="h-full w-full object-cover" />
                </button>
              ))}
            </div>
          ) : (
            <div className="h-full flex flex-col items-center justify-center gap-2 text-center px-8">
              <Images size={24} className="text-white/30" />
              <div className="text-xs font-body text-white/50">No photos yet — capture from the camera</div>
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
              <img src={viewing.url} alt="Captured" className="max-h-full max-w-full rounded-xl" />
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

      <div className="absolute top-2 inset-x-0 px-3 flex items-center justify-between">
        <button onClick={() => setMode("roll")} title="Camera roll"
          className="relative flex h-9 w-9 items-center justify-center rounded-full bg-black/45 backdrop-blur">
          <Images size={16} />
          {photos.length > 0 && (
            <span className="absolute -top-1 -right-1 rounded-full bg-amber px-1.5 text-[9px] font-body font-semibold text-black">{photos.length}</span>
          )}
        </button>
        <button onClick={() => setFacing((f) => (f === "environment" ? "user" : "environment"))} title="Flip lens"
          className="flex h-9 w-9 items-center justify-center rounded-full bg-black/45 backdrop-blur">
          <RefreshCw size={16} />
        </button>
      </div>

      <div className="absolute bottom-4 inset-x-0 flex justify-center">
        <button onClick={capture} disabled={error} title="Capture"
          className="h-16 w-16 rounded-full border-4 border-white/80 bg-white/20 backdrop-blur active:scale-95 transition disabled:opacity-40" />
      </div>
    </div>
  );
}