import React, { useState, useEffect, useRef } from "react";
import {
  ChevronLeft, Music, Pause, Play, Repeat, SkipBack, SkipForward, Trash2, Upload,
} from "lucide-react";
import { listTracks, getTrack, deleteTrack, importTrack, fmtDur, MAX_TRACKS } from "@/lib/musicStore";

// OS Music app - local tracks imported from this device, stored offline.
export default function MusicApp() {
  const [tracks, setTracks] = useState([]);
  const [view, setView] = useState("list");
  const [currentId, setCurrentId] = useState(null);
  const [playing, setPlaying] = useState(false);
  const [time, setTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [repeat, setRepeat] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const audioRef = useRef(null);
  const urlsRef = useRef({});

  const current = tracks.find((t) => t.id === currentId) || null;

  const load = async () => setTracks(await listTracks());
  useEffect(() => { load(); }, []);

  // audio element lifecycle
  useEffect(() => {
    const a = new Audio();
    audioRef.current = a;
    const onTime = () => setTime(a.currentTime);
    const onMeta = () => setDuration(isFinite(a.duration) ? a.duration : 0);
    const onPlay = () => setPlaying(true);
    const onPause = () => setPlaying(false);
    a.addEventListener("timeupdate", onTime);
    a.addEventListener("loadedmetadata", onMeta);
    a.addEventListener("durationchange", onMeta);
    a.addEventListener("play", onPlay);
    a.addEventListener("pause", onPause);
    return () => {
      a.pause();
      Object.values(urlsRef.current).forEach((u) => URL.revokeObjectURL(u));
      urlsRef.current = {};
    };
  }, []);

  const urlFor = async (id) => {
    if (urlsRef.current[id]) return urlsRef.current[id];
    const t = await getTrack(id);
    if (!t) return null;
    const url = URL.createObjectURL(t.blob);
    urlsRef.current[id] = url;
    return url;
  };

  const playTrack = async (id) => {
    const a = audioRef.current;
    if (currentId === id) {
      if (a.paused) a.play().catch(() => {});
      else a.pause();
      return;
    }
    const url = await urlFor(id);
    if (!url) return;
    a.src = url;
    setCurrentId(id);
    setTime(0);
    setView("player");
    a.play().catch(() => setPlaying(false));
  };

  const step = (dir) => {
    if (!tracks.length) return;
    const i = tracks.findIndex((t) => t.id === currentId);
    if (i < 0) { playTrack(tracks[0].id); return; }
    playTrack(tracks[(i + dir + tracks.length) % tracks.length].id);
  };

  // advance at end of track
  useEffect(() => {
    const a = audioRef.current;
    if (!a || !currentId) return;
    const onEnd = () => {
      if (repeat) { a.currentTime = 0; a.play().catch(() => {}); return; }
      const i = tracks.findIndex((t) => t.id === currentId);
      const next = tracks[i + 1];
      if (next) playTrack(next.id);
      else { a.currentTime = 0; setPlaying(false); }
    };
    a.addEventListener("ended", onEnd);
    return () => a.removeEventListener("ended", onEnd);
  }, [currentId, tracks, repeat]);

  const onUpload = async (e) => {
    const files = [...(e.target.files || [])];
    e.target.value = "";
    if (!files.length) return;
    setBusy(true);
    setError("");
    try {
      let order = tracks.length;
      for (const f of files) {
        const existing = await listTracks();
        if (existing.length >= MAX_TRACKS) {
          setError(`Library is full - up to ${MAX_TRACKS} tracks`);
          break;
        }
        await importTrack(f, order++);
      }
      await load();
    } catch (err) {
      setError(err.message || "Could not import this file");
    } finally {
      setBusy(false);
    }
  };

  const removeTrack = async (id) => {
    const a = audioRef.current;
    if (currentId === id) {
      a.pause();
      a.removeAttribute("src");
      setCurrentId(null);
      setPlaying(false);
    }
    if (urlsRef.current[id]) {
      URL.revokeObjectURL(urlsRef.current[id]);
      delete urlsRef.current[id];
    }
    await deleteTrack(id);
    load();
  };

  return (
    <div className="flex h-full flex-col bg-[#0c0d14] text-white">
      {view === "player" && current ? (
        <>
          <div className="flex items-center justify-between px-5 pb-2 pt-12">
            <button onClick={() => setView("list")} className="rounded-full p-1.5 text-white/70 hover:bg-white/10 hover:text-white">
              <ChevronLeft size={18} />
            </button>
            <span className="text-[10px] font-body uppercase tracking-widest text-white/40">Now Playing</span>
            <button onClick={() => setRepeat((r) => !r)}
              className={repeat ? "rounded-full p-1.5 text-[#FC3C44]" : "rounded-full p-1.5 text-white/40 hover:bg-white/10 hover:text-white"}>
              <Repeat size={16} />
            </button>
          </div>
          <div className="flex flex-1 flex-col items-center justify-center gap-6 px-8 pb-10">
            <div className="flex h-44 w-44 items-center justify-center rounded-2xl bg-gradient-to-br from-[#FC3C44] to-[#7A1FA2] shadow-2xl">
              <Music size={52} className="text-white/90" />
            </div>
            <p className="w-full truncate text-center text-lg font-semibold font-body">{current.name}</p>
            <div className="w-full">
              <input type="range" min={0} max={duration || 0} step={0.1} value={Math.min(time, duration || 0)}
                disabled={!duration}
                onChange={(e) => {
                  const v = Number(e.target.value);
                  setTime(v);
                  if (audioRef.current) audioRef.current.currentTime = v;
                }}
                className="w-full accent-[#FC3C44]" />
              <div className="mt-1 flex justify-between text-[11px] font-body text-white/40">
                <span>{fmtDur(time)}</span>
                <span>{fmtDur(duration)}</span>
              </div>
            </div>
            <div className="flex items-center gap-8">
              <button onClick={() => step(-1)} className="rounded-full p-2 text-white/80 hover:bg-white/10">
                <SkipBack size={26} />
              </button>
              <button onClick={() => currentId && playTrack(currentId)}
                className="flex h-16 w-16 items-center justify-center rounded-full bg-[#FC3C44] shadow-lg shadow-[#FC3C44]/30">
                {playing ? <Pause size={26} /> : <Play size={26} className="translate-x-0.5" />}
              </button>
              <button onClick={() => step(1)} className="rounded-full p-2 text-white/80 hover:bg-white/10">
                <SkipForward size={26} />
              </button>
            </div>
          </div>
        </>
      ) : (
        <>
          <div className="flex items-center justify-between px-5 pb-3 pt-12">
            <h1 className="font-display text-2xl font-bold">Music</h1>
            <label className="flex cursor-pointer items-center gap-1.5 rounded-full bg-white/10 px-3.5 py-1.5 text-xs font-body backdrop-blur hover:bg-white/20">
              {busy ? "Importing…" : (<><Upload size={14} /> Import</>)}
              <input type="file" accept="audio/*" multiple className="hidden" onChange={onUpload} disabled={busy} />
            </label>
          </div>
          {error && <p className="px-5 pb-2 text-xs font-body text-red-400">{error}</p>}
          <div className="flex-1 overflow-y-auto px-3 pb-6">
            {tracks.length === 0 ? (
              <div className="flex h-full flex-col items-center justify-center gap-3 px-8 text-center">
                <Music size={36} className="text-white/25" />
                <p className="text-sm font-body text-white/40">
                  No tracks yet. Import music files from this device to play them on the mock phone.
                </p>
              </div>
            ) : tracks.map((t) => (
              <div key={t.id}
                className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left hover:bg-white/5">
                <button onClick={() => playTrack(t.id)} className="flex flex-1 items-center gap-3 text-left">
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-white/10">
                    {currentId === t.id && playing ? (
                      <Pause size={14} className="text-[#FC3C44]" />
                    ) : (
                      <Music size={15} className="text-white/60" />
                    )}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className={`block truncate text-sm font-body ${currentId === t.id ? "text-[#FC3C44]" : ""}`}>{t.name}</span>
                    <span className="block text-[11px] font-body text-white/40">{fmtDur(t.duration)}</span>
                  </span>
                </button>
                <button onClick={() => removeTrack(t.id)}
                  className="shrink-0 rounded-full p-1.5 text-white/30 hover:bg-white/10 hover:text-red-400">
                  <Trash2 size={14} />
                </button>
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );
}