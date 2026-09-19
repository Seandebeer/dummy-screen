import React, { useState, useEffect, useRef } from "react";
import {
  Check, ChevronLeft, Crop, Lock, Maximize2, Minimize2, Pause, Play,
  Repeat, Shapes, SkipBack, SkipForward,
} from "lucide-react";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import Timeline from "./Timeline";
import VideoMarks, { MARK_COLORS, MARK_STYLES } from "./VideoMarks";
import MarkAdjust from "@/components/os/MarkAdjust";
import { fmtDur, updateVideo } from "@/lib/videoStore";
import { cn } from "@/lib/utils";

const ASPECTS = [
  { id: "fit", label: "Fit (full frame)" },
  { id: "fill", label: "Fill (crop edges)" },
  { id: "16:9", label: "16:9" },
  { id: "9:16", label: "9:16 vertical" },
  { id: "1:1", label: "1:1 square" },
  { id: "4:3", label: "4:3" },
  { id: "2.39:1", label: "2.39:1 cinema" },
];
const RATIOS = { "16:9": [16, 9], "9:16": [9, 16], "1:1": [1, 1], "4:3": [4, 3], "2.39:1": [2.39, 1] };

export default function VideoPlayer({ videos, index, setIndex, onExit, urlFor }) {
  const video = videos[index];
  const vidRef = useRef(null);
  const stageRef = useRef(null);
  const saveTimer = useRef(null);
  const marksTimer = useRef(null);
  const lockEnteredFs = useRef(false);

  const [playing, setPlaying] = useState(false);
  const [time, setTime] = useState(0);
  const [locked, setLocked] = useState(false);
  const [hint, setHint] = useState(false);
  const [fs, setFs] = useState(false);
  const [stageSize, setStageSize] = useState({ w: 0, h: 0 });
  const [vidRatio, setVidRatio] = useState(null);
  const [trim, setTrim] = useState({ start: video.trimStart || 0, end: video.trimEnd ?? video.duration });
  const [loop, setLoop] = useState(!!video.loop);
  const [aspect, setAspect] = useState(video.aspect || "fit");
  const [marks, setMarks] = useState(video.marks || { style: "none", layouts: {} });

  // reset the editor whenever the queued video changes, then autoplay
  useEffect(() => {
    setTrim({ start: video.trimStart || 0, end: video.trimEnd ?? video.duration });
    setLoop(!!video.loop);
    setAspect(video.aspect || "fit");
    setMarks(video.marks || { style: "none", layouts: {} });
    setVidRatio(null);
    setTime(video.trimStart || 0);
    const v = vidRef.current;
    if (v) { v.currentTime = video.trimStart || 0; v.play().catch(() => {}); }
  }, [video.id]);

  // measure the stage for the aspect-ratio frame
  useEffect(() => {
    const el = stageRef.current;
    if (!el) return;
    const ro = new ResizeObserver(() => setStageSize({ w: el.clientWidth, h: el.clientHeight }));
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  // 3-finger tap to unlock - leaves fullscreen if the lock entered it
  useEffect(() => {
    if (!locked) return;
    const onTouch = (e) => {
      if (e.touches.length < 3) return;
      setLocked(false);
      if (lockEnteredFs.current) {
        lockEnteredFs.current = false;
        if (document.fullscreenElement) document.exitFullscreen().catch(() => {});
      }
    };
    window.addEventListener("touchstart", onTouch, { passive: true });
    return () => window.removeEventListener("touchstart", onTouch);
  }, [locked]);

  const persist = (patch) => { updateVideo(video.id, patch).catch(() => {}); };

  const setMarksPersist = (updater) => setMarks((m) => {
    const next = typeof updater === "function" ? updater(m) : { ...m, ...updater };
    clearTimeout(marksTimer.current);
    marksTimer.current = setTimeout(() => persist({ marks: next }), 400);
    return next;
  });

  const onTrim = (which, t) => {
    setTrim((cur) => {
      const next = which === "start"
        ? { ...cur, start: Math.max(0, Math.min(t, cur.end - 0.5)) }
        : { ...cur, end: Math.min(video.duration, Math.max(t, cur.start + 0.5)) };
      const v = vidRef.current;
      if (v && (v.currentTime < next.start || v.currentTime > next.end)) v.currentTime = next.start;
      clearTimeout(saveTimer.current);
      saveTimer.current = setTimeout(() => persist({ trimStart: next.start, trimEnd: next.end }), 400);
      return next;
    });
  };

  const seek = (t) => {
    const tt = Math.max(trim.start, Math.min(trim.end, t));
    const v = vidRef.current;
    if (v) v.currentTime = tt;
    setTime(tt);
  };

  const onTimeUpdate = () => {
    const v = vidRef.current;
    if (!v) return;
    setTime(v.currentTime);
    if (v.currentTime >= trim.end - 0.05) {
      if (loop) { v.currentTime = trim.start; }
      else if (index < videos.length - 1) { setIndex(index + 1); }
      else { v.pause(); v.currentTime = trim.start; }
    }
  };

  const togglePlay = () => {
    const v = vidRef.current;
    if (!v) return;
    if (v.paused) v.play().catch(() => {}); else v.pause();
  };

  const lockScreen = async () => {
    setLocked(true);
    setHint(true);
    setTimeout(() => setHint(false), 2400);
    // locked playback takes over the whole screen - no app dock
    try {
      if (!document.fullscreenElement && stageRef.current?.requestFullscreen) {
        lockEnteredFs.current = true;
        await stageRef.current.requestFullscreen();
      }
    } catch {}
  };

  const toggleFs = async () => {
    try {
      if (document.fullscreenElement) await document.exitFullscreen();
      else await stageRef.current?.requestFullscreen();
    } catch {}
  };
  useEffect(() => {
    const onFs = () => setFs(!!document.fullscreenElement);
    document.addEventListener("fullscreenchange", onFs);
    return () => document.removeEventListener("fullscreenchange", onFs);
  }, []);

  // the displayed video box - ratio frame, contained (fit) or the full stage
  const boxStyle = () => {
    const r = RATIOS[aspect];
    if (r) {
      if (!stageSize.w) return { width: "100%", height: "100%" };
      let w = stageSize.w;
      let h = (stageSize.w * r[1]) / r[0];
      if (h > stageSize.h) { h = stageSize.h; w = (stageSize.h * r[0]) / r[1]; }
      return { width: w, height: h };
    }
    if (aspect === "fit" && vidRatio) {
      let w = stageSize.w;
      let h = stageSize.w / vidRatio;
      if (h > stageSize.h) { h = stageSize.h; w = stageSize.h * vidRatio; }
      return { width: w, height: h };
    }
    return { width: "100%", height: "100%" };
  };

  return (
    <div className="relative h-full bg-black text-white">
      {/* stage - cropped to the chosen aspect ratio, tap toggles playback */}
      <div ref={stageRef} className="absolute inset-0 flex items-center justify-center overflow-hidden bg-black"
        onClick={!locked ? togglePlay : undefined}>
        <div className="relative overflow-hidden bg-black" style={boxStyle()}>
          <video ref={vidRef} src={urlFor(video)} playsInline
            className={cn("absolute inset-0 h-full w-full", aspect === "fit" && !vidRatio ? "object-contain" : "object-cover")}
            onTimeUpdate={onTimeUpdate}
            onPlay={() => setPlaying(true)}
            onPause={() => setPlaying(false)}
            onLoadedMetadata={() => {
              const v = vidRef.current;
              if (v?.videoWidth) setVidRatio(v.videoWidth / v.videoHeight);
            }} />
          <VideoMarks marks={marks} onChange={setMarksPersist} locked={locked} color={marks.color || "#FFFFFF"} />
        </div>
      </div>

      {!locked && (
        <>
          {/* top bar */}
          <div className="absolute inset-x-0 top-0 z-10 flex items-center gap-2 bg-gradient-to-b from-black/80 to-transparent px-3 pb-4 pt-2.5">
            <button onClick={onExit} className="rounded-lg bg-white/10 p-1.5 text-white/80 hover:text-white">
              <ChevronLeft size={16} />
            </button>
            <div className="min-w-0 flex-1">
              <div className="truncate text-[12px] font-body">{video.name}</div>
              <div className="text-[9px] font-body text-white/45">
                {index + 1} of {videos.length} · {fmtDur(trim.end - trim.start)} section
              </div>
            </div>
            <button onClick={toggleFs} className="rounded-lg bg-white/10 p-1.5 text-white/80 hover:text-white">
              {fs ? <Minimize2 size={14} /> : <Maximize2 size={14} />}
            </button>
            <button onClick={lockScreen} className="rounded-lg bg-white/10 p-1.5 text-white/80 hover:text-white">
              <Lock size={14} />
            </button>
          </div>

          {/* bottom editor deck */}
          <div className="absolute inset-x-0 bottom-0 z-10 bg-gradient-to-t from-black/90 via-black/60 to-transparent px-3 pb-3 pt-6">
            <Timeline duration={video.duration} trim={trim} currentTime={time} thumbs={video.thumbs}
              onTrim={onTrim} onSeek={seek} />
            <div className="mt-2.5 flex flex-wrap items-center justify-center gap-2">
              <button onClick={() => setIndex(Math.max(0, index - 1))} disabled={index === 0}
                className="rounded-full bg-white/10 p-2 text-white/80 disabled:opacity-30"><SkipBack size={14} /></button>
              <button onClick={togglePlay} className="rounded-full bg-white p-2.5 text-black">
                {playing ? <Pause size={16} /> : <Play size={16} />}
              </button>
              <button onClick={() => setIndex(Math.min(videos.length - 1, index + 1))} disabled={index === videos.length - 1}
                className="rounded-full bg-white/10 p-2 text-white/80 disabled:opacity-30"><SkipForward size={14} /></button>
              <button onClick={() => { setLoop(!loop); persist({ loop: !loop }); }}
                className={cn("rounded-full p-2", loop ? "bg-amber text-black" : "bg-white/10 text-white/80")}><Repeat size={14} /></button>
              <Popover>
                <PopoverTrigger asChild>
                  <button className="flex items-center gap-1 rounded-full bg-white/10 px-2.5 py-2 text-[10px] font-body text-white/80">
                    <Crop size={14} /> {aspect}
                  </button>
                </PopoverTrigger>
                <PopoverContent side="top" align="center" className="w-40 border-white/15 bg-black/90 p-1.5 text-white shadow-2xl backdrop-blur-xl">
                  {ASPECTS.map((a) => (
                    <button key={a.id} onClick={() => { setAspect(a.id); persist({ aspect: a.id }); }}
                      className="flex w-full items-center justify-between rounded-lg px-2.5 py-1.5 text-[10px] font-body hover:bg-white/10">
                      {a.label}
                      {aspect === a.id && <Check size={12} className="text-amber" />}
                    </button>
                  ))}
                </PopoverContent>
              </Popover>
              <Popover>
                <PopoverTrigger asChild>
                  <button className={cn("flex items-center gap-1 rounded-full px-2.5 py-2 text-[10px] font-body",
                    marks.style !== "none" ? "bg-amber text-black" : "bg-white/10 text-white/80")}>
                    <Shapes size={14} /> Marks
                  </button>
                </PopoverTrigger>
                <PopoverContent side="top" align="center" className="w-44 border-white/15 bg-black/90 p-1.5 text-white shadow-2xl backdrop-blur-xl">
                  <button onClick={() => setMarksPersist((m) => ({ ...m, style: "none" }))}
                    className="flex w-full items-center justify-between rounded-lg px-2.5 py-1.5 text-[10px] font-body uppercase tracking-wider hover:bg-white/10">
                    None
                    {marks.style === "none" && <Check size={12} className="text-amber" />}
                  </button>
                  {MARK_STYLES.map((s) => (
                    <button key={s.id} onClick={() => setMarksPersist((m) => ({ ...m, style: s.id }))}
                      className="flex w-full items-center justify-between rounded-lg px-2.5 py-1.5 text-[10px] font-body uppercase tracking-wider hover:bg-white/10">
                      {s.label}
                      {marks.style === s.id && <Check size={12} className="text-amber" />}
                    </button>
                  ))}
                  <div className="mt-1 flex flex-wrap items-center gap-1.5 border-t border-white/10 px-2 pt-1.5">
                    {MARK_COLORS.map((c) => (
                      <button key={c} onClick={() => setMarksPersist((m) => ({ ...m, color: c }))}
                        className={cn("h-4 w-4 rounded-full border transition", marks.color === c ? "border-amber ring-2 ring-amber/60" : "border-white/25")}
                        style={{ background: c }} aria-label={`Mark colour ${c}`} />
                    ))}
                  </div>
                  <MarkAdjust size={marks.size} thickness={marks.thickness} rot={marks.rot}
                    onChange={(p) => setMarksPersist((m) => ({ ...m, ...p }))} />
                  <p className="px-2.5 pt-1.5 text-[8px] font-body text-white/35">Hold &amp; drag to move · tap to rotate · double-tap to delete</p>
                </PopoverContent>
              </Popover>
            </div>
          </div>
        </>
      )}
      {locked && hint && (
        <div className="pointer-events-none absolute inset-x-0 bottom-3 flex justify-center">
          <span className="rounded-full bg-white/10 px-3 py-1 text-[10px] font-body text-white/50 backdrop-blur">
            3-finger tap to unlock
          </span>
        </div>
      )}
    </div>
  );
}