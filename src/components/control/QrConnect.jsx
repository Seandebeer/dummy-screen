import React, { useState, useEffect, useRef, useCallback } from "react";
import { QrCode, ScanLine, X } from "lucide-react";
import { base44 } from "@/api/base44Client";

// any prop device can scan this to open its mock OS instantly
const osLink = () => `${window.location.origin}/os?connect=1`;
const qrSrc = () => `https://api.qrserver.com/v1/create-qr-code/?size=220x220&margin=8&data=${encodeURIComponent(osLink())}`;

export default function QrConnect() {
  const [scanning, setScanning] = useState(false);
  const [supported, setSupported] = useState(true);
  const [status, setStatus] = useState("");
  const videoRef = useRef(null);
  const streamRef = useRef(null);

  const register = useCallback(async (raw) => {
    let name = "Scanned device";
    try {
      const data = JSON.parse(raw);
      if (typeof data?.deviceName === "string" && data.deviceName.trim()) name = data.deviceName.trim();
    } catch {}
    try {
      await base44.entities.Device.create({ name, kind: "phone", status: "online" });
      setStatus(`Connected "${name}"`);
      setScanning(false);
    } catch {
      setStatus("Could not connect device");
    }
  }, []);

  useEffect(() => {
    if (!scanning) return undefined;
    if (!("BarcodeDetector" in window)) { setSupported(false); return undefined; }
    let alive = true;
    let timer = null;
    const detector = new window.BarcodeDetector({ formats: ["qr_code"] });
    navigator.mediaDevices?.getUserMedia({ video: { facingMode: "environment" }, audio: false })
      .then((stream) => {
        if (!alive) { stream.getTracks().forEach((t) => t.stop()); return; }
        streamRef.current = stream;
        if (videoRef.current) videoRef.current.srcObject = stream;
        videoRef.current?.play().catch(() => {});
        timer = setInterval(async () => {
          if (!videoRef.current || !alive) return;
          try {
            const codes = await detector.detect(videoRef.current);
            if (codes.length) await register(codes[0].rawValue);
          } catch {}
        }, 500);
      })
      .catch(() => { if (alive) setStatus("Camera unavailable"); });
    return () => {
      alive = false;
      if (timer) clearInterval(timer);
      streamRef.current?.getTracks().forEach((t) => t.stop());
      streamRef.current = null;
    };
  }, [scanning, register]);

  return (
    <div className="rounded-xl border border-border bg-surface p-4">
      <div className="flex items-center gap-2 mb-3">
        <QrCode size={16} className="text-amber" />
        <span className="font-display font-semibold text-sm">Quick Connect</span>
      </div>
      {scanning ? (
        <div className="flex flex-col gap-2">
          <div className="relative rounded-lg overflow-hidden bg-black aspect-[4/3] flex items-center justify-center">
            <video ref={videoRef} playsInline muted className="h-full w-full object-cover" />
            {!supported && (
              <div className="absolute inset-0 flex items-center justify-center text-center px-6 text-[11px] font-body text-white/70 bg-black/70">
                QR scanning isn't supported in this browser — have the device scan the code with its own camera instead.
              </div>
            )}
          </div>
          <div className="flex items-center justify-between">
            <span className="text-[11px] text-muted-foreground font-body">{status || "Point the camera at a device QR…"}</span>
            <button onClick={() => setScanning(false)}
              className="flex items-center gap-1 rounded-lg border border-border px-2 py-1 text-[10px] font-body text-muted-foreground hover:text-foreground transition">
              <X size={11} /> Stop
            </button>
          </div>
        </div>
      ) : (
        <div className="flex items-center gap-4">
          <div className="h-[110px] w-[110px] rounded-lg overflow-hidden bg-white p-1.5 shrink-0">
            <img src={qrSrc()} alt="Scan to open the prop OS" className="h-full w-full" />
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-[11px] text-muted-foreground font-body mb-2">
              Point a prop device's camera at this code — its mock OS opens instantly, it appears online in Devices, and this deck can remote-control it (calls, alarms, messages).
            </p>
            <button onClick={() => { setStatus(""); setSupported(true); setScanning(true); }}
              className="flex items-center gap-1.5 rounded-lg border border-amber/40 bg-amber/10 px-3 py-2 text-xs font-body text-amber hover:bg-amber/20 transition">
              <ScanLine size={14} /> Scan a device QR
            </button>
          </div>
        </div>
      )}
    </div>
  );
}