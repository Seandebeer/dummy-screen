import React, { useState, useEffect, useCallback, useRef } from "react";
import { Loader2 } from "lucide-react";
import { listVideos } from "@/lib/videoStore";
import VideoLibrary from "./video/VideoLibrary";
import VideoPlayer from "./video/VideoPlayer";

// Videos app - a queue of up to five locally stored clips with a
// trim / loop editor, aspect-ratio crop, fullscreen and a 3-finger lock
export default function VideoApp() {
  const [videos, setVideos] = useState(null);
  const [playIndex, setPlayIndex] = useState(null);
  const urlMapRef = useRef({});

  const reload = useCallback(() => {
    listVideos().then(setVideos).catch(() => setVideos([]));
  }, []);

  useEffect(() => { reload(); }, [reload]);

  // blob object urls are created once per video and freed on close
  const urlFor = (rec) => {
    if (!urlMapRef.current[rec.id]) urlMapRef.current[rec.id] = URL.createObjectURL(rec.blob);
    return urlMapRef.current[rec.id];
  };

  useEffect(() => {
    const map = urlMapRef.current;
    return () => Object.values(map).forEach((u) => URL.revokeObjectURL(u));
  }, []);

  if (videos === null) {
    return (
      <div className="flex h-full items-center justify-center bg-[#0b0b0f] text-white/50">
        <Loader2 size={20} className="animate-spin" />
      </div>
    );
  }

  if (playIndex !== null && videos[playIndex]) {
    return (
      <VideoPlayer videos={videos} index={playIndex} setIndex={setPlayIndex}
        onExit={() => setPlayIndex(null)} urlFor={urlFor} />
    );
  }

  return <VideoLibrary videos={videos} reload={reload} onPlay={setPlayIndex} />;
}