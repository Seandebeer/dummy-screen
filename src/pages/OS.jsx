import React, { useState, useEffect, useCallback, useRef } from "react";
import { Link } from "react-router-dom";
import { ArrowLeft, Check, Maximize2, Save, Shapes } from "lucide-react";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import PhoneFrame from "@/components/os/PhoneFrame";
import Homescreen from "@/components/os/Homescreen";
import PhoneApp from "@/components/os/apps/PhoneApp";
import ContactsApp from "@/components/os/apps/ContactsApp";
import MessagesApp from "@/components/os/apps/MessagesApp";
import EmailApp from "@/components/os/apps/EmailApp";
import ClockApp from "@/components/os/apps/ClockApp";
import CalculatorApp from "@/components/os/apps/CalculatorApp";
import CalendarApp from "@/components/os/apps/CalendarApp";
import NotesApp from "@/components/os/apps/NotesApp";
import CameraApp from "@/components/os/apps/CameraApp";
import CallOverlay from "@/components/os/CallOverlay";
import AlarmOverlay from "@/components/os/AlarmOverlay";
import MockApp from "@/components/os/apps/MockApp";
import MusicApp from "@/components/os/apps/MusicApp";
import MapsApp from "@/components/os/apps/MapsApp";
import { allAppsById } from "@/lib/osApps";
import VideoMarks, { MARK_COLORS, MARK_STYLES } from "@/components/os/apps/video/VideoMarks";
import MarkAdjust from "@/components/os/MarkAdjust";
import NotificationBanner from "@/components/os/NotificationBanner";
import { cn } from "@/lib/utils";
import useOsConfig from "@/hooks/useOsConfig";
import { ensureDeviceOnline, saveDevice } from "@/lib/deviceLink";
import { slimConfig } from "@/lib/osConfigStore";
import LockScreen from "@/components/os/LockScreen";
import WpTileHome from "@/components/os/WpTileHome";
import Bb10Home from "@/components/os/Bb10Home";
import SettingsApp from "@/components/os/apps/SettingsApp";
import AppStoreApp from "@/components/os/apps/AppStoreApp";
import { skinUi } from "@/lib/osSkins";
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
  const [alarm, setAlarm] = useState(null);
  const [banner, setBanner] = useState(null);
  const [messageTo, setMessageTo] = useState(null);
  const [emailTo, setEmailTo] = useState(null);
  const callRef = useRef(null);
  const alarmRef = useRef(null);
  const fmtTime = (d) => new Date(d).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });

  const lockedRef = useRef(locked);
  const contactsRef = useRef(config.contacts);
  const bannerTimer = useRef(null);
  useEffect(() => { lockedRef.current = locked; }, [locked]);
  useEffect(() => { contactsRef.current = config.contacts; }, [config.contacts]);

  // drop-down banner for new notifications while the phone is unlocked
  const showBanner = useCallback((notif) => {
    setBanner(notif);
    clearTimeout(bannerTimer.current);
    bannerTimer.current = setTimeout(() => setBanner(null), 6000);
  }, []);

  // persistent call history - names resolve from the contact book by number
  const logCall = useCallback((entry) => {
    const known = (contactsRef.current || []).find((k) => k.number && k.number === entry.number);
    const name = (known && known.name) || entry.name || entry.number || "Unknown";
    const notif = entry.type === "missed"
      ? { id: `missed-${Date.now()}`, app: "phone", title: name, body: "Missed call", time: entry.time || fmtTime(Date.now()) }
      : null;
    update((c) => ({
      callLog: [{ ...entry, name }, ...(c.callLog || [])].slice(0, 100),
      ...(notif && {
        notifications: [notif, ...(c.notifications || [])].slice(0, 5),
        badges: { ...(c.badges || {}), phone: Math.min(1000000, ((c.badges || {}).phone || 0) + 1) },
      }),
    }));
    if (notif && !lockedRef.current) showBanner(notif);
  }, []);

  const callType = (cur) =>
    cur.phase === "incoming" ? "missed" : (cur.direction === "in" ? "incoming" : "outgoing");

  // load + subscribe to commands (control-driven calls)
  useEffect(() => {
    let mounted = true;
    base44.entities.Command.filter({ channel: "stage-1" }, "-created_date", 50)
      .then((data) => {
        if (!mounted) return;
        update((c) => {
          if (c.callLog?.length) return {};
          const past = data.filter((x) => x.status === "completed" && x.type.startsWith("call_")).map((x) => ({
            name: x.contact_name || "",
            number: x.contact_number || "",
            type: x.type === "call_incoming" ? "incoming" : "outgoing",
            time: fmtTime(x.created_date),
          }));
          return past.length ? { callLog: past } : {};
        });
      }).catch(() => {});

    const unsub = base44.entities.Command.subscribe((event) => {
      const c = event.data;
      if (!c || c.channel !== "stage-1") return;
      if (event.type === "create") {
        if (c.type === "call_incoming") {
          setCall({ phase: "incoming", direction: "in", contact: { name: c.contact_name, number: c.contact_number, image: c.contact_image }, commandId: c.id });
        } else if (c.type === "call_outgoing") {
          setCall({ phase: "outgoing", direction: "out", contact: { name: c.contact_name, number: c.contact_number, image: c.contact_image }, commandId: c.id, startTime: Date.now() });
          setTimeout(() => setCall((cur) => cur && cur.commandId === c.id ? { ...cur, phase: "active", startTime: Date.now() } : cur), 2200);
        } else if (c.type === "alarm") {
          setAlarm({ commandId: c.id });
        }
      } else if (event.type === "update") {
        // control deck ended the call remotely
        if (c.status === "completed" && callRef.current && c.id === callRef.current.commandId) {
          const cur = callRef.current;
          logCall({ name: cur.contact?.name, number: cur.contact?.number || "", type: callType(cur), time: fmtTime(Date.now()) });
          setCall(null);
        }
        if (c.status === "completed" && alarmRef.current && c.id === alarmRef.current.commandId) {
          setAlarm(null);
        }
      }
    });
    return () => { mounted = false; unsub(); };
  }, []);

  // control-deck messages: unread badge + lock-screen / banner notification
  useEffect(() => {
    const unsub = base44.entities.Message.subscribe((event) => {
      if (event.type !== "create") return;
      const m = event.data;
      if (!m || m.sender === "phone") return;
      const contact = (contactsRef.current || []).find((x) => String(x.id) === String(m.thread_id));
      const title = m.thread_id === "stage-1"
        ? (m.sender_name && m.sender_name !== "Control" ? m.sender_name : "Control Deck")
        : (contact?.name || m.sender_name || m.thread_id || "New message");
      const notif = { id: m.id, app: "messages", title, body: m.text || "", threadId: m.thread_id, time: fmtTime(Date.now()) };
      update((c) => ({
        notifications: [notif, ...(c.notifications || [])].slice(0, 5),
        badges: { ...(c.badges || {}), messages: Math.min(1000000, ((c.badges || {}).messages || 0) + 1) },
      }));
      if (!lockedRef.current) showBanner(notif);
    });
    return unsub;
  }, []);

  // keep refs in sync with current call / alarm
  useEffect(() => { callRef.current = call; }, [call]);
  useEffect(() => { alarmRef.current = alarm; }, [alarm]);

  // keep the live status-bar clock fresh
  useEffect(() => {
    const t = setInterval(() => setTick((n) => n + 1), 15000);
    return () => clearInterval(t);
  }, []);

  // opened via QR (?connect=1): register this screen as an online,
  // remotely-controllable device
  useEffect(() => {
    ensureDeviceOnline(new URLSearchParams(window.location.search).get("connect") === "1");
  }, []);

  // clear cross-app compose targets once the user leaves the app
  useEffect(() => { if (app !== "messages" && messageTo) setMessageTo(null); }, [app]);
  useEffect(() => { if (app !== "email" && emailTo) setEmailTo(null); }, [app]);

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

  // save this screen's OS layout as a character's device (appears in Devices)
  const saveAsDevice = async () => {
    const fallback = localStorage.getItem("takeover-device-name") || "Character's phone";
    const name = window.prompt("Save as character's device - name:", fallback);
    if (!name || !name.trim()) return;
    await saveDevice(name.trim(), slimConfig(config));
  };

  const statusTime = config.clock.mode === "custom" && config.clock.time
    ? config.clock.time
    : fmtTime(Date.now());
  const onStatusChange = (patch) => update({ status: { ...config.status, ...patch } });

  // tracking-mark overlay for the OS screen - works like the video / UI marks
  const osMarks = config.osMarks || { style: "none", layouts: {} };
  const setOsMarks = (updater) => update((c) => ({
    osMarks: updater(c.osMarks || { style: "none", layouts: {} }),
  }));

  const endCall = useCallback(() => {
    const cur = callRef.current;
    if (cur) {
      logCall({ name: cur.contact?.name, number: cur.contact?.number || "", type: callType(cur), time: fmtTime(Date.now()) });
      if (cur.commandId) {
        base44.entities.Command.update(cur.commandId, { status: "completed" }).catch(() => {});
      }
    }
    setCall(null);
  }, [logCall]);

  const stopAlarm = useCallback(() => {
    const cur = alarmRef.current;
    if (cur?.commandId) {
      base44.entities.Command.update(cur.commandId, { status: "completed" }).catch(() => {});
    }
    setAlarm(null);
  }, []);

  const acceptCall = useCallback(() => {
    setCall((cur) => {
      if (cur?.commandId) base44.entities.Command.update(cur.commandId, { status: "active" }).catch(() => {});
      return { ...cur, phase: "active", startTime: Date.now() };
    });
  }, []);

  const startLocalCall = (contact) => {
    setCall({ phase: "active", direction: "out", contact, startTime: Date.now(), commandId: null });
  };

  // opening a notification unlocks and jumps straight to the thread / app
  const openNotification = useCallback((n) => {
    setBanner(null);
    setLocked(false);
    update((c) => (c.notifications?.length ? { notifications: [] } : {}));
    if (n?.app === "phone") setApp("phone");
    else if (n?.app === "mail") setApp("email");
    else {
      if (n?.threadId) setMessageTo({ id: String(n.threadId), name: n.title });
      setApp("messages");
    }
  }, []);

  // unlocking clears the lock-screen notification list
  const handleUnlock = useCallback(() => {
    setLocked(false);
    update((c) => (c.notifications?.length ? { notifications: [] } : {}));
  }, []);

  const renderApp = () => {
    switch (app) {
      case "phone": return <PhoneApp onCall={startLocalCall} recents={config.callLog || []} language={config.language} />;
      case "contacts": return (
        <ContactsApp contacts={config.contacts} dialCode={config.dialCode} language={config.language} update={update}
          onCall={startLocalCall}
          onMessage={(c) => { setMessageTo(c); setApp("messages"); }}
          onEmail={(c) => { setEmailTo(c); setApp("email"); }} />
      );
      case "messages": return <MessagesApp key={messageTo?.id || "list"} contacts={config.contacts} initialTo={messageTo} theme={config.theme} />;
      case "email": return <EmailApp initialTo={emailTo} />;
      case "clock": return <ClockApp />;
      case "calculator": return <CalculatorApp />;
      case "calendar": return <CalendarApp />;
      case "notes": return <NotesApp />;
      case "camera": return <CameraApp />;
      case "music": return <MusicApp />;
      case "maps": return <MapsApp />;
      case "settings": return <SettingsApp config={config} update={update} onLock={() => setLocked(true)} />;
      case "appstore": return <AppStoreApp config={config} update={update} />;
      case null: {
        const ui = skinUi(config.skin);
        if (ui.layout === "tiles") return <WpTileHome config={config} update={update} onOpen={setApp} ui={ui} />;
        if (ui.layout === "bb") return <Bb10Home config={config} update={update} onOpen={setApp} ui={ui} />;
        return <Homescreen onOpen={setApp} config={config} update={update} />;
      }
      default: return <MockApp app={allAppsById[app]} />;
    }
  };

  const rtl = config.language === "ar";
  const screen = locked
    ? <div className="absolute inset-0" dir={rtl ? "rtl" : "ltr"}><LockScreen config={config} update={update} onUnlock={handleUnlock} notifications={config.notifications || []} onOpenNotification={openNotification} /></div>
    : app === null
      ? renderApp()
      : <div className="absolute inset-0 pt-9" dir={rtl ? "rtl" : "ltr"}>{renderApp()}</div>;

  return (
    <div className="min-h-dvh bg-background grid-backdrop flex flex-col">
      <header className="flex items-center justify-between px-6 py-4 border-b border-border/60 bg-surface/30 backdrop-blur-xl">
        <Link to="/" className="flex items-center gap-2 text-muted-foreground hover:text-foreground text-sm font-body">
          <ArrowLeft size={18} /> Back
        </Link>
        <div className="font-display font-semibold text-[17px] tracking-[-0.01em]">OS Simulator</div>
        <div className="flex items-center gap-3">
          <Popover>
            <PopoverTrigger asChild>
              <button className={cn("flex items-center gap-1.5 rounded-lg border px-2.5 py-1.5 text-xs font-body transition",
                osMarks.style !== "none" ? "border-amber/50 text-amber" : "border-border text-muted-foreground hover:text-foreground hover:border-muted-foreground")}>
                <Shapes size={14} /> <span className="hidden sm:inline">Marks</span>
              </button>
            </PopoverTrigger>
            <PopoverContent align="end" className="w-44 p-1.5">
              <button onClick={() => setOsMarks((m) => ({ ...m, style: "none" }))}
                className="flex w-full items-center justify-between rounded-lg px-2.5 py-1.5 text-[10px] font-body uppercase tracking-wider hover:bg-muted">
                None
                {osMarks.style === "none" && <Check size={12} className="text-amber" />}
              </button>
              {MARK_STYLES.map((s) => (
                <button key={s.id} onClick={() => setOsMarks((m) => ({ ...m, style: s.id }))}
                  className="flex w-full items-center justify-between rounded-lg px-2.5 py-1.5 text-[10px] font-body uppercase tracking-wider hover:bg-muted">
                  {s.label}
                  {osMarks.style === s.id && <Check size={12} className="text-amber" />}
                </button>
              ))}
              <div className="mt-1 flex flex-wrap items-center gap-1.5 border-t border-border px-2 pt-1.5">
                {MARK_COLORS.map((c) => (
                  <button key={c} onClick={() => setOsMarks((m) => ({ ...m, color: c }))}
                    className={cn("h-4 w-4 rounded-full border transition", osMarks.color === c ? "border-amber ring-2 ring-amber/60" : "border-border")}
                    style={{ background: c }} aria-label={`Mark colour ${c}`} />
                ))}
                <button onClick={() => setOsMarks((m) => ({ ...m, color: null }))}
                  className={cn("rounded-md border px-1 py-0.5 text-[8px] font-body uppercase tracking-wider transition",
                    !osMarks.color ? "border-amber text-amber" : "border-border text-muted-foreground hover:text-foreground")}>
                  Auto
                </button>
              </div>
              <MarkAdjust size={osMarks.size} thickness={osMarks.thickness} rot={osMarks.rot}
                onChange={(p) => setOsMarks((m) => ({ ...m, ...p }))} />
              <p className="px-2.5 pt-1.5 text-[8px] font-body text-muted-foreground">Hold &amp; drag to move · tap to rotate · double-tap to delete</p>
            </PopoverContent>
          </Popover>
          <button onClick={saveAsDevice}
            className="flex items-center gap-1.5 rounded-lg border border-border px-2.5 py-1.5 text-xs font-body text-muted-foreground hover:text-foreground hover:border-muted-foreground transition">
            <Save size={14} /> <span className="hidden sm:inline">Save as Device</span>
          </button>
          <button onClick={toggleFullscreen}
            className="flex items-center gap-1.5 rounded-lg border border-border px-2.5 py-1.5 text-xs font-body text-muted-foreground hover:text-foreground hover:border-muted-foreground transition">
            <Maximize2 size={14} /> <span className="hidden sm:inline">Fullscreen</span>
          </button>
        </div>
      </header>
      <div className="flex-1 flex items-center justify-center p-6">
        <PhoneFrame className="os-sf" onHome={() => setApp(null)} skin={config.skin || "modern"} light={(app === null || app === "messages") && config.theme === "light"}
          time={statusTime} status={config.status} onStatusChange={onStatusChange}>
          {screen}
          <VideoMarks marks={osMarks} onChange={setOsMarks} locked={locked}
            color={osMarks.color || (config.theme === "light" ? "#000000" : "#FFFFFF")} />
          <CallOverlay call={call} onAccept={acceptCall} onEnd={endCall} answerMode={config.callAnswer} />
          {alarm && <AlarmOverlay onDismiss={stopAlarm} />}
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
          <PhoneFrame bare className="os-sf" onHome={() => setApp(null)} skin={config.skin || "modern"}
            light={(app === null || app === "messages") && config.theme === "light"}
            time={statusTime} status={config.status} onStatusChange={onStatusChange}>
            {screen}
            <VideoMarks marks={osMarks} onChange={setOsMarks} locked={locked}
              color={osMarks.color || (config.theme === "light" ? "#000000" : "#FFFFFF")} />
            {banner && !locked && (
              <NotificationBanner notif={banner} light={config.theme === "light"}
                onOpen={openNotification} onDismiss={() => setBanner(null)} />
            )}
            <CallOverlay call={call} onAccept={acceptCall} onEnd={endCall} answerMode={config.callAnswer} />
            {alarm && <AlarmOverlay onDismiss={stopAlarm} />}
          </PhoneFrame>
        </div>
      )}
      <footer className="px-6 py-3 text-center text-[11px] text-muted-foreground font-body border-t border-border/60">
        Mock device · channel stage-1 · control deck can drive calls & messages
      </footer>
    </div>
  );
}