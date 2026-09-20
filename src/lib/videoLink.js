import { base44 } from "@/api/base44Client";

// Live video (with mic audio) between the control device and the prop phone:
// a WebRTC session negotiated through Signal records on the stage-1 channel,
// same as voiceLink but with camera + mic and track toggles mid-call.

const RTC_CONFIG = { iceServers: [{ urls: "stun:stun.l.google.com:19302" }] };
const CHANNEL = "stage-1";

const parse = (s) => {
  try { return JSON.parse(s); } catch { return null; }
};

// ---------- control side: streams the operator's camera + mic to the device ----------
export function startControlVideo(session, onStatus, ch = CHANNEL, opts = {}) {
  let pc = null;
  let stream = null;
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
      stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "user" }, audio: true });
    } catch {
      onStatus?.("denied");
      stop();
      return;
    }
    if (stopped) { stream.getTracks().forEach((t) => t.stop()); return; }
    // the operator's mic starts silent when it was toggled off pre-call
    if (opts.micOn === false) stream.getAudioTracks().forEach((t) => { t.enabled = false; });
    pc = new RTCPeerConnection(RTC_CONFIG);
    stream.getTracks().forEach((t) => pc.addTrack(t, stream));
    pc.onicecandidate = (e) => { if (e.candidate) send("ice", e.candidate.toJSON()); };
    try {
      await pc.setLocalDescription(await pc.createOffer());
      await send("offer", pc.localDescription);
      onStatus?.("on");
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
    onStatus?.("off");
  }

  return {
    stop,
    setCamOn: (v) => stream?.getVideoTracks().forEach((t) => { t.enabled = v; }),
    setMicOn: (v) => stream?.getAudioTracks().forEach((t) => { t.enabled = v; }),
  };
}

// ---------- phone side: shows the operator's live feed in the call ----------
export function startPhoneVideo(session, videoEl, ch = CHANNEL) {
  let pc = null;
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
    seen.add(sig.id);
    const payload = parse(sig.payload);
    if (sig.kind === "offer" && pc && payload) {
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

  pc = new RTCPeerConnection(RTC_CONFIG);
  pc.addTransceiver("video", { direction: "recvonly" });
  pc.addTransceiver("audio", { direction: "recvonly" });
  pc.onicecandidate = (e) => { if (e.candidate) send("ice", e.candidate.toJSON()); };
  pc.ontrack = (e) => {
    if (stopped || !videoEl) return;
    videoEl.srcObject = e.streams[0];
    videoEl.play?.().catch(() => {});
  };

  const unsub = base44.entities.Signal.subscribe((e) => handle(e.data));
  // the offer was sent when the call was triggered - pick it up here
  base44.entities.Signal.filter({ channel: ch, session }, "created_date", 60)
    .then((hist) => hist.forEach(handle)).catch(() => {});

  function stop() {
    if (stopped) return;
    stopped = true;
    unsub();
    if (videoEl) videoEl.srcObject = null;
    if (pc) { try { pc.close(); } catch {} pc = null; }
  }

  return { stop };
}