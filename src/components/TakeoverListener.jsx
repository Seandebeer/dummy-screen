import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { base44 } from "@/api/base44Client";
import { getLinkedDeviceId, getScreenId } from "@/lib/deviceLink";

const parseJson = (s) => { try { return JSON.parse(s) || {}; } catch { return {}; } };
const TRIGGER_TYPES = ["call_incoming", "call_outgoing", "alarm", "notification", "video_call"];

// When the control deck triggers anything, every screen of the app - except
// the control deck itself - jumps to the phone, which comes up fullscreen
// and locked in takeover mode.
export default function TakeoverListener() {
  const navigate = useNavigate();

  useEffect(() => {
    const takeOver = (search) => {
      const path = window.location.pathname;
      if (path === "/control" || path === "/os") return;
      navigate(`/os${search}`);
    };
    const unsubCommands = base44.entities.Command.subscribe((event) => {
      if (event.type !== "create") return;
      const c = event.data;
      if (!c || !TRIGGER_TYPES.includes(c.type)) return;
      // a reset clears the phone - it never locks anything
      if (c.type === "notification" && parseJson(c.payload).action === "reset") return;
      const own = getLinkedDeviceId();
      if (c.channel !== "stage-1" && c.channel !== (own ? `device-${own}` : null)) return;
      // triggers pushed from this same screen's own deck never echo back
      if (parseJson(c.payload).source === getScreenId()) return;
      takeOver(`?takeover=${c.id}`);
    });
    const unsubMessages = base44.entities.Message.subscribe((event) => {
      if (event.type !== "create") return;
      const m = event.data;
      if (!m || m.sender !== "control") return;
      if (m.source && m.source === getScreenId()) return;
      const own = getLinkedDeviceId();
      if (m.thread_id !== "stage-1" && m.thread_id !== (own ? `device-${own}` : null)) return;
      takeOver(`?takeover=1&msg=${m.id}`);
    });
    return () => { unsubCommands(); unsubMessages(); };
  }, [navigate]);

  return null;
}