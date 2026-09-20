import { applyPage } from "@/lib/savedPages";
import { applyOsConfig } from "@/lib/osConfigStore";

// open a saved entry on this screen - shared by the Saved card and the
// per-device folders on Home so both behave identically
export const openSavedEntry = (s, navigate) => {
  if (s.kind === "os") {
    applyOsConfig(s.data);
    navigate("/os");
  } else if (s.kind === "markers") {
    try {
      const cfg = JSON.parse(localStorage.getItem("takeover-os-config")) || {};
      cfg.uiMarkers = s.uiMarkers;
      localStorage.setItem("takeover-os-config", JSON.stringify(cfg));
    } catch {}
    navigate("/uimarkers");
  } else if (s.kind === "page") {
    applyPage(s);
    navigate("/os");
  } else {
    try {
      localStorage.setItem("takeover-screen-marks", JSON.stringify(s.marks));
    } catch {}
    navigate(`/vfx?color=${s.colorId}&marks=${s.marksId}`);
  }
};