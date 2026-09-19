import React from "react";
import VideoApp from "@/components/os/apps/VideoApp";

// Videos - the app's own video queue player (not part of the mock OS):
// up to five locally stored clips with trim / loop timeline, aspect-ratio
// crop, fullscreen and a 3-finger screen lock
export default function Videos() {
  return (
    <div className="h-dvh pb-16 md:pb-0">
      <VideoApp />
    </div>
  );
}