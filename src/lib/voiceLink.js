import { base44 } from "@/api/base44Client";

// Live two-way voice between the control device and the prop phone: a WebRTC
// session is negotiated through Signal records on the call channel (realtime
// entity subscriptions carry the signalling). The control side streams the
// operator's mic into the target device and plays the prop phone's mic back
// to the operator - the deck's mic / speaker toggles are trigger-side only,
// nothing is pushed to the target.

const RTC_CONFIG = { iceServers: [{ urls: "stun:stun.l.google.com:19302" }] };
const CHANNEL = "stage-1";

const parse = (s) => {
  try { return JSON.parse(s); } catch { return null; }
};

// ---------- control side: your mic into the phone, the phone into your speaker ----------
export function startControlVoice(session, onStatus, ch = CHANNEL, opts = {}) {
  let pc = null;
  let stream = null;
  let farAudio = null;
  let micOn = opts.micOn !== false;
  let speakerOn = !!opts.speakerOn;
  let stopped = false;
  const seen = new Set();
  let pendingIce = [];

  const send = (kind, payload) =>
    base44.entities.Signal.create({ channel: ch, sender: "control", kind, session, payload: JSON.stringify(payload) }).catch(() => {});

  const applyIce = (cand) => {
    if (!pc || !pc.remoteDescription) pendingIce.push(cand);
    else pc.addIceCandidate(cand).catch(() => {});
  };

  const handle = (sig) => {
    if (!sig || sig.session !== session || sig.sender !== "phone" || seen.has(sig.id)) return;
    seen.add(sig.id);
    const payload = parse(sig.payload);
    if (sig.kind === "answer" && pc && payload) {
      pc.setRemoteDescription(payload)
        .then(() => pendingIce.splice(0).forEach((c) => pc.addIceCandidate(c).catch(() => {})))
        .catch(() => {});
    } else if (sig.kind === "ice" && payload) {
      applyIce(payload);
    }
  };

  const unsub = base44.entities.Signal.subscribe((e) => handle(e.data));

  (async () => {
    try {
      stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    } catch {
      onStatus?.("mic-denied");
      stop();
      return;
    }
    if (stopped) { stream.getTracks().forEach((t) => t.stop()); return; }
    // the operator's mic starts silent when it was toggled off pre-call
    stream.getAudioTracks().forEach((t) => { t.enabled = micOn; });
    pc = new RTCPeerConnection(RTC_CONFIG);
    stream.getTracks().forEach((t) => pc.addTrack(t, stream));
    // the prop phone's mic streams back - held muted unless the operator's
    // speaker is on
    pc.ontrack = (e) => {
      if (stopped) return;
      if (!farAudio) farAudio = new Audio();
      farAudio.autoplay = true;
      farAudio.muted = !speakerOn;
      farAudio.srcObject = e.streams[0];
      farAudio.play().catch(() => {});
    };
    pc.onicecandidate = (e) => { if (e.candidate) send("ice", e.candidate.toJSON()); };
    try {
      await pc.setLocalDescription(await pc.createOffer());
      await send("offer", pc.localDescription);
      onStatus?.("mic-on");
    } catch {
      onStatus?.("error");
      stop();
      return;
    }
    // catch up on anything the phone signalled before we were listening
    base44.entities.Signal.filter({ channel: ch, session }, "created_date", 60)
      .then((hist) => hist.forEach(handle)).catch(() => {});
  })();

  function stop() {
    if (stopped) return;
    stopped = true;
    unsub();
    base44.entities.Signal.deleteMany({ session }).catch(() => {});
    if (pc) { try { pc.close(); } catch {} pc = null; }
    if (stream) { stream.getTracks().forEach((t) => t.stop()); stream = null; }
    if (farAudio) { farAudio.srcObject = null; farAudio = null; }
    onStatus?.("off");
  }

  return {
    stop,
    setMicOn: (v) => { micOn = v; stream?.getAudioTracks().forEach((t) => { t.enabled = v; }); },
    setSpeakerOn: (v) => { speakerOn = v; if (farAudio) farAudio.muted = !v; },
  };
}

// ---------- phone side: plays the operator's voice, streams its own mic back ----------
export function startPhoneVoice(session, ch = CHANNEL) {
  let pc = null;
  let audio = null;
  let micStream = null;
  let stopped = false;
  let answered = false;
  const seen = new Set();
  let pendingIce = [];

  const send = (kind, payload) =>
    base44.entities.Signal.create({ channel: ch, sender: "phone", kind, session, payload: JSON.stringify(payload) }).catch(() => {});

  const applyIce = (cand) => {
    if (!pc || !pc.remoteDescription || !answered) pendingIce.push(cand);
    else pc.addIceCandidate(cand).catch(() => {});
  };

  const handle = (sig) => {
    if (!sig || sig.session !== session || sig.sender !== "control" || seen.has(sig.id)) return;
    // signals that arrive before the peer connection is up are skipped here
    // and re-delivered by the history sweep once it exists
    if (!pc) return;
    seen.add(sig.id);
    const payload = parse(sig.payload);
    if (sig.kind === "offer" && payload) {
      pc.setRemoteDescription(payload)
        .then(() => pc.createAnswer())
        .then((answer) => pc.setLocalDescription(answer))
        .then(() => {
          answered = true;
          pendingIce.splice(0).forEach((c) => pc.addIceCandidate(c).catch(() => {}));
          return send("answer", pc.localDescription);
        })
        .catch(() => {});
    } else if (sig.kind === "ice" && payload) {
      applyIce(payload);
    }
  };

  const unsub = base44.entities.Signal.subscribe((e) => handle(e.data));

  // the prop phone's mic streams back so the operator can hear the actor;
  // without mic permission the call still runs, just one-way
  (async () => {
    try { micStream = await navigator.mediaDevices.getUserMedia({ audio: true }); } catch { micStream = null; }
    if (stopped) { micStream?.getTracks().forEach((t) => t.stop()); return; }
    pc = new RTCPeerConnection(RTC_CONFIG);
    pc.addTransceiver("audio", { direction: "recvonly" });
    micStream?.getTracks().forEach((t) => pc.addTrack(t, micStream));
    pc.onicecandidate = (e) => { if (e.candidate) send("ice", e.candidate.toJSON()); };
    pc.ontrack = (e) => {
      if (stopped) return;
      if (!audio) audio = new Audio();
      audio.autoplay = true;
      audio.srcObject = e.streams[0];
      audio.play().catch(() => {});
    };
    // the offer was sent when the call was triggered - pick it up here
    base44.entities.Signal.filter({ channel: ch, session }, "created_date", 60)
      .then((hist) => hist.forEach(handle)).catch(() => {});
  })();

  function stop() {
    if (stopped) return;
    stopped = true;
    unsub();
    if (audio) { audio.srcObject = null; audio = null; }
    if (micStream) { micStream.getTracks().forEach((t) => t.stop()); micStream = null; }
    if (pc) { try { pc.close(); } catch {} pc = null; }
  }

  return { stop };
}