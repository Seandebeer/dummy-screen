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
import VideoCallApp from "@/components/os/apps/VideoCallApp";
import CallOverlay from "@/components/os/CallOverlay";
import AlarmOverlay from "@/components/os/AlarmOverlay";
import MockApp from "@/components/os/apps/MockApp";
import MusicApp from "@/components/os/apps/MusicApp";
import MapsApp from "@/components/os/apps/MapsApp";
import FacepageApp from "@/components/os/apps/social/FacepageApp";
import PhotogramApp from "@/components/os/apps/social/PhotogramApp";
import VidTubeApp from "@/components/os/apps/social/VidTubeApp";
import QuickTokApp from "@/components/os/apps/social/QuickTokApp";
import BrowserApp from "@/components/os/apps/BrowserApp";
import WebdeckApp from "@/components/os/apps/WebdeckApp";
import NewsApp from "@/components/os/apps/NewsApp";
import PropertyApp from "@/components/os/apps/PropertyApp";
import FitnessApp from "@/components/os/apps/FitnessApp";
import { allAppsById } from "@/lib/osApps";
import VideoMarks, { MARK_COLORS, MARK_STYLES } from "@/components/os/apps/video/VideoMarks";
import MarkAdjust from "@/components/os/MarkAdjust";
import ThreeFingerHint from "@/components/os/ThreeFingerHint";
import NotificationBanner from "@/components/os/NotificationBanner";
import { cn } from "@/lib/utils";
import useOsConfig from "@/hooks/useOsConfig";
import { ensureDeviceOnline, getDeviceName, getLinkedDeviceId, getScreenId } from "@/lib/deviceLink";
import SaveDeviceSheet from "@/components/os/SaveDeviceSheet";
import LockScreen from "@/components/os/LockScreen";
import ClockEditor from "@/components/os/ClockEditor";
import WpTileHome from "@/components/os/WpTileHome";
import Bb10Home from "@/components/os/Bb10Home";
import SettingsApp from "@/components/os/apps/SettingsApp";
import AppStoreApp from "@/components/os/apps/AppStoreApp";
import { skinUi, OS_SKINS } from "@/lib/osSkins";
import { base44 } from "@/api/base44Client";
import { startPhoneVoice } from "@/lib/voiceLink";
import { scheduleDeviceSync } from "@/lib/cloudSync";
import { logTeamCall } from "@/lib/callLog";

const parseJson = (s) => { try { return JSON.parse(s) || {}; } catch { return {}; } };

export default function OS() {
  const [app, setApp] = useState(null);
  const [locked, setLocked] = useState(true);
  const { config, update, reset } = useOsConfig();
  const [fullscreen, setFullscreen] = useState(false);
  const [fsHint, setFsHint] = useState(false);
  const fsHintTimer = useRef(null);
  const [, setTick] = useState(0);
  const [call, setCall] = useState(null);
  const [alarm, setAlarm] = useState(null);
  const [banners, setBanners] = useState([]);
  const [clockEdit, setClockEdit] = useState(false);
  const [saveOpen, setSaveOpen] = useState(false);
  const [deviceName, setDeviceName] = useState(getDeviceName);
  const [callSpeaker, setCallSpeaker] = useState(false);
  const [callMuted, setCallMuted] = useState(false);
  const [videoCall, setVideoCall] = useState(null);

  // the header names a device only once it's saved to a project - a linked
  // device with no project, or nothing linked at all, is just the sandbox
  const refreshDeviceName = useCallback(() => {
    const id = getLinkedDeviceId();
    if (!id) { setDeviceName("Sandbox"); return; }
    base44.entities.Device.get(id)
      .then((d) => setDeviceName(d?.project_id ? d.name : "Sandbox"))
      .catch(() => setDeviceName("Sandbox"));
  }, []);

  useEffect(() => { refreshDeviceName(); }, [refreshDeviceName]);
  const [ear, setEar] = useState(false);
  const voiceRef = useRef(null);
  const [messageTo, setMessageTo] = useState(null);
  const [emailTo, setEmailTo] = useState(null);
  const callRef = useRef(null);
  const alarmRef = useRef(null);
  const videoCallRef = useRef(null);
  const fmtTime = (d) => new Date(d).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });

  const lockedRef = useRef(locked);
  const contactsRef = useRef(config.contacts);
  useEffect(() => { lockedRef.current = locked; }, [locked]);
  useEffect(() => { contactsRef.current = config.contacts; }, [config.contacts]);

  // drop-down banners stack while the phone is unlocked - each one stays
  // until dismissed, a reset from the deck, or opening it
  const showBanner = useCallback((notif) => {
    setBanners((b) => [...b, notif].slice(-20));
  }, []);
  const dismissBanner = useCallback((id) => {
    setBanners((b) => b.filter((n) => n.id !== id));
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
    logTeamCall({ name, number: entry.number || "", type: entry.type });
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
      if (!c) return;
      // only broadcast commands, or ones aimed at this screen's device profile
      const own = getLinkedDeviceId();
      const ownChannel = own ? `device-${own}` : null;
      if (c.channel !== "stage-1" && c.channel !== ownChannel) return;
      // triggers pushed from this same screen (its own control deck) never echo back
      if (event.type === "create" && parseJson(c.payload).source === getScreenId()) return;
      if (event.type === "create") {
        if (c.type === "call_incoming") {
          const p = parseJson(c.payload);
          // the deck can start the phone's mic muted / speaker on
          if (typeof p.micOn === "boolean") setCallMuted(!p.micOn);
          if (typeof p.speakerOn === "boolean") setCallSpeaker(p.speakerOn);
          setCall({ phase: "incoming", direction: "in", contact: { name: c.contact_name, number: c.contact_number, image: c.contact_image }, commandId: c.id, channel: c.channel, photoMode: p.photoMode });
        } else if (c.type === "call_outgoing") {
          setCall({ phase: "outgoing", direction: "out", contact: { name: c.contact_name, number: c.contact_number, image: c.contact_image }, commandId: c.id, channel: c.channel, startTime: Date.now() });
          setTimeout(() => setCall((cur) => cur && cur.commandId === c.id ? { ...cur, phase: "active", startTime: Date.now() } : cur), ringDelayRef.current * 1000);
        } else if (c.type === "alarm") {
          setAlarm({ commandId: c.id });
        } else if (c.type === "notification") {
          // deck-pushed banners stack below each other until reset clears them
          const p = parseJson(c.payload);
          if (p.action === "reset") {
            setBanners([]);
            update((cfg) => ({ notifications: (cfg.notifications || []).filter((n) => !String(n.id).startsWith("push-")) }));
          } else {
            const notif = {
              id: `push-${c.id}`,
              app: p.app || "messages",
              title: allAppsById[p.app]?.label || "Notification",
              body: p.body || "",
              time: fmtTime(Date.now()),
            };
            if (p.screen === "home") {
              if (!lockedRef.current) showBanner(notif);
            } else {
              update((cfg) => ({ notifications: [notif, ...(cfg.notifications || [])].slice(0, 20) }));
            }
          }
        } else if (c.type === "video_call") {
          // a control-deck video call opens the app and rings until answered
          setLocked(false);
          setApp("videocall");
          setVideoCall({
            id: c.id,
            contact: { name: c.contact_name, number: c.contact_number, image: c.contact_image },
            payload: parseJson(c.payload),
            channel: c.channel,
          });
        }
      } else if (event.type === "update") {
        if (callRef.current && c.id === callRef.current.commandId) {
          if (c.status === "completed") {
            // control deck ended the call remotely
            const cur = callRef.current;
            logCall({ name: cur.contact?.name, number: cur.contact?.number || "", type: callType(cur), time: fmtTime(Date.now()) });
            setCall(null);
          } else {
            // mid-call: the deck toggled the phone's mic / speaker
            const p = parseJson(c.payload);
            if (typeof p.micOn === "boolean") setCallMuted(!p.micOn);
            if (typeof p.speakerOn === "boolean") setCallSpeaker(p.speakerOn);
          }
        }
        if (c.status === "completed" && alarmRef.current && c.id === alarmRef.current.commandId) {
          setAlarm(null);
        }
        // video call: apply mid-call content / toggle changes, or hang up
        if (c.type === "video_call" && videoCallRef.current?.id === c.id) {
          if (c.status === "completed") setVideoCall(null);
          else setVideoCall((cur) => (cur ? { ...cur, payload: parseJson(c.payload) } : cur));
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
      // pushed from this same screen, or aimed at another device - not for us
      if (m.source && m.source === getScreenId()) return;
      const own = getLinkedDeviceId();
      const ownChannel = own ? `device-${own}` : null;
      if (m.thread_id !== "stage-1" && m.thread_id !== ownChannel) return;
      const contact = (contactsRef.current || []).find((x) => String(x.id) === String(m.thread_id));
      const title = (m.thread_id === "stage-1" || m.thread_id === ownChannel)
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
  useEffect(() => { videoCallRef.current = videoCall; }, [videoCall]);

  // a new call always starts off speakerphone, with the mic live
  useEffect(() => { if (!call) { setCallSpeaker(false); setCallMuted(false); } }, [call]);

  // how long the other side rings before picking up (1-60s, from Settings)
  const ringDelayRef = useRef(4);
  useEffect(() => {
    ringDelayRef.current = Math.min(60, Math.max(1, Number(config.ringDelay) || 4));
  }, [config.ringDelay]);

  // live voice: a control-driven call pipes the operator's mic into this device
  useEffect(() => {
    if (call?.phase === "active" && call?.commandId && !voiceRef.current) {
      voiceRef.current = startPhoneVoice(call.commandId, call.channel || "stage-1");
    }
    if (!call && voiceRef.current) {
      voiceRef.current.stop();
      voiceRef.current = null;
    }
  }, [call?.phase, call?.commandId]);

  // ear proximity: during a live non-speaker call the screen sleeps like a
  // phone held to the ear - the tilt sensor wakes it when it comes back down,
  // and without sensors the screen sleeps 3 seconds in (tap to wake)
  useEffect(() => {
    if (!call || call.phase !== "active" || callSpeaker) { setEar(false); return; }
    let engaged = false;
    let sensor = false;
    const engage = () => { engaged = true; setEar(true); };
    const wake = () => { if (engaged) { engaged = false; setEar(false); } };
    // real proximity sensor, when the browser exposes one
    const onProx = (e) => {
      sensor = true;
      if (e.value < 5) engage();
      else if (e.value > 8) wake();
    };
    if (typeof window.DeviceProximityEvent !== "undefined") {
      window.addEventListener("deviceproximity", onProx);
    }
    // lift-to-ear: the top of the phone tilted steeply up = at the ear
    const onOrient = (e) => {
      if (e.beta == null) return;
      sensor = true;
      if (e.beta > 75) engage();
      else if (e.beta < 60) wake();
    };
    window.addEventListener("deviceorientation", onOrient);
    // fallback: no sensors available, sleep the screen 3s into the call
    const timer = setTimeout(() => { if (!sensor) engage(); }, 3000);
    return () => {
      clearTimeout(timer);
      window.removeEventListener("deviceorientation", onOrient);
      if (typeof window.DeviceProximityEvent !== "undefined") {
        window.removeEventListener("deviceproximity", onProx);
      }
    };
  }, [call?.phase, call?.commandId, call?.startTime, callSpeaker]);

  // keep the live status-bar clock fresh
  useEffect(() => {
    const t = setInterval(() => setTick((n) => n + 1), 15000);
    return () => clearInterval(t);
  }, []);

  // every OS change (contacts, settings, pages, social content) syncs to the
  // shared cloud library for the team - debounced, queued while offline
  useEffect(() => { scheduleDeviceSync(); }, [config]);

  // opened via QR (?connect=1): bring the linked device record online -
  // a sandbox screen (nothing saved yet) stays unregistered
  useEffect(() => {
    ensureDeviceOnline();
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

  // save this screen's OS layout - to the current device, the Saved card
  // (favourites) or a new device inside a project
  const saveAsDevice = () => setSaveOpen(true);

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
    // iOS needs a user gesture to allow the lift-to-ear tilt sensor
    if (typeof DeviceOrientationEvent !== "undefined" && typeof DeviceOrientationEvent.requestPermission === "function") {
      DeviceOrientationEvent.requestPermission().catch(() => {});
    }
    setCall((cur) => {
      if (cur?.commandId) base44.entities.Command.update(cur.commandId, { status: "active" }).catch(() => {});
      return { ...cur, phase: "active", startTime: Date.now() };
    });
  }, []);

  // dialling from this phone: the other side rings first, then picks up
  const startLocalCall = (contact) => {
    setCall({ phase: "ringing", direction: "out", contact, commandId: null });
    setTimeout(() => {
      setCall((cur) => cur && cur.phase === "ringing" && cur.direction === "out" && cur.contact?.number === contact.number
        ? { ...cur, phase: "active", startTime: Date.now() }
        : cur);
    }, ringDelayRef.current * 1000);
  };

  // opening a notification unlocks and jumps straight to the thread / app
  const openNotification = useCallback((n) => {
    setBanners([]);
    setLocked(false);
    update((c) => (c.notifications?.length ? { notifications: [] } : {}));
    if (n?.app === "phone") setApp("phone");
    else if (n?.app === "mail") setApp("email");
    else if (n?.app && !n.threadId && allAppsById[n.app]) setApp(n.app);
    else {
      if (n?.threadId) setMessageTo({ id: String(n.threadId), name: n.title });
      setApp("messages");
    }
  }, []);

  // actor ended a control-triggered video call from the phone side
  const endVideoCall = useCallback(() => {
    const cur = videoCallRef.current;
    if (cur) base44.entities.Command.update(cur.id, { status: "completed" }).catch(() => {});
    setVideoCall(null);
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
      case "videocall": return <VideoCallApp config={config} update={update} remote={videoCall} onRemoteEnd={endVideoCall} />;
      case "music": return <MusicApp />;
      case "maps": return <MapsApp />;
      case "facepage": return <FacepageApp config={config} update={update} locked={locked} fullscreen={fullscreen} />;
      case "photogram": return <PhotogramApp config={config} update={update} locked={locked} fullscreen={fullscreen} />;
      case "vidtube": return <VidTubeApp config={config} update={update} locked={locked} fullscreen={fullscreen} />;
      case "quicktok": return <QuickTokApp config={config} update={update} locked={locked} fullscreen={fullscreen} />;
      case "browser": return <BrowserApp />;
      case "webdeck": return <WebdeckApp config={config} update={update} locked={locked} fullscreen={fullscreen} />;
      case "news": return <NewsApp config={config} update={update} locked={locked} fullscreen={fullscreen} />;
      case "property": return <PropertyApp config={config} update={update} locked={locked} fullscreen={fullscreen} />;
      case "fitness": return <FitnessApp />;
      case "settings": return <SettingsApp config={config} update={update} onLock={() => setLocked(true)} reset={reset} />;
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
  const skinName = OS_SKINS.find((s) => s.id === (config.skin || "modern"))?.name || "Modern";
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
        <div className="text-center min-w-0">
          <div className="font-display font-semibold text-[17px] tracking-[-0.01em] leading-tight truncate max-w-[180px] sm:max-w-[240px]">{deviceName}</div>
          <div className="text-[10px] text-muted-foreground font-body uppercase tracking-wider">
            {skinName} · {config.theme === "light" ? "Light" : "Dark"} theme
          </div>
        </div>
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
            <Save size={14} /> <span className="hidden sm:inline">Save</span>
          </button>
          <button onClick={toggleFullscreen}
            className="flex items-center gap-1.5 rounded-lg border border-border px-2.5 py-1.5 text-xs font-body text-muted-foreground hover:text-foreground hover:border-muted-foreground transition">
            <Maximize2 size={14} /> <span className="hidden sm:inline">Fullscreen</span>
          </button>
        </div>
      </header>
      <div className="flex-1 flex items-center justify-center p-6">
        <PhoneFrame className="os-sf" onHome={() => setApp(null)} onTime={() => setClockEdit(true)} skin={config.skin || "modern"} light={((app === null || app === "messages") && config.theme === "light") || app === "facepage" || app === "photogram" || app === "vidtube" || app === "browser" || app === "webdeck"}
          time={statusTime} status={config.status} onStatusChange={onStatusChange}>
          {screen}
          <VideoMarks marks={osMarks} onChange={setOsMarks} locked={locked}
            color={osMarks.color || (config.theme === "light" ? "#000000" : "#FFFFFF")} />
          {clockEdit && (
            <div className="absolute inset-x-3 top-10 z-40">
              <ClockEditor clock={config.clock} onSave={(c) => { update({ clock: c }); setClockEdit(false); }} onClose={() => setClockEdit(false)} />
            </div>
          )}
          <CallOverlay call={call} onAccept={acceptCall} onEnd={endCall} answerMode={config.callAnswer} speaker={callSpeaker} onSpeakerChange={setCallSpeaker} muted={callMuted} onMutedChange={setCallMuted} />
          {ear && call?.phase === "active" && (
            <div className="absolute inset-0 z-[60] bg-black" onClick={() => setEar(false)} aria-label="Screen off - tap to wake" />
          )}
          {alarm && <AlarmOverlay onDismiss={stopAlarm} />}
          {banners.length > 0 && !locked && (
            <div className="absolute top-2 inset-x-2 z-30 flex flex-col gap-1.5">
              {banners.map((n) => (
                <NotificationBanner key={n.id} notif={n} light={config.theme === "light"}
                  onOpen={openNotification} onDismiss={() => dismissBanner(n.id)} />
              ))}
            </div>
          )}
        </PhoneFrame>
      </div>
      {saveOpen && (
        <SaveDeviceSheet config={config} onClose={() => setSaveOpen(false)}
          onSaved={refreshDeviceName} />
      )}
      {fullscreen && (
        <div className="fixed inset-0 z-50 bg-black">
          {fsHint && <ThreeFingerHint />}
          <PhoneFrame bare className="os-sf" onHome={() => setApp(null)} onTime={() => setClockEdit(true)} skin={config.skin || "modern"}
            light={((app === null || app === "messages") && config.theme === "light") || app === "facepage" || app === "photogram" || app === "vidtube" || app === "browser" || app === "webdeck"}
            time={statusTime} status={config.status} onStatusChange={onStatusChange}>
            {screen}
            <VideoMarks marks={osMarks} onChange={setOsMarks} locked={locked}
              color={osMarks.color || (config.theme === "light" ? "#000000" : "#FFFFFF")} />
            {clockEdit && (
              <div className="absolute inset-x-3 top-10 z-40">
                <ClockEditor clock={config.clock} onSave={(c) => { update({ clock: c }); setClockEdit(false); }} onClose={() => setClockEdit(false)} />
              </div>
            )}
            {banners.length > 0 && !locked && (
              <div className="absolute top-2 inset-x-2 z-30 flex flex-col gap-1.5">
                {banners.map((n) => (
                  <NotificationBanner key={n.id} notif={n} light={config.theme === "light"}
                    onOpen={openNotification} onDismiss={() => dismissBanner(n.id)} />
                ))}
              </div>
            )}
            <CallOverlay call={call} onAccept={acceptCall} onEnd={endCall} answerMode={config.callAnswer} speaker={callSpeaker} onSpeakerChange={setCallSpeaker} muted={callMuted} onMutedChange={setCallMuted} />
            {ear && call?.phase === "active" && (
              <div className="absolute inset-0 z-[60] bg-black" onClick={() => setEar(false)} aria-label="Screen off - tap to wake" />
            )}
            {alarm && <AlarmOverlay onDismiss={stopAlarm} />}
          </PhoneFrame>
        </div>
      )}
      <footer className="px-6 py-3 text-center text-[11px] text-muted-foreground font-body border-t border-border/60">
        Mock device · channel {getLinkedDeviceId() ? `device-${getLinkedDeviceId()}` : "stage-1"} · control deck can drive calls & messages
      </footer>
    </div>
  );
}