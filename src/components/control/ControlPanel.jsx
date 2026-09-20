import React, { useState, useEffect, useRef } from "react";
import { PhoneIncoming, PhoneOff, Send, Radio, Users, AlarmClock, Trash2, ImagePlus, Smartphone, Mic, MicOff, Volume2, Bell, ChevronDown, Plus, GripVertical, Recycle, Clock, Check, CheckCheck, Paperclip, Play, Image as ImageIcon, MessageSquare } from "lucide-react";
import { DragDropContext, Droppable, Draggable } from "@hello-pangea/dnd";
import { base44 } from "@/api/base44Client";
import { startControlVoice } from "@/lib/voiceLink";
import { Image } from "@/components/ui/image";
import QrConnect from "@/components/control/QrConnect";
import VideoCallCard from "@/components/control/VideoCallCard";
import LockPad from "@/components/control/LockPad";
import ControlCard from "@/components/control/ControlCard";
import DeviceContactPicker from "@/components/control/DeviceContactPicker";
import { getScreenId } from "@/lib/deviceLink";
import { coreApps, mockApps, categories, allAppsById } from "@/lib/osApps";
import { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator } from "@/components/ui/dropdown-menu";
import { cn } from "@/lib/utils";

// notification picker: socials first, then the remaining functional apps.
// the mock library is tucked away in the "more apps" dropdown by category
const SOCIAL_IDS = new Set(["facepage", "photogram", "vidtube", "quicktok"]);
const notifPrimaryApps = [
  ...coreApps.filter((a) => SOCIAL_IDS.has(a.id)),
  ...coreApps.filter((a) => !SOCIAL_IDS.has(a.id)),
];

const CONTACT_KEY = "takeover-control-contact";
const BLANK = { name: "", number: "", email: "", image: "" };

const loadContact = () => {
  try {
    const s = JSON.parse(localStorage.getItem(CONTACT_KEY));
    if (s) return { ...BLANK, ...s };
  } catch {}
  return BLANK;
};

export default function ControlPanel() {
  const [messages, setMessages] = useState([]);
  const [text, setText] = useState("");
  const [callState, setCallState] = useState("idle"); // idle | ringing | active | ended
  const [activeCmdId, setActiveCmdId] = useState(null);
  const [contact, setContact] = useState(loadContact);
  const [alarmId, setAlarmId] = useState(null);
  const [busy, setBusy] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [voice, setVoice] = useState("off");
  const [pickerOpen, setPickerOpen] = useState(false);
  const [photoMode, setPhotoMode] = useState(() => {
    try { return localStorage.getItem("takeover-call-photo-mode") || "circle"; } catch { return "circle"; }
  });
  const [targetId, setTargetId] = useState(() => {
    try { return localStorage.getItem("takeover-target-device") || ""; } catch { return ""; }
  });
  const [devices, setDevices] = useState(null);
  // the operator's own mic + speaker - trigger-side only, never pushed to the
  // target phone (mic = your voice into the phone, speaker = hearing the actor)
  const [opMic, setOpMic] = useState(true);
  const [opSpeaker, setOpSpeaker] = useState(false);
  // notification banner trigger state - a queue of up to 20 pushable banners
  const [notifScreen, setNotifScreen] = useState("lock"); // lock | home
  const [notifApp, setNotifApp] = useState("messages");
  const [notifText, setNotifText] = useState("");
  const [notifQueue, setNotifQueue] = useState([]);
  // everything pushed since the last reset - Reset reloads it into the queue
  const [pushedNotifs, setPushedNotifs] = useState([]);
  // pre-loaded message replies - hit Reply to push the next one down
  const [replyQueue, setReplyQueue] = useState([]);
  const [pushedReplies, setPushedReplies] = useState([]);
  const [replyText, setReplyText] = useState("");
  // optional manual timestamp for pushed messages - blank means live time
  const [msgTime, setMsgTime] = useState("");
  const voiceRef = useRef(null);
  const scrollRef = useRef(null);

  // the operator can steer one specific prop device instead of broadcasting
  const channel = targetId ? `device-${targetId}` : "stage-1";
  const chooseTarget = (id) => {
    setTargetId(id);
    try { localStorage.setItem("takeover-target-device", id); } catch {}
  };

  // only devices still tied to an existing project are steerable - devices that
  // were deleted (or recreated by an orphaned screen save) have no live project
  useEffect(() => {
    Promise.all([
      base44.entities.Device.list("-updated_date", 100),
      base44.entities.Project.list("-updated_date", 100),
    ])
      .then(([devs, projects]) => {
        const projectIds = new Set(projects.map((p) => p.id));
        const live = devs.filter((d) => projectIds.has(d.project_id));
        setDevices(live);
        if (targetId && !live.some((d) => d.id === targetId)) {
          setTargetId("");
          try { localStorage.setItem("takeover-target-device", ""); } catch {}
        }
      })
      .catch(() => setDevices([]));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const saveContact = (patch) => setContact((c) => {
    const next = { ...c, ...patch };
    localStorage.setItem(CONTACT_KEY, JSON.stringify(next));
    return next;
  });

  const choosePhotoMode = (m) => {
    setPhotoMode(m);
    try { localStorage.setItem("takeover-call-photo-mode", m); } catch {}
  };

  // load messages + any pending alarm for the selected channel, keep live
  useEffect(() => {
    let mounted = true;
    setMessages([]);
    setReplyQueue([]);
    setPushedReplies([]);
    base44.entities.Message.filter({ thread_id: channel }, "created_date", 200)
      .then((d) => mounted && setMessages(d)).catch(() => {});
    base44.entities.Command.filter({ channel, type: "alarm", status: "pending" }, "-created_date", 1)
      .then((d) => { if (mounted && d.length) setAlarmId((a) => a || d[0].id); }).catch(() => {});
    const unsubMsgs = base44.entities.Message.subscribe((e) => {
      if (e.type === "create" && e.data?.thread_id === channel) setMessages((m) => [...m, e.data]);
      // the phone marking a thread read flips ticks to blue live
      if (e.type === "update" && e.data?.thread_id === channel) {
        setMessages((m) => m.map((x) => (x.id === e.data.id ? e.data : x)));
      }
    });
    const unsubCmds = base44.entities.Command.subscribe((e) => {
      if (e.data?.type !== "alarm" || e.data.channel !== channel) return;
      if (e.type === "create" && e.data.status === "pending") setAlarmId(e.data.id);
      if (e.type === "update" && e.data.status === "completed") setAlarmId((a) => (a === e.data.id ? null : a));
    });
    return () => { mounted = false; unsubMsgs(); unsubCmds(); };
  }, [channel]);

  // subscribe to call command status updates (reflect phone answering/ending)
  useEffect(() => {
    const unsub = base44.entities.Command.subscribe((e) => {
      if (e.type === "update" && e.data.id === activeCmdId && e.data.type?.startsWith("call_")) {
        if (e.data.status === "active") setCallState("active");
        if (e.data.status === "completed") {
          voiceRef.current?.stop();
          voiceRef.current = null;
          setVoice("off");
          setCallState("ended");
          setTimeout(() => setCallState("idle"), 1500);
          setActiveCmdId(null);
        }
      }
    });
    return () => unsub();
  }, [activeCmdId]);

  useEffect(() => {
    if (scrollRef.current) scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [messages]);

  const onPic = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setUploading(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
      saveContact({ image: file_url });
    } catch {}
    setUploading(false);
  };

  // photo / video attachments - send one straight away, or queue it as a reply
  const [mediaBusy, setMediaBusy] = useState(false);
  const sendMediaMsg = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setMediaBusy(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
      await base44.entities.Message.create({
        thread_id: channel, sender: "control",
        text: text.trim(), media: file_url,
        media_type: file.type.startsWith("video") ? "video" : "photo",
        sender_name: contact.name.trim() || "Control",
        contact_image: contact.image || "",
        ...(msgTime ? { custom_time: msgTime } : {}),
        source: getScreenId(),
      });
      setText("");
    } catch {}
    setMediaBusy(false);
  };
  const queueMediaMsg = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file || replyQueue.length >= 20) return;
    setMediaBusy(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
      setReplyQueue((q) => [...q, {
        id: `r-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
        text: replyText.trim(), media: file_url,
        media_type: file.type.startsWith("video") ? "video" : "photo",
      }]);
      setReplyText("");
    } catch {}
    setMediaBusy(false);
  };

  const triggerCall = async () => {
    if (busy || callState !== "idle" || !contact.name.trim() || !contact.number.trim()) return;
    setBusy(true);
    try {
      const rec = await base44.entities.Command.create({
        channel, type: "call_incoming",
        contact_name: contact.name.trim(), contact_number: contact.number.trim(),
        ...(contact.image ? { contact_image: contact.image } : {}),
        payload: JSON.stringify({ photoMode, source: getScreenId() }),
        status: "pending",
      });
      setActiveCmdId(rec.id);
      setCallState("ringing");
      // open the voice link - the phone picks it up when the call is answered;
      // the operator's mic / speaker carry over from the deck toggles
      voiceRef.current?.stop();
      voiceRef.current = startControlVoice(rec.id, setVoice, channel, { micOn: opMic, speakerOn: opSpeaker });
    } catch (e) {}
    setBusy(false);
  };

  // mid-call, trigger-side: mute your own voice or (un)mute hearing the
  // actor - handled locally on the deck's voice link
  const toggleOpMic = () => {
    const v = !opMic;
    setOpMic(v);
    voiceRef.current?.setMicOn(v);
  };
  const toggleOpSpeaker = () => {
    const v = !opSpeaker;
    setOpSpeaker(v);
    voiceRef.current?.setSpeakerOn(v);
  };

  const endCall = async () => {
    voiceRef.current?.stop();
    voiceRef.current = null;
    setVoice("off");
    if (activeCmdId) {
      try { await base44.entities.Command.update(activeCmdId, { status: "completed" }); } catch (e) {}
    }
    setCallState("ended");
    setTimeout(() => setCallState("idle"), 1200);
    setActiveCmdId(null);
  };

  const triggerAlarm = async () => {
    if (alarmId) return;
    try {
      const rec = await base44.entities.Command.create({ channel, type: "alarm", status: "pending" });
      setAlarmId(rec.id);
    } catch {}
  };

  const stopAlarm = async () => {
    if (!alarmId) return;
    const id = alarmId;
    setAlarmId(null);
    try { await base44.entities.Command.update(id, { status: "completed" }); } catch {}
  };

  const sendMessage = async () => {
    if (!text.trim()) return;
    const body = text.trim();
    setText("");
    try {
      await base44.entities.Message.create({
        thread_id: channel, sender: "control", text: body,
        sender_name: contact.name.trim() || "Control",
        contact_image: contact.image || "",
        ...(msgTime ? { custom_time: msgTime } : {}),
        source: getScreenId(),
      });
    } catch (e) { setText(body); }
  };

  const resetMessages = async () => {
    if (!window.confirm("Clear all messages on this channel?")) return;
    setMessages([]);
    try { await base44.entities.Message.deleteMany({ thread_id: channel }); } catch {}
    // the thread is cleared on the phone and every pushed reply loads back
    // into the queue - whatever gets pushed next becomes the next set
    setReplyQueue(pushedReplies.slice(0, 20));
    setPushedReplies([]);
  };

  const addReply = () => {
    const t = replyText.trim();
    if (!t || replyQueue.length >= 20) return;
    setReplyQueue((q) => [...q, { id: `r-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`, text: t }]);
    setReplyText("");
  };
  const sendNextReply = async () => {
    const next = replyQueue[0];
    if (!next) return;
    try {
      await base44.entities.Message.create({
        thread_id: channel, sender: "control", text: next.text,
        sender_name: contact.name.trim() || "Control",
        contact_image: contact.image || "",
        ...(next.media ? { media: next.media, media_type: next.media_type } : {}),
        ...(msgTime ? { custom_time: msgTime } : {}),
        source: getScreenId(),
      });
      setPushedReplies((p) => [...p, next]);
      setReplyQueue((q) => q.slice(1));
    } catch {}
  };
  const removeReply = (id) => setReplyQueue((q) => q.filter((r) => r.id !== id));

  const canCall = contact.name.trim() && contact.number.trim() && callState === "idle" && !busy;

  // notification queue: compose up to 20, drag to reorder, Push sends the
  // next one, Reset clears every banner on the target screen
  const addNotifToQueue = () => {
    const t = notifText.trim();
    if (!t || notifQueue.length >= 20) return;
    setNotifQueue((q) => [...q, {
      id: `q-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
      app: notifApp, screen: notifScreen, text: t,
    }]);
    setNotifText("");
  };
  const pushNextNotification = async () => {
    const next = notifQueue[0];
    if (!next) return;
    try {
      await base44.entities.Command.create({
        channel, type: "notification", status: "pending",
        payload: JSON.stringify({ screen: next.screen, app: next.app, body: next.text, source: getScreenId() }),
      });
      // remember what was pushed - Reset brings the whole set back
      setPushedNotifs((p) => [...p, next]);
      setNotifQueue((q) => q.slice(1));
    } catch {}
  };
  const resetNotifications = async () => {
    try {
      await base44.entities.Command.create({
        channel, type: "notification", status: "pending",
        payload: JSON.stringify({ action: "reset", source: getScreenId() }),
      });
      // clear the phone and reload the last pushed set into the queue -
      // whatever gets pushed next becomes the set a future Reset restores
      setNotifQueue(pushedNotifs.slice(0, 20));
      setPushedNotifs([]);
    } catch {}
  };
  const setQueueText = (id, text) => setNotifQueue((q) => q.map((n) => (n.id === id ? { ...n, text } : n)));
  const removeQueuedNotif = (id) => setNotifQueue((q) => q.filter((n) => n.id !== id));
  const onQueueDragEnd = (res) => {
    if (!res.destination || res.destination.index === res.source.index) return;
    setNotifQueue((q) => {
      const next = [...q];
      const [moved] = next.splice(res.source.index, 1);
      next.splice(res.destination.index, 0, moved);
      return next;
    });
  };

  return (
    <div className="flex flex-col gap-5 h-full">
      {/* quick connect via QR */}
      <QrConnect />

      {/* connection panel */}
      <div className="rounded-[20px] border border-white/[0.07] bg-surface/60 backdrop-blur-2xl shadow-[0_10px_32px_rgba(0,0,0,0.28)] p-5">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Radio size={16} className="text-signal" />
            <span className="font-display font-semibold text-[15px] tracking-tight">Target Device</span>
          </div>
          <span className="flex items-center gap-1.5 text-[11px] font-body text-signal">
            <span className="h-2 w-2 rounded-full bg-signal led-pulse" /> CONNECTED
          </span>
        </div>
        <div className="flex items-center gap-3 rounded-xl border border-white/[0.06] bg-white/[0.04] p-3.5">
          <div className="h-10 w-10 rounded-lg bg-amber/15 border border-amber/30 flex items-center justify-center shrink-0">
            <Users size={18} className="text-amber" />
          </div>
          <div className="flex-1 min-w-0">
            <select value={targetId} onChange={(e) => chooseTarget(e.target.value)} aria-label="Target device"
              className="w-full cursor-pointer appearance-none bg-transparent font-body text-sm font-semibold text-foreground outline-none">
              <option value="">All devices (broadcast)</option>
              {(devices || []).map((d) => <option key={d.id} value={d.id}>{d.name}</option>)}
            </select>
            <div className="text-[11px] text-muted-foreground font-body truncate">
              channel {channel} · {targetId ? "only this device's phones react" : "every connected phone reacts"}
            </div>
          </div>
          <div className="text-right">
            <div className="text-[11px] text-muted-foreground font-body">CALL STATE</div>
            <div className={cn("text-xs font-body font-semibold uppercase",
              callState === "active" && "text-signal",
              callState === "ringing" && "text-amber amber-pulse",
              callState === "ended" && "text-alert",
              callState === "idle" && "text-muted-foreground")}>
              {callState}
            </div>
          </div>
        </div>
      </div>

      {/* on-screen contact - the identity used for calls and messages */}
      <div className="rounded-[20px] border border-white/[0.07] bg-surface/60 backdrop-blur-2xl shadow-[0_10px_32px_rgba(0,0,0,0.28)] p-5">
        <div className="flex items-center justify-between mb-3">
          <div>
            <div className="text-[11px] uppercase tracking-wider text-muted-foreground font-body">On-Screen Contact</div>
            <div className="text-[10px] text-muted-foreground/80 font-body mt-0.5">Displayed on the actor's OS when calling or messaging</div>
          </div>
          {contact.image && (
            <button onClick={() => saveContact({ image: "" })}
              className="text-[10px] font-body text-muted-foreground hover:text-alert transition">
              Remove photo
            </button>
          )}
        </div>
        <div className="flex items-start gap-3 mb-3">
          <label className="relative h-16 w-16 rounded-full bg-white/[0.04] border border-white/[0.08] overflow-hidden flex items-center justify-center cursor-pointer shrink-0">
            {contact.image
              ? <Image src={contact.image} alt="" className="h-full w-full" fittingType="fill" />
              : <ImagePlus size={18} className="text-muted-foreground" />}
            {uploading && <span className="absolute inset-0 bg-black/50 flex items-center justify-center text-[9px] text-white font-body">…</span>}
            <input type="file" accept="image/*" className="hidden" onChange={onPic} />
          </label>
          <div className="flex-1 grid grid-cols-2 gap-2">
            <input value={contact.name} onChange={(e) => saveContact({ name: e.target.value })} placeholder="Name"
              className="bg-white/[0.04] border border-white/[0.08] rounded-lg px-3 py-2 text-sm font-body outline-none focus:border-amber/50" />
            <input value={contact.number} onChange={(e) => saveContact({ number: e.target.value })} placeholder="Mock number"
              className="bg-white/[0.04] border border-white/[0.08] rounded-lg px-3 py-2 text-sm font-body outline-none focus:border-amber/50" />
            <input value={contact.email} onChange={(e) => saveContact({ email: e.target.value })} placeholder="Email (optional)"
              className="col-span-2 bg-white/[0.04] border border-white/[0.08] rounded-lg px-3 py-2 text-sm font-body outline-none focus:border-amber/50" />
          </div>
        </div>
        <button onClick={() => setPickerOpen(true)}
          className="mt-3 flex items-center gap-1.5 rounded-lg border border-white/[0.08] px-2.5 py-1.5 text-[10px] font-body text-muted-foreground transition hover:border-signal/40 hover:text-foreground">
          <Smartphone size={12} /> Choose from contacts
        </button>
      </div>

      {/* call trigger */}
      <ControlCard icon={PhoneIncoming} title="Call Trigger">
        <div className="grid grid-cols-2 gap-2">
          <button onClick={triggerCall} disabled={!canCall}
            className="flex flex-col items-center gap-1.5 rounded-2xl border border-signal/30 bg-signal/10 py-3.5 text-signal disabled:opacity-40 hover:bg-signal/20 transition">
            <PhoneIncoming size={20} />
            <span className="text-[11px] font-body">Call</span>
          </button>
          <button onClick={endCall} disabled={callState === "idle"}
            className="flex flex-col items-center gap-1.5 rounded-2xl border border-alert/30 bg-alert/10 py-3.5 text-alert disabled:opacity-40 hover:bg-alert/20 transition">
            <PhoneOff size={20} />
            <span className="text-[11px] font-body">End</span>
          </button>
        </div>
        <div className="mt-2 flex items-center justify-between">
          <span className="text-[10px] font-body text-muted-foreground">Caller photo before answering</span>
          <div className="flex gap-1">
            {["circle", "full"].map((m) => (
              <button key={m} onClick={() => choosePhotoMode(m)}
                className={cn("rounded-lg border px-2 py-1 text-[10px] font-body transition",
                  photoMode === m ? "border-signal/50 bg-signal/10 text-signal" : "border-white/[0.08] text-muted-foreground")}>
                {m === "circle" ? "Circle" : "Full screen"}
              </button>
            ))}
          </div>
        </div>
        <div className="mt-2 flex flex-wrap items-center gap-2">
          <span className="text-[10px] font-body text-muted-foreground">On this deck</span>
          <button onClick={toggleOpMic}
            className={cn("flex items-center gap-1.5 rounded-lg border px-2.5 py-1.5 text-[10px] font-body transition",
              opMic ? "border-signal/40 bg-signal/10 text-signal" : "border-white/[0.08] text-muted-foreground")}>
            {opMic ? <Mic size={13} /> : <MicOff size={13} />} {opMic ? "Mic on" : "Mic off"}
          </button>
          <button onClick={toggleOpSpeaker}
            className={cn("flex items-center gap-1.5 rounded-lg border px-2.5 py-1.5 text-[10px] font-body transition",
              opSpeaker ? "border-signal/40 bg-signal/10 text-signal" : "border-white/[0.08] text-muted-foreground")}>
            <Volume2 size={13} /> {opSpeaker ? "Speaker on" : "Speaker off"}
          </button>
          <span className="text-[9px] font-body text-muted-foreground/70">your voice into the phone · hear the actor</span>
        </div>
        <div className={cn("mt-2 text-[10px] font-body",
          voice === "mic-on" ? "text-signal" : "text-muted-foreground")}>
          {voice === "mic-on"
            ? "Voice live - you're speaking through the target device"
            : voice === "mic-denied"
              ? "Mic blocked - calls run without live voice"
              : voice === "error"
                ? "Voice link failed - calls run without live voice"
                : "Allow mic access for live voice through the target device"}
        </div>
      </ControlCard>

      {/* video call trigger */}
      <VideoCallCard contact={contact} channel={channel} />

      {/* message console */}
      <ControlCard icon={MessageSquare} title="Message Push Console">
        <div ref={scrollRef} className="max-h-64 overflow-auto no-scrollbar space-y-2 mb-3 min-h-[120px]">
          {messages.length === 0 && <div className="text-center text-muted-foreground text-xs py-6 font-body">No messages. Push one to the prop phone.</div>}
          {messages.map((m) => {
            const mine = m.sender === "control";
            return (
              <div key={m.id} className={cn("flex", mine ? "justify-end" : "justify-start")}>
                <div className={cn("max-w-[80%] rounded-2xl px-3.5 py-2 text-[13px]",
                  mine ? "bg-amber/15 border border-amber/30 text-foreground" : "bg-signal/10 border border-signal/30 text-foreground")}>
                  {!mine && <div className="text-[10px] text-signal font-body mb-0.5">PHONE</div>}
                  {m.media && (
                    <div className="mb-1 flex items-center gap-1 text-[10px] font-body text-muted-foreground">
                      {m.media_type === "video" ? <Play size={11} /> : <ImageIcon size={11} />}
                      {m.media_type || "photo"}
                    </div>
                  )}
                  <div className="font-body">{m.text}</div>
                  {mine && (
                    <div className="mt-1 flex items-center justify-end">
                      {m.read
                        ? <CheckCheck size={13} className="text-primary" />
                        : <Check size={13} className="text-muted-foreground" />}
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
        {contact.name.trim() && (
          <div className="text-[10px] text-muted-foreground font-body mb-1.5">Sending as {contact.name.trim()}</div>
        )}
        <textarea value={text} onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); sendMessage(); } }}
          placeholder="Type message to push…" rows={4}
          className="w-full min-h-[96px] resize-y bg-white/[0.04] border border-white/[0.08] rounded-lg px-3 py-2 text-sm font-body outline-none focus:border-signal" />
        <div className="mt-2 flex items-center justify-between gap-2">
          <label className="flex h-9 items-center gap-1.5 rounded-lg border border-white/[0.08] bg-white/[0.04] px-2 shrink-0"
            title="Time shown on the phone - clear it for live time">
            <Clock size={12} className="text-muted-foreground shrink-0" />
            <input type="time" value={msgTime} onChange={(e) => setMsgTime(e.target.value)}
              className="w-[70px] bg-transparent text-xs font-body outline-none" />
          </label>
          <div className="flex items-center gap-2">
            <label className={cn("h-9 w-9 shrink-0 rounded-lg border border-white/[0.08] flex items-center justify-center cursor-pointer transition hover:border-signal/40",
              mediaBusy && "opacity-50")} title="Send a photo or video">
              <Paperclip size={15} className="text-muted-foreground" />
              <input type="file" accept="image/*,video/*" className="hidden" onChange={sendMediaMsg} />
            </label>
            <button onClick={sendMessage} disabled={!text.trim()}
              className="h-9 w-9 rounded-full bg-signal text-background flex items-center justify-center disabled:opacity-40 hover:brightness-110 transition">
              <Send size={16} />
            </button>
          </div>
        </div>

        {/* pre-loaded replies - a single button pushes the next one down */}
        <div className="mt-3 border-t border-border pt-2.5">
          <div className="text-[10px] font-body text-muted-foreground mb-1.5">
            Pre-loaded replies · {replyQueue.length}/20
          </div>
          <div className="flex items-center gap-2">
            <input value={replyText} onChange={(e) => setReplyText(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && addReply()}
              placeholder="Queue up a reply…" disabled={replyQueue.length >= 20}
              className="min-w-0 flex-1 bg-white/[0.04] border border-white/[0.08] rounded-lg px-3 py-2 text-sm font-body outline-none focus:border-signal disabled:opacity-50" />
            <button onClick={addReply} disabled={!replyText.trim() || replyQueue.length >= 20}
              className="flex h-9 shrink-0 items-center gap-1.5 rounded-lg border border-signal/50 bg-signal/10 px-3 text-xs font-body font-semibold text-signal disabled:opacity-40 hover:bg-signal/20 transition">
              <Plus size={13} /> Add
            </button>
          </div>
          <div className="mt-2 flex items-center justify-end gap-2">
            <button onClick={resetMessages}
              className="flex h-9 items-center gap-1.5 rounded-lg border border-white/[0.08] px-3 text-xs font-body text-muted-foreground hover:text-alert hover:border-alert/40 transition">
              <Recycle size={13} /> Reset
            </button>
            <label className={cn("flex h-9 shrink-0 items-center rounded-lg border border-white/[0.08] px-2.5 cursor-pointer transition hover:border-signal/40",
              (replyQueue.length >= 20 || mediaBusy) && "pointer-events-none opacity-40")} title="Queue a photo or video">
              <Paperclip size={13} className="text-muted-foreground" />
              <input type="file" accept="image/*,video/*" className="hidden" onChange={queueMediaMsg} />
            </label>
            <button onClick={sendNextReply} disabled={!replyQueue.length}
              className="flex h-9 shrink-0 items-center gap-1.5 rounded-lg bg-signal px-3 text-xs font-body font-semibold text-background disabled:opacity-40 hover:brightness-110 transition">
              <Send size={13} /> Send
            </button>
          </div>
          {replyQueue.length > 0 && (
            <div className="mt-2 space-y-1.5 max-h-36 overflow-y-auto no-scrollbar">
              {replyQueue.map((r, i) => (
                <div key={r.id} className="flex items-center gap-2 rounded-lg border border-white/[0.08] bg-white/[0.03] px-2 py-1.5">
                  <span className="text-[9px] font-body text-muted-foreground shrink-0">{i + 1}</span>
                  {r.media && (r.media_type === "video"
                    ? <Play size={12} className="text-muted-foreground shrink-0" />
                    : <ImageIcon size={12} className="text-muted-foreground shrink-0" />)}
                  <span className="flex-1 min-w-0 truncate text-xs font-body text-foreground">
                    {r.text || (r.media_type === "video" ? "Video" : "Photo")}
                  </span>
                  <button onClick={() => removeReply(r.id)} aria-label="Remove"
                    className="text-muted-foreground hover:text-alert shrink-0 transition">
                    <Trash2 size={12} />
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      </ControlCard>

      {/* notification banner trigger */}
      <ControlCard icon={Bell} title="Notification Banner">
        <div className="mb-2 flex items-center justify-between">
          <span className="text-[10px] font-body text-muted-foreground">Show on</span>
          <div className="flex gap-1">
            {["lock", "home"].map((s) => (
              <button key={s} onClick={() => setNotifScreen(s)}
                className={cn("rounded-lg border px-2 py-1 text-[10px] font-body transition",
                  notifScreen === s ? "border-signal/50 bg-signal/10 text-signal" : "border-white/[0.08] text-muted-foreground")}>
                {s === "lock" ? "Lock screen" : "Home screen"}
              </button>
            ))}
          </div>
        </div>
        <div className="mb-2">
          <div className="text-[10px] font-body text-muted-foreground mb-1.5">App icon</div>
          <div className="flex gap-1.5 overflow-x-auto no-scrollbar pb-1">
            {notifPrimaryApps.map((a) => (
              <button key={a.id} onClick={() => setNotifApp(a.id)} title={a.label}
                className={cn("h-9 w-9 shrink-0 rounded-lg flex items-center justify-center border transition",
                  notifApp === a.id ? "border-signal ring-1 ring-signal" : "border-white/[0.08] opacity-60 hover:opacity-100")}
                style={{ background: a.bg }}>
                {a.Icon ? <a.Icon size={16} className="text-white" /> : null}
              </button>
            ))}
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <button title="More apps"
                  className={cn("h-9 w-9 shrink-0 rounded-lg flex items-center justify-center border transition",
                    mockApps.some((a) => a.id === notifApp) ? "border-signal ring-1 ring-signal" : "border-white/[0.08] opacity-60 hover:opacity-100")}>
                  <ChevronDown size={16} className="text-muted-foreground" />
                </button>
              </DropdownMenuTrigger>
              <DropdownMenuContent className="max-h-72 overflow-y-auto w-52">
                {categories.map((cat, ci) => (
                  <div key={cat.id}>
                    {ci > 0 && <DropdownMenuSeparator />}
                    <DropdownMenuLabel className="text-[10px] font-body text-muted-foreground">{cat.name}</DropdownMenuLabel>
                    {mockApps.filter((a) => a.category === cat.id).map((a) => (
                      <DropdownMenuItem key={a.id} onClick={() => setNotifApp(a.id)}
                        className={cn("gap-2 text-xs", notifApp === a.id && "bg-accent/60")}>
                        <span className="h-5 w-5 rounded flex items-center justify-center shrink-0" style={{ background: a.bg }}>
                          {a.Icon ? <a.Icon size={12} className="text-white" /> : null}
                        </span>
                        {a.label}
                      </DropdownMenuItem>
                    ))}
                  </div>
                ))}
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
          <div className="text-[9px] font-body text-muted-foreground/70 mt-1">
            {allAppsById[notifApp]?.label || notifApp}
          </div>
        </div>
        <div>
          <textarea value={notifText} onChange={(e) => setNotifText(e.target.value)}
            onKeyDown={(e) => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); addNotifToQueue(); } }}
            placeholder="Banner text…" rows={4} disabled={notifQueue.length >= 20}
            className="w-full min-h-[96px] resize-y bg-white/[0.04] border border-white/[0.08] rounded-lg px-3 py-2 text-sm font-body outline-none focus:border-signal disabled:opacity-50" />
          <div className="mt-2 flex justify-end">
            <button onClick={addNotifToQueue} disabled={!notifText.trim() || notifQueue.length >= 20}
              className="flex h-9 items-center gap-1.5 rounded-lg border border-signal/50 bg-signal/10 px-3 text-xs font-body font-semibold text-signal disabled:opacity-40 hover:bg-signal/20 transition">
              <Plus size={13} /> Add
            </button>
          </div>
        </div>
        {notifQueue.length > 0 && (
          <div className="mt-3">
            <div className="text-[10px] font-body text-muted-foreground mb-1.5">
              Queue · {notifQueue.length}/20 · drag to reorder
            </div>
            <DragDropContext onDragEnd={onQueueDragEnd}>
              <Droppable droppableId="notif-queue">
                {(provided) => (
                  <div ref={provided.innerRef} {...provided.droppableProps}
                    className="space-y-1.5 max-h-44 overflow-y-auto no-scrollbar pr-0.5">
                    {notifQueue.map((n, i) => (
                      <Draggable key={n.id} draggableId={n.id} index={i}>
                        {(p) => (
                          <div ref={p.innerRef} {...p.draggableProps} {...p.dragHandleProps}
                            className="flex items-center gap-2 rounded-lg border border-white/[0.08] bg-white/[0.03] px-2 py-1.5">
                            <GripVertical size={13} className="text-muted-foreground shrink-0" />
                            <span className="h-6 w-6 rounded flex items-center justify-center shrink-0"
                              style={{ background: allAppsById[n.app]?.bg || "#5E5CE6" }}>
                              {(() => { const A = allAppsById[n.app]; return A?.Icon ? <A.Icon size={12} className="text-white" /> : null; })()}
                            </span>
                            <input value={n.text} onChange={(e) => setQueueText(n.id, e.target.value)}
                              className="flex-1 min-w-0 bg-transparent text-xs font-body outline-none text-foreground" />
                            <button onClick={() => removeQueuedNotif(n.id)} aria-label="Remove"
                              className="text-muted-foreground hover:text-alert shrink-0 transition">
                              <Trash2 size={12} />
                            </button>
                          </div>
                        )}
                      </Draggable>
                    ))}
                    {provided.placeholder}
                  </div>
                )}
              </Droppable>
            </DragDropContext>
          </div>
        )}
        <div className="mt-2 flex items-center gap-2">
          <button onClick={pushNextNotification} disabled={!notifQueue.length}
            className="flex-1 flex h-9 items-center justify-center gap-1.5 rounded-full bg-signal px-4 text-xs font-body font-semibold text-background disabled:opacity-40 hover:brightness-110 transition">
            <Bell size={13} /> Push
          </button>
          <button onClick={resetNotifications}
            className="flex h-9 items-center gap-1.5 rounded-lg border border-white/[0.08] px-3 text-xs font-body text-muted-foreground hover:text-alert hover:border-alert/40 transition">
            <Recycle size={13} /> Reset
          </button>
        </div>
        <div className="mt-2 text-[10px] font-body text-muted-foreground">
          Banners stack below each other on the phone until Reset clears them
        </div>
      </ControlCard>

      {/* alarm trigger */}
      <ControlCard icon={AlarmClock} iconClass="text-amber" title="Alarm Trigger"
        badge={alarmId ? (
          <span className="text-[11px] font-body font-semibold uppercase text-amber amber-pulse">ringing</span>
        ) : null}>
        <button onClick={alarmId ? stopAlarm : triggerAlarm}
          className={cn("w-full flex items-center justify-center gap-2 rounded-2xl border py-3.5 text-sm font-body font-semibold transition",
            alarmId
              ? "border-alert/40 bg-alert/10 text-alert hover:bg-alert/20"
              : "border-amber/40 bg-amber/10 text-amber hover:bg-amber/20")}>
          <AlarmClock size={18} />
          {alarmId ? "Stop Alarm" : "Trigger Alarm"}
        </button>
      </ControlCard>

      {/* remote 3-finger tap pad */}
      <LockPad channel={channel} />

      {pickerOpen && (
        <DeviceContactPicker
          onPick={(c) => {
            saveContact({ name: c.name, number: c.number, email: c.email, image: c.image || "" });
            setPickerOpen(false);
          }}
          onClose={() => setPickerOpen(false)} />
      )}
    </div>
  );
}