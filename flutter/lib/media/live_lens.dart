import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// The device camera, used by the camera app and Vidcall.
class LiveLens {
  RTCVideoRenderer? renderer;
  MediaStream? _stream;
  bool ready = false;
  bool denied = false;

  Future<void> open({
    bool video = true,
    bool audio = false,
    bool front = false,
  }) async {
    await close();
    denied = false;
    ready = false;
    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': audio,
        'video': video
            ? {'facingMode': front ? 'user' : 'environment'}
            : false,
      });
      final view = RTCVideoRenderer();
      await view.initialize();
      view.srcObject = stream;
      _stream = stream;
      renderer = view;
      ready = video && stream.getVideoTracks().isNotEmpty;
    } catch (_) {
      denied = true;
      ready = false;
    }
  }

  void setMic(bool on) {
    final stream = _stream;
    if (stream == null) return;
    for (final track in stream.getAudioTracks()) {
      track.enabled = on;
    }
  }

  Future<Uint8List?> capture() async {
    final tracks = _stream?.getVideoTracks() ?? const <MediaStreamTrack>[];
    if (tracks.isEmpty) return null;
    try {
      final buffer = await tracks.first.captureFrame();
      return await _poster(buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _poster(Uint8List bytes) async {
    if (bytes.isEmpty) return null;
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 480);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      codec.dispose();
      final poster = data?.buffer.asUint8List();
      if (poster == null || poster.isEmpty) return null;
      return poster;
    } catch (_) {
      return bytes.length > 180000 ? null : bytes;
    }
  }

  Future<void> close() async {
    final stream = _stream;
    final view = renderer;
    _stream = null;
    renderer = null;
    ready = false;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        try {
          await track.stop();
        } catch (_) {}
      }
      try {
        await stream.dispose();
      } catch (_) {}
    }
    try {
      await view?.dispose();
    } catch (_) {}
  }
}

class LensView extends StatelessWidget {
  const LensView({super.key, required this.lens, this.mirror = false});

  final LiveLens lens;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final renderer = lens.renderer;
    if (!lens.ready || renderer == null) {
      return const ColoredBox(color: Colors.black);
    }
    return RTCVideoView(
      renderer,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      mirror: mirror,
    );
  }
}
