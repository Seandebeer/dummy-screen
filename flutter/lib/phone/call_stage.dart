import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:video_player/video_player.dart';

import '../image_file.dart';
import '../models.dart';
import '../video_source.dart';
import '../vfx/catalog.dart';
import '../vfx/mark_glyph.dart';

/// What the actor sees once a video call is answered: the deck camera,
/// a VFX screen, an uploaded clip, or a still.
class CallStage extends StatelessWidget {
  const CallStage({super.key, required this.call, this.feed});

  final LiveCall call;
  final RTCVideoRenderer? feed;

  @override
  Widget build(BuildContext context) {
    switch (call.sceneMode) {
      case 'photo':
        return _Still(
          source: call.scene['photo'] as String? ?? '',
          empty: 'No photo for ${call.contactName}',
          name: call.contactName,
        );
      case 'video':
        return _Clip(source: call.scene['video'] as String? ?? '');
      case 'vfx':
        return _Vfx(
          bg: call.scene['bg'] as String? ?? '#00B140',
          mark: call.scene['mark'] as String? ?? 'cross',
        );
      default:
        final off = call.scene['camOff'] == true;
        final renderer = feed;
        if (!off && renderer?.srcObject != null) {
          return RTCVideoView(
            renderer!,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          );
        }
        return _Hold(
          name: call.contactName,
          text: off ? 'Camera off' : 'Connecting…',
        );
    }
  }
}

class _Hold extends StatelessWidget {
  const _Hold({required this.name, required this.text});

  final String name;
  final String text;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return ColoredBox(
      color: const Color(0xFF101012),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white10,
              child: Text(initial, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _Still extends StatelessWidget {
  const _Still({required this.source, required this.empty, required this.name});

  final String source;
  final String empty;
  final String name;

  @override
  Widget build(BuildContext context) {
    final provider = imageProviderForPath(source);
    if (provider == null) return _Hold(name: name, text: empty);
    return SizedBox.expand(
      child: Image(image: provider, fit: BoxFit.cover),
    );
  }
}

class _Vfx extends StatelessWidget {
  const _Vfx({required this.bg, required this.mark});

  final String bg;
  final String mark;

  @override
  Widget build(BuildContext context) {
    final color = parseHex(bg, const Color(0xFF00B140));
    final ink = lightHex(color) ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final marks = mark == 'none' ? const <StageMark>[] : defaultLayoutFor(mark);
    return ColoredBox(
      color: color,
      child: Stack(
        children: [
          for (final item in marks)
            Align(
              alignment: Alignment(item.x / 50 - 1, item.y / 50 - 1),
              child: MarkGlyph(
                kind: item.kind,
                color: ink,
                scale: 1.1,
                thickness: 0.6,
                rotation: item.rot,
                x: item.x,
                y: item.y,
              ),
            ),
        ],
      ),
    );
  }
}

class _Clip extends StatefulWidget {
  const _Clip({required this.source});

  final String source;

  @override
  State<_Clip> createState() => _ClipState();
}

class _ClipState extends State<_Clip> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(covariant _Clip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _controller?.dispose();
      _controller = null;
      _open();
    }
  }

  Future<void> _open() async {
    final source = widget.source;
    if (source.isEmpty) return;
    final controller = source.startsWith('http://') ||
            source.startsWith('https://') ||
            source.startsWith('blob:')
        ? VideoPlayerController.networkUrl(Uri.parse(source))
        : playerForPath(source);
    if (controller == null) return;
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (widget.source.isEmpty || controller == null || !controller.value.isInitialized) {
      return _Hold(
        name: '',
        text: widget.source.isEmpty ? 'No video for the other end yet' : 'Connecting…',
      );
    }
    final size = controller.value.size;
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}
