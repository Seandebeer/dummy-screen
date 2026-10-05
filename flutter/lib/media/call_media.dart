import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models.dart';
import '../store.dart';
import 'signal_hub.dart';

const _rtcConfig = {
  'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
  ],
};

/// Live voice and camera between the control deck and the prop phone.
///
/// This replaces the Base44 Signal records: the offer, answer, and ICE
/// candidates travel through [SignalHub], which is local on one machine and
/// forwarded over the deck link when a second machine has joined.
class CallMedia extends ChangeNotifier {
  CallMedia(this.store, this.hub) {
    store.addListener(_sync);
    _signals = hub.messages.listen(_onSignal);
    _sync();
  }

  final StageStore store;
  final SignalHub hub;

  String voiceStatus = 'off';
  String videoStatus = 'off';
  RTCVideoRenderer? remoteRenderer;

  bool _micOn = true;
  bool _speakerOn = false;
  bool _camOn = true;
  bool _armed = false;
  bool _sessionArmed = false;
  String? _session;
  bool _video = false;
  bool _phoneStarted = false;
  RTCPeerConnection? _controlPc;
  RTCPeerConnection? _phonePc;
  MediaStream? _controlStream;
  MediaStream? _phoneStream;
  RTCVideoRenderer? _controlFar;
  RTCVideoRenderer? _phoneFar;
  final List<RTCIceCandidate> _controlIce = [];
  final List<RTCIceCandidate> _phoneIce = [];
  final List<Map<String, dynamic>> _earlyControl = [];
  final List<Map<String, dynamic>> _earlyPhone = [];
  bool _phoneAnswered = false;
  StreamSubscription<Map<String, dynamic>>? _signals;
  int _generation = 0;

  /// Marks the next call the deck is about to place. A call the phone
  /// starts itself is left alone, so the operator mic stays closed.
  void arm({required bool mic, bool speaker = false, bool camera = true}) {
    _micOn = mic;
    _speakerOn = speaker;
    _camOn = camera;
    _armed = true;
  }

  void setMic(bool on) {
    _micOn = on;
    final stream = _controlStream;
    if (stream == null) return;
    for (final track in stream.getAudioTracks()) {
      track.enabled = on;
    }
  }

  void setSpeaker(bool on) {
    _speakerOn = on;
    _controlFar?.setVolume(on ? 1 : 0);
  }

  void setCam(bool on) {
    _camOn = on;
    final stream = _controlStream;
    if (stream == null) return;
    for (final track in stream.getVideoTracks()) {
      track.enabled = on;
    }
  }

  void _sync() {
    final call = store.calls.isEmpty ? null : store.calls.first;
    if (call == null) {
      if (_session != null) unawaited(_stop());
      return;
    }
    if (_session != call.id) {
      _sessionArmed = _armed;
      _armed = false;
      _session = call.id;
      _video = call.kind == 'video';
      _phoneStarted = false;
      unawaited(_open(call));
      return;
    }
    if (call.status == 'active' && !_phoneStarted && _shouldPhone) {
      _phoneStarted = true;
      unawaited(_startPhone(call));
    }
  }

  /// The joined phone always answers. On the deck machine the phone peer
  /// runs only for a call this deck just armed.
  bool get _shouldPhone => _phoneHere && (_sessionArmed || !_controlHere);

  bool get _controlHere => controlMediaHere(store.sync?.role.name ?? 'solo');

  bool get _phoneHere =>
      phoneMediaHere(store.sync?.role.name ?? 'solo', hub.remotePeers);

  Future<void> _open(LiveCall call) async {
    final token = ++_generation;
    _phoneStarted = false;
    await _releasePeers();
    if (token != _generation || _session != call.id) return;
    _video = call.kind == 'video';
    voiceStatus = 'off';
    videoStatus = 'off';
    if (_controlHere && _sessionArmed) {
      await _startControl(call);
    } else {
      notifyListeners();
    }
    if (token != _generation || _session != call.id) return;
    LiveCall? current;
    for (final item in store.calls) {
      if (item.id == call.id) current = item;
    }
    if (current != null &&
        current.status == 'active' &&
        !_phoneStarted &&
        _shouldPhone) {
      _phoneStarted = true;
      await _startPhone(current);
    }
  }

  Future<void> _startControl(LiveCall call) async {
    final generation = _generation;
    final session = call.id;
    MediaStream stream;
    try {
      stream = await navigator.mediaDevices.getUserMedia(
        _video
            ? {
                'audio': true,
                'video': {'facingMode': 'user'},
              }
            : {'audio': true, 'video': false},
      );
    } catch (_) {
      if (!_same(generation, session)) return;
      if (_video) {
        videoStatus = 'cam-denied';
      } else {
        voiceStatus = 'mic-denied';
      }
      notifyListeners();
      return;
    }
    if (!_same(generation, session)) {
      await _dropStream(stream);
      return;
    }
    try {
      _controlStream = stream;
      for (final track in stream.getAudioTracks()) {
        track.enabled = _micOn;
      }
      for (final track in stream.getVideoTracks()) {
        track.enabled = _camOn;
      }
      final pc = await createPeerConnection(_rtcConfig);
      if (!_same(generation, session)) {
        await pc.dispose();
        await _dropStream(stream);
        return;
      }
      _controlPc = pc;
      for (final track in stream.getTracks()) {
        await pc.addTrack(track, stream);
      }
      pc.onIceCandidate = (candidate) {
        hub.publish({
          'session': session,
          'sender': 'control',
          'kind': 'ice',
          'payload': candidate.toMap(),
        });
      };
      pc.onTrack = (event) {
        if (event.streams.isEmpty) return;
        unawaited(_attachControlFar(event.streams.first));
      };
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      hub.publish({
        'session': session,
        'sender': 'control',
        'kind': 'offer',
        'payload': {'sdp': offer.sdp, 'type': offer.type},
      });
      if (_video) {
        videoStatus = 'cam-on';
      } else {
        voiceStatus = 'mic-on';
      }
      notifyListeners();
      await _drain(_earlyControl, _controlSignal);
    } catch (_) {
      if (!_same(generation, session)) return;
      if (_video) {
        videoStatus = 'error';
      } else {
        voiceStatus = 'error';
      }
      notifyListeners();
    }
  }

  Future<void> _startPhone(LiveCall call) async {
    final generation = _generation;
    final session = call.id;
    try {
      MediaStream? mic;
      try {
        mic = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': false,
        });
      } catch (_) {
        mic = null;
      }
      if (!_same(generation, session)) {
        if (mic != null) await _dropStream(mic);
        return;
      }
      _phoneStream = mic;
      final pc = await createPeerConnection(_rtcConfig);
      if (!_same(generation, session)) {
        await pc.dispose();
        return;
      }
      _phonePc = pc;
      if (_video) {
        await pc.addTransceiver(
          kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
          init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
        );
      }
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      if (mic != null) {
        for (final track in mic.getAudioTracks()) {
          await pc.addTrack(track, mic);
        }
      }
      pc.onIceCandidate = (candidate) {
        hub.publish({
          'session': session,
          'sender': 'phone',
          'kind': 'ice',
          'payload': candidate.toMap(),
        });
      };
      pc.onTrack = (event) {
        if (event.streams.isEmpty) return;
        unawaited(_attachPhoneFar(event.streams.first));
      };
      _phoneAnswered = false;
      await _drain(_earlyPhone, _phoneSignal);
    } catch (_) {
      if (_video) {
        videoStatus = 'error';
      } else {
        voiceStatus = 'error';
      }
      notifyListeners();
    }
  }

  void _onSignal(Map<String, dynamic> message) {
    if (message['session'] != _session) return;
    final sender = message['sender'];
    final kind = message['kind'] as String? ?? '';
    final payload = message['payload'];
    if (payload is! Map) return;
    final map = Map<String, dynamic>.from(payload);
    if (sender == 'phone') {
      if (_controlPc == null) {
        _earlyControl.add({'kind': kind, 'payload': map});
      } else {
        unawaited(_controlSignal(kind, map));
      }
    } else if (sender == 'control') {
      if (_phonePc == null) {
        _earlyPhone.add({'kind': kind, 'payload': map});
      } else {
        unawaited(_phoneSignal(kind, map));
      }
    }
  }

  Future<void> _drain(
    List<Map<String, dynamic>> queued,
    Future<void> Function(String kind, Map<String, dynamic> payload) handle,
  ) async {
    final pending = List<Map<String, dynamic>>.of(queued);
    queued.clear();
    for (final message in pending) {
      final payload = message['payload'];
      if (payload is Map<String, dynamic>) {
        await handle(message['kind'] as String? ?? '', payload);
      }
    }
  }

  Future<void> _controlSignal(String kind, Map<String, dynamic> payload) async {
    final pc = _controlPc;
    if (pc == null) return;
    if (kind == 'answer') {
      await pc.setRemoteDescription(
        RTCSessionDescription(payload['sdp'] as String?, payload['type'] as String?),
      );
      final queued = List<RTCIceCandidate>.of(_controlIce);
      _controlIce.clear();
      for (final candidate in queued) {
        await pc.addCandidate(candidate);
      }
    } else if (kind == 'ice') {
      final candidate = _candidate(payload);
      if (await pc.getRemoteDescription() == null) {
        _controlIce.add(candidate);
      } else {
        await pc.addCandidate(candidate);
      }
    }
  }

  Future<void> _phoneSignal(String kind, Map<String, dynamic> payload) async {
    final pc = _phonePc;
    if (pc == null) return;
    if (kind == 'offer') {
      await pc.setRemoteDescription(
        RTCSessionDescription(payload['sdp'] as String?, payload['type'] as String?),
      );
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      _phoneAnswered = true;
      final queued = List<RTCIceCandidate>.of(_phoneIce);
      _phoneIce.clear();
      for (final candidate in queued) {
        await pc.addCandidate(candidate);
      }
      hub.publish({
        'session': _session,
        'sender': 'phone',
        'kind': 'answer',
        'payload': {'sdp': answer.sdp, 'type': answer.type},
      });
    } else if (kind == 'ice') {
      final candidate = _candidate(payload);
      if (!_phoneAnswered) {
        _phoneIce.add(candidate);
      } else {
        await pc.addCandidate(candidate);
      }
    }
  }

  RTCIceCandidate _candidate(Map<String, dynamic> payload) {
    return RTCIceCandidate(
      payload['candidate'] as String?,
      payload['sdpMid'] as String?,
      (payload['sdpMLineIndex'] as num?)?.toInt(),
    );
  }

  Future<void> _attachControlFar(MediaStream stream) async {
    _controlFar ??= RTCVideoRenderer();
    try {
      await _controlFar!.initialize();
    } catch (_) {}
    _controlFar!.srcObject = stream;
    await _controlFar!.setVolume(_speakerOn ? 1 : 0);
  }

  Future<void> _attachPhoneFar(MediaStream stream) async {
    _phoneFar ??= RTCVideoRenderer();
    remoteRenderer = _phoneFar;
    try {
      await _phoneFar!.initialize();
    } catch (_) {}
    _phoneFar!.srcObject = stream;
    await _phoneFar!.setVolume(1);
    notifyListeners();
  }

  bool _same(int generation, String session) =>
      generation == _generation && _session == session;

  Future<void> _stop({bool notify = true}) async {
    _generation += 1;
    _session = null;
    _sessionArmed = false;
    _phoneStarted = false;
    _video = false;
    voiceStatus = 'off';
    videoStatus = 'off';
    await _releasePeers();
    if (notify) notifyListeners();
  }

  Future<void> _releasePeers() async {
    _phoneAnswered = false;
    _controlIce.clear();
    _phoneIce.clear();
    _earlyControl.clear();
    _earlyPhone.clear();
    final control = _controlPc;
    final phone = _phonePc;
    final controlStream = _controlStream;
    final phoneStream = _phoneStream;
    final controlFar = _controlFar;
    final phoneFar = _phoneFar;
    _controlPc = null;
    _phonePc = null;
    _controlStream = null;
    _phoneStream = null;
    _controlFar = null;
    _phoneFar = null;
    remoteRenderer = null;
    try {
      controlFar?.srcObject = null;
      phoneFar?.srcObject = null;
    } catch (_) {}
    try {
      await control?.dispose();
    } catch (_) {}
    try {
      await phone?.dispose();
    } catch (_) {}
    try {
      await controlFar?.dispose();
    } catch (_) {}
    try {
      await phoneFar?.dispose();
    } catch (_) {}
    await _dropStream(controlStream);
    await _dropStream(phoneStream);
  }

  Future<void> _dropStream(MediaStream? stream) async {
    if (stream == null) return;
    for (final track in stream.getTracks()) {
      try {
        await track.stop();
      } catch (_) {}
    }
    try {
      await stream.dispose();
    } catch (_) {}
  }

  @override
  void dispose() {
    _signals?.cancel();
    store.removeListener(_sync);
    unawaited(_stop(notify: false));
    super.dispose();
  }
}

class CallMediaScope extends InheritedNotifier<CallMedia> {
  const CallMediaScope({
    super.key,
    required CallMedia? media,
    required super.child,
  }) : super(notifier: media);

  static CallMedia? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CallMediaScope>()
        ?.notifier;
  }
}
