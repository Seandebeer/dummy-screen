// browser-level screen takeover: pulls the real device UI out of the way so
// only the app's screen is visible. Used by the fullscreen prop screens
// (OS takeover, UI markers) - enter on lock, exit on 3-finger unlock.
export const enterTakeover = () => {
  try {
    if (!document.fullscreenElement && document.documentElement.requestFullscreen) {
      document.documentElement.requestFullscreen().catch(() => {});
    }
  } catch {}
};

export const exitTakeover = () => {
  try {
    if (document.fullscreenElement && document.exitFullscreen) {
      document.exitFullscreen().catch(() => {});
    }
  } catch {}
};