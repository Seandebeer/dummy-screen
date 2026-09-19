import React, { useState, useEffect, useCallback, useRef } from "react";
import { Link } from "react-router-dom";
import { ArrowLeft, Radio, Maximize2 } from "lucide-react";
import PhoneFrame from "@/components/os/PhoneFrame";
import Homescreen from "@/components/os/Homescreen";
import PhoneApp from "@/components/os/apps/PhoneApp";
import ContactsApp from "@/components/os/apps/ContactsApp";
import MessagesApp from "@/components/os/apps/MessagesApp";
import EmailApp from "@/components/os/apps/EmailApp";
import ClockApp from "@/components/os/apps/ClockApp";
import CallOverlay from "@/components/os/CallOverlay";
import MockApp from "@/components/os/apps/MockApp";
import { allAppsById } from "@/lib/osApps";
import useOsConfig from "@/hooks/useOsConfig";
import LockScreen from "@/components/os/LockScreen";
import SettingsApp from "@/components/os/apps/SettingsApp";
import { base44 } from "@/api/base44Client";

export default function OS() {
  const [app, setApp] = useState(null);
  const [locked, setLocked] = useState(true);
  const { config, update } = useOsConfig();
  const [fullscreen, setFullscreen] = useState(false);
  const [fsHint, setFsHint] = useState(false);
  const fsHintTimer = useRef(null);
  const [, setTick] = useState(0);
  const [call, setCall] = useState(null);
  const [recents, setRecents] = useState([]);
  const callRef = useRef(null);
  const fmtTime = (d) => new Date(d).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });

  const addRecent = (cur) => setRecents((r) => [{
    label: cur.contact?.name || cur.contact?.number || "Unknown",
    number: cur.contact?.number || "",
    type: cur.phase === "incoming" ? "Incoming" : "Outgoing",
    time: fmtTime(Date.now()),
  }, ...r].slice(0, 30));

  // load + subscribe to commands (control-driven calls)
  useEffect(() => {
    let mounted = true;
    base44.entities.Command.filter({ channel: "stage-1" }, "-created_date", 50)
      .then((data) => {
        if (!mounted) return;
        const past = data.filter((c) => c.status === "completed").map((c) => ({
          label: c.contact_name || c.contact_number || "Unknown",
          number: c.contact_number || "",
          type: c.type === "call_incoming" ? "Incoming" : "Outgoing",
          time: fmtTime(c.created_date),
        }));
        setRecents(past);
      }).catch(() => {});

    const unsub = base44.entities.Command.subscribe((event) => {
      const c = event.data;
      if (!c || c.channel !== "stage-1") return;
      if (event.type === "create") {
        if (c.type === "call_incoming") {
          setCall({ phase: "incoming", contact: { name: c.contact_name, number: c.contact_number }, commandId: c.id });
        } else if (c.type === "call_outgoing") {
          setCall({ phase: "outgoing", contact: { name: c.contact_name, number: c.contact_number }, commandId: c.id, startTime: Date.now() });
          setTimeout(() => setCall((cur) => cur && cur.commandId === c.id ? { ...cur, phase: "active", startTime: Date.now() } : cur), 2200);
        }
      } else if (event.type === "update") {
        // control deck ended the call remotely
        if (c.status === "completed" && callRef.current && c.id === callRef.current.commandId) {
          addRecent(callRef.current);
          setCall(null);
        }
      }
    });
    return () => { mounted = false; unsub(); };
  }, []);

  // keep ref in sync with current call
  useEffect(() => { callRef.current = call; }, [call]);

  // keep the live status-bar clock fresh
  useEffect(() => {
    const t = setInterval(() => setTick((n) => n + 1), 15000);
    return () => clearInterval(t);
  }, []);

  // browser fullscreen exit (Esc) should also end the takeover
  useEffect(() => {
    const onFs = () => { if (!document.fullscreenElement) setFullscreen(false); };
    document.addEventListener("fullscreenchange", onFs);
    return () => document.removeEventListener("fullscreenchange", onFs);
  }, []);

  const exitFullscreen = useCallback(() => {
    clearTimeout(fsHintTimer.current);
    setFsHint(false);
    setFullscreen(false);
    if (document.fullscreenElement && document.exitFullscreen) {
      document.exitFullscreen().catch(() => {});
    }
  }, []);

  const toggleFullscreen = async () => {
    const next = !fullscreen;
    setFullscreen(next);
    if (next) {
      setFsHint(true);
      fsHintTimer.current = setTimeout(() => setFsHint(false), 2600);
    } else {
      clearTimeout(fsHintTimer.current);
      setFsHint(false);
    }
    try {
      if (next && !document.fullscreenElement && document.documentElement.requestFullscreen) {
        await document.documentElement.requestFullscreen();
      } else if (!next && document.fullscreenElement && document.exitFullscreen) {
        await document.exitFullscreen();
      }
    } catch {}
  };

  // clean-HUD takeover: 3-finger tap (or Esc / L) is the only way out
  useEffect(() => {
    if (!fullscreen) return;
    const onTouch = (e) => { if (e.touches.length >= 3) exitFullscreen(); };
    const onKey = (e) => { if (e.key === "Escape" || e.key.toLowerCase() === "l") exitFullscreen(); };
    window.addEventListener("touchstart", onTouch, { passive: true });
    window.addEventListener("keydown", onKey);
    return () => {
      window.removeEventListener("touchstart", onTouch);
      window.removeEventListener("keydown", onKey);
    };
  }, [fullscreen, exitFullscreen]);

  const statusTime = config.clock.mode === "custom" && config.clock.time
    ? config.clock.time
    : fmtTime(Date.now());
  const onStatusChange = (patch) => update({ status: { ...config.status, ...patch } });

  const endCall = useCallback(() => {
    setCall((cur) => {
      if (cur) {
        addRecent(cur);
        if (cur.commandId) {
          base44.entities.Command.update(cur.commandId, { status: "completed" }).catch(() => {});
        }
      }
      return null;
    });
  }, []);

  const acceptCall = useCallback(() => {
    setCall((cur) => {
      if (cur?.commandId) base44.entities.Command.update(cur.commandId, { status: "active" }).catch(() => {});
      return { ...cur, phase: "active", startTime: Date.now() };
    });
  }, []);

  const startLocalCall = (contact) => {
    setCall({ phase: "active", contact, startTime: Date.now(), commandId: null });
  };

  const renderApp = () => {
    switch (app) {
      case "phone": return <PhoneApp onCall={startLocalCall} recents={recents} />;
      case "contacts": return <ContactsApp onCall={startLocalCall} />;
      case "messages": return <MessagesApp />;
      case "email": return <EmailApp />;
      case "clock": return <ClockApp />;
      case "settings": return <SettingsApp config={config} update={update} onLock={() => setLocked(true)} />;
      case null: return <Homescreen onOpen={setApp} config={config} update={update} />;
      default: return <MockApp app={allAppsById[app]} />;
    }
  };

  const screen = locked
    ? <LockScreen config={config} update={update} onUnlock={() => setLocked(false)} />
    : renderApp();

  return (
    <div className="min-h-dvh bg-background grid-backdrop flex flex-col">
      <header className="flex items-center justify-between px-6 py-4 border-b border-border">
        <Link to="/" className="flex items-center gap-2 text-muted-foreground hover:text-foreground text-sm font-body">
          <ArrowLeft size={18} /> Deck
        </Link>
        <div className="font-display font-bold text-lg tracking-wide">OS SIMULATOR</div>
        <div className="flex items-center gap-3">
          <button onClick={toggleFullscreen}
            className="flex items-center gap-1.5 rounded-lg border border-border px-2.5 py-1.5 text-xs font-body text-muted-foreground hover:text-foreground hover:border-muted-foreground transition">
            <Maximize2 size={14} /> <span className="hidden sm:inline">Fullscreen</span>
          </button>
          <div className="flex items-center gap-2 text-xs font-body text-signal">
            <span className="h-2 w-2 rounded-full bg-signal led-pulse" /> SYNC LIVE
          </div>
        </div>
      </header>
      <div className="flex-1 flex items-center justify-center p-6">
        <PhoneFrame onHome={() => setApp(null)} light={app === null && config.theme === "light"}
          time={statusTime} status={config.status} onStatusChange={onStatusChange}>
          {screen}
          <CallOverlay call={call} onAccept={acceptCall} onEnd={endCall} />
        </PhoneFrame>
      </div>
      {fullscreen && (
        <div className="fixed inset-0 z-50 bg-black">
          {fsHint && (
            <div className="absolute inset-x-0 bottom-5 z-50 flex justify-center pointer-events-none">
              <div className="px-4 py-1.5 rounded-full text-[11px] font-body text-white/70 bg-white/10 backdrop-blur">
                3-Finger Tap to Exit
              </div>
            </div>
          )}
          <PhoneFrame bare onHome={() => setApp(null)}
            light={app === null && config.theme === "light"}
            time={statusTime} status={config.status} onStatusChange={onStatusChange}>
            {screen}
            <CallOverlay call={call} onAccept={acceptCall} onEnd={endCall} />
          </PhoneFrame>
        </div>
      )}
      <footer className="px-6 py-3 text-center text-[11px] text-muted-foreground font-body border-t border-border">
        Mock device · channel stage-1 · control deck can drive calls & messages
      </footer>
    </div>
  );
}