import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

/// Eight filmstrip frames, matching `grabThumbs` in videoStore.js.
Future<List<String>> grabFilmstrip(String url, double durationSeconds) async {
  if (url.isEmpty || !durationSeconds.isFinite || durationSeconds <= 0) {
    return const [];
  }
  final video = HTMLVideoElement()
    ..preload = 'auto'
    ..muted = true
    ..crossOrigin = 'anonymous'
    ..src = url;
  video.setAttribute('playsinline', 'true');
  try {
    final loaded = Completer<bool>();
    video.onloadeddata = ((Event _) {
      if (!loaded.isCompleted) loaded.complete(true);
    }).toJS;
    final ready = await loaded.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => false,
    );
    if (!ready || video.videoWidth == 0) return const [];
    const width = 120;
    final height = (video.videoHeight / video.videoWidth * width).round().clamp(48, 240);
    final canvas = HTMLCanvasElement()
      ..width = width
      ..height = height;
    final raw = canvas.getContext('2d');
    if (raw == null) return const [];
    final context = raw as CanvasRenderingContext2D;
    final frames = <String>[];
    for (var i = 0; i < 8; i++) {
      final at = ((i + 0.5) / 8) * durationSeconds;
      if (!await _seek(video, at)) continue;
      try {
        context.drawImage(video, 0, 0, width, height);
        frames.add(canvas.toDataURL('image/jpeg', 0.55.toJS));
      } catch (_) {
        break;
      }
    }
    return frames;
  } finally {
    video.removeAttribute('src');
    video.load();
  }
}

Future<bool> _seek(HTMLVideoElement video, double seconds) {
  final done = Completer<bool>();
  video.onseeked = ((Event _) {
    if (!done.isCompleted) done.complete(true);
  }).toJS;
  video.currentTime = seconds;
  return done.future.timeout(const Duration(seconds: 3), onTimeout: () => false);
}
