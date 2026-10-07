import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../app.dart';
import '../deck/chrome.dart';
import '../filmstrip.dart';
import '../store.dart';
import '../models.dart';
import '../theme.dart';
import '../trim_math.dart';
import '../video_source.dart';
import '../widgets/three_finger.dart';

const _aspects = [
  ('fit', 'Fit (full frame)'),
  ('fill', 'Fill (crop edges)'),
  ('16:9', '16:9'),
  ('9:16', '9:16 vertical'),
  ('1:1', '1:1 square'),
  ('4:3', '4:3'),
  ('2.39:1', '2.39:1 cinema'),
];

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  int? _playIndex;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final palette = paletteFor(store.appTheme);
    final clips = [...store.clips]..sort((a, b) => a.order.compareTo(b.order));
    if (_playIndex != null && _playIndex! < clips.length) {
      return _Player(
        clips: clips,
        index: _playIndex!,
        onIndex: (value) => setState(() => _playIndex = value),
        onExit: () => setState(() => _playIndex = null),
      );
    }
    return GridFill(
      palette: palette,
      child: ColoredBox(
        color: const Color(0xFF0B0B0F),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Videos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${clips.length} of 5 slots · max 10 min each',
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: clips.isEmpty ? null : () => setState(() => _playIndex = 0),
                  icon: const Icon(Icons.play_arrow, size: 14),
                  label: const Text('Play queue'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: clips.length >= 5 ? null : _import,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add video from this device'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: clips.length >= 5
                  ? null
                  : () {
                      store.addClip(
                        VideoClip(
                          id: 'sample-${DateTime.now().microsecondsSinceEpoch}',
                          name: 'Sample clip',
                          url: kSampleClipUrl,
                          order: clips.length,
                        ),
                      );
                    },
              icon: const Icon(Icons.movie_outlined, size: 16),
              label: const Text('Load sample'),
            ),
            if (clips.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Icon(Icons.movie_outlined, color: Colors.white38, size: 28),
                    SizedBox(height: 8),
                    Text(
                      'No videos yet - add up to five to build the queue',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              )
            else
              for (var i = 0; i < clips.length; i++)
                _row(store, clips, i),
          ],
        ),
      ),
    );
  }

  Widget _row(StageStore store, List<VideoClip> clips, int index) {
    final clip = clips[index];
    final trimmed = clip.trimStartMs > 100 ||
        (clip.trimEndMs > 0 && clip.durationMs > 0 && clip.trimEndMs < clip.durationMs - 100);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => setState(() => _playIndex = index),
            child: Container(
              width: 80,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.movie_outlined, color: Colors.white30, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _playIndex = index),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clip.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    children: [
                      Text('${index + 1} in queue', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                      if (trimmed)
                        const Text('trimmed', style: TextStyle(color: kAccent, fontSize: 9)),
                      if (clip.loop)
                        const Text('loop', style: TextStyle(color: kSignal, fontSize: 9)),
                      if (clip.aspect != 'fit')
                        Text(clip.aspect, style: const TextStyle(color: Colors.white54, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: index == 0 ? null : () => store.moveClip(index, index - 1),
                icon: const Icon(Icons.arrow_upward, size: 14, color: Colors.white54),
              ),
              IconButton(
                onPressed: index == clips.length - 1 ? null : () => store.moveClip(index, index + 1),
                icon: const Icon(Icons.arrow_downward, size: 14, color: Colors.white54),
              ),
            ],
          ),
          IconButton(
            onPressed: () async {
              await deleteVideoFile(clip.path);
              store.removeClip(clip.id);
            },
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Future<void> _import() async {
    final store = StoreScope.of(context);
    final file = await FilePicker.pickFile(type: FileType.video, dialogTitle: 'Import clip');
    if (file == null || !mounted) return;
    final path = await persistPickedVideo(file);
    if (!mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Import a clip from the iOS, Android, Windows, or Mac app. Sample playback still works here.',
          ),
        ),
      );
      return;
    }
    store.addClip(
      VideoClip(
        id: 'clip-${DateTime.now().microsecondsSinceEpoch}',
        name: file.name,
        path: path,
        order: store.clips.length,
      ),
    );
  }
}

class _Player extends StatefulWidget {
  const _Player({
    required this.clips,
    required this.index,
    required this.onIndex,
    required this.onExit,
  });

  final List<VideoClip> clips;
  final int index;
  final ValueChanged<int> onIndex;
  final VoidCallback onExit;

  @override
  State<_Player> createState() => _PlayerState();
}

class _PlayerState extends State<_Player> {
  VideoPlayerController? _controller;
  bool _locked = false;
  String? _error;
  String _aspect = 'fit';
  bool _loop = false;
  int _trimStart = 0;
  int _trimEnd = 0;
  List<String> _thumbs = const [];
  Timer? _trimSave;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(_Player oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clips[oldWidget.index].id != widget.clips[widget.index].id) {
      _open();
    }
  }

  @override
  void dispose() {
    _trimSave?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final clip = widget.clips[widget.index];
    final previous = _controller;
    _controller = null;
    await previous?.dispose();
    final next = playerForClip(clip);
    try {
      await next.initialize();
    } catch (_) {
      await next.dispose();
      if (mounted) setState(() => _error = "Couldn't open this video");
      return;
    }
    final duration = next.value.duration.inMilliseconds;
    if (next.value.duration.inSeconds > 600) {
      await next.dispose();
      if (mounted) setState(() => _error = 'Clips are limited to 10 minutes.');
      return;
    }
    if (!mounted) {
      await next.dispose();
      return;
    }
    final start = clip.trimStartMs;
    if (start > 0) await next.seekTo(Duration(milliseconds: start));
    if (mounted && clip.durationMs != duration) {
      StoreScope.of(context).updateClip(clip.copyWith(durationMs: duration));
    }
    setState(() {
      _controller = next;
      _aspect = clip.aspect;
      _loop = clip.loop;
      _trimStart = clip.trimStartMs;
      _trimEnd = clip.trimEndMs > 0 ? clip.trimEndMs : duration;
      _thumbs = const [];
      _error = null;
    });
    next.addListener(_tick);
    unawaited(_loadThumbs(clip, duration));
    await next.play();
  }

  Future<void> _loadThumbs(VideoClip clip, int durationMs) async {
    final url = clip.url;
    if (url == null || url.isEmpty) return;
    final frames = await grabFilmstrip(url, durationMs / 1000);
    if (!mounted || widget.clips[widget.index].id != clip.id) return;
    setState(() => _thumbs = frames);
  }

  void _moveTrim(bool startEdge, int at) {
    final controller = _controller;
    final duration = controller?.value.duration.inMilliseconds ?? 0;
    final next = moveTrim(
      startEdge: startEdge,
      at: at,
      start: _trimStart,
      end: _trimEnd,
      duration: duration,
    );
    final position = controller?.value.position.inMilliseconds ?? 0;
    if (position < next.start || position > next.end) {
      controller?.seekTo(Duration(milliseconds: next.start));
    }
    setState(() {
      _trimStart = next.start;
      _trimEnd = next.end;
    });
    _trimSave?.cancel();
    final clip = widget.clips[widget.index];
    _trimSave = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      StoreScope.of(context).updateClip(
        clip.copyWith(trimStartMs: next.start, trimEndMs: next.end),
      );
    });
  }

  void _seek(int at) {
    final target = clampSeek(at, _trimStart, _trimEnd);
    _controller?.seekTo(Duration(milliseconds: target));
  }

  void _tick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final end = _trimEnd == 0 ? controller.value.duration.inMilliseconds : _trimEnd;
    final now = controller.value.position.inMilliseconds;
    if (now >= end - 50) {
      if (_loop) {
        controller.seekTo(Duration(milliseconds: _trimStart));
      } else if (widget.index < widget.clips.length - 1) {
        widget.onIndex(widget.index + 1);
      } else {
        controller.pause();
        controller.seekTo(Duration(milliseconds: _trimStart));
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clips[widget.index];
    final controller = _controller;
    return ThreeFingerToggle(
      onToggle: () => setState(() => _locked = !_locked),
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: controller == null
                    ? null
                    : () {
                        setState(() {
                          controller.value.isPlaying ? controller.pause() : controller.play();
                        });
                      },
                child: Center(child: _frame(controller)),
              ),
            ),
            if (_error != null)
              Center(child: Text(_error!, style: const TextStyle(color: Colors.white70))),
            if (!_locked) ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xCC000000), Color(0x00000000)],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: widget.onExit,
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(clip.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              Text(
                                '${widget.index + 1} of ${widget.clips.length} · ${_stamp((_trimEnd - _trimStart).clamp(0, 1 << 30))} section',
                                style: const TextStyle(color: Colors.white54, fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _locked = true),
                          icon: const Icon(Icons.lock, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xE6000000), Color(0x00000000)],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                    child: Column(
                      children: [
                        if (controller != null && controller.value.isInitialized)
                          _Timeline(
                            durationMs: controller.value.duration.inMilliseconds,
                            positionMs: controller.value.position.inMilliseconds,
                            trimStartMs: _trimStart,
                            trimEndMs: _trimEnd,
                            thumbs: _thumbs,
                            onTrim: _moveTrim,
                            onSeek: _seek,
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            IconButton(
                              onPressed: widget.index == 0 ? null : () => widget.onIndex(widget.index - 1),
                              icon: const Icon(Icons.skip_previous, color: Colors.white),
                            ),
                            IconButton(
                              onPressed: controller == null
                                  ? null
                                  : () => setState(() {
                                      controller.value.isPlaying ? controller.pause() : controller.play();
                                    }),
                              style: IconButton.styleFrom(backgroundColor: Colors.white),
                              icon: Icon(
                                controller?.value.isPlaying == true ? Icons.pause : Icons.play_arrow,
                                color: Colors.black,
                              ),
                            ),
                            IconButton(
                              onPressed: widget.index >= widget.clips.length - 1
                                  ? null
                                  : () => widget.onIndex(widget.index + 1),
                              icon: const Icon(Icons.skip_next, color: Colors.white),
                            ),
                            IconButton(
                              onPressed: () {
                                final next = !_loop;
                                setState(() => _loop = next);
                                StoreScope.of(context).updateClip(clip.copyWith(loop: next));
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: _loop ? kAccent : Colors.white10,
                              ),
                              icon: Icon(Icons.repeat, color: _loop ? Colors.black : Colors.white),
                            ),
                            PopupMenuButton<String>(
                              color: const Color(0xE6000000),
                              onSelected: (value) {
                                setState(() => _aspect = value);
                                StoreScope.of(context).updateClip(clip.copyWith(aspect: value));
                              },
                              itemBuilder: (context) => [
                                for (final aspect in _aspects)
                                  PopupMenuItem(value: aspect.$1, child: Text(aspect.$2)),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(_aspect, style: const TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (_locked)
              const Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Text(
                  'Three-finger tap or L unlocks',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _frame(VideoPlayerController? controller) {
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    final ratio = switch (_aspect) {
      '16:9' => 16 / 9,
      '9:16' => 9 / 16,
      '1:1' => 1.0,
      '4:3' => 4 / 3,
      '2.39:1' => 2.39,
      _ => controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
    };
    return AspectRatio(
      aspectRatio: ratio,
      child: FittedBox(
        fit: _aspect == 'fill' ? BoxFit.cover : BoxFit.contain,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

String _stamp(int ms) {
  final seconds = (ms / 1000).floor();
  final minutes = seconds ~/ 60;
  final remain = seconds % 60;
  return '$minutes:${remain.toString().padLeft(2, '0')}';
}

enum _Drag { play, start, end }

/// Filmstrip with in and out handles, matching `Timeline.jsx`.
class _Timeline extends StatefulWidget {
  const _Timeline({
    required this.durationMs,
    required this.positionMs,
    required this.trimStartMs,
    required this.trimEndMs,
    required this.thumbs,
    required this.onTrim,
    required this.onSeek,
  });

  final int durationMs;
  final int positionMs;
  final int trimStartMs;
  final int trimEndMs;
  final List<String> thumbs;
  final void Function(bool startEdge, int at) onTrim;
  final ValueChanged<int> onSeek;

  @override
  State<_Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<_Timeline> {
  _Drag? _drag;

  double _pct(int ms, double width) {
    if (widget.durationMs <= 0) return 0;
    return (ms / widget.durationMs).clamp(0, 1) * width;
  }

  int _timeAt(double dx, double width) {
    if (width <= 0 || widget.durationMs <= 0) return 0;
    return ((dx / width) * widget.durationMs).round().clamp(0, widget.durationMs);
  }

  void _apply(double dx, double width) {
    final at = _timeAt(dx, width);
    switch (_drag) {
      case _Drag.start:
        widget.onTrim(true, at);
      case _Drag.end:
        widget.onTrim(false, at);
      case _Drag.play:
      case null:
        widget.onSeek(at);
    }
  }

  _Drag _hit(double dx, double width) {
    final start = _pct(widget.trimStartMs, width);
    final end = _pct(widget.trimEndMs, width);
    if ((dx - (start + 6)).abs() <= 14) return _Drag.start;
    if ((dx - (end - 6)).abs() <= 14) return _Drag.end;
    return _Drag.play;
  }

  @override
  Widget build(BuildContext context) {
    final end = widget.trimEndMs <= 0 ? widget.durationMs : widget.trimEndMs;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_stamp(widget.trimStartMs), style: const TextStyle(color: Colors.white54, fontSize: 9, fontFamily: 'monospace')),
            Text(_stamp(widget.positionMs), style: const TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace')),
            Text(_stamp(end), style: const TextStyle(color: Colors.white54, fontSize: 9, fontFamily: 'monospace')),
          ],
        ),
        const SizedBox(height: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: SizedBox(
              height: 48,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final startX = _pct(widget.trimStartMs, width);
                  final endX = _pct(end, width);
                  return Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (event) {
                      _drag = _hit(event.localPosition.dx, width);
                      _apply(event.localPosition.dx, width);
                    },
                    onPointerMove: (event) {
                      if (_drag == null) return;
                      _apply(event.localPosition.dx, width);
                    },
                    onPointerUp: (_) => _drag = null,
                    onPointerCancel: (_) => _drag = null,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: widget.thumbs.isEmpty
                              ? const ColoredBox(color: Colors.black)
                              : Row(
                                  children: [
                                    for (final thumb in widget.thumbs)
                                      Expanded(child: _Thumb(thumb)),
                                  ],
                                ),
                        ),
                        if (startX > 0)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: startX,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                border: Border(
                                  right: BorderSide(color: kAccent.withValues(alpha: 0.7)),
                                ),
                              ),
                            ),
                          ),
                        if (endX < width)
                          Positioned(
                            left: endX,
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                border: Border(
                                  left: BorderSide(color: kAccent.withValues(alpha: 0.7)),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: _pct(widget.positionMs, width).clamp(0, width - 2),
                          top: 0,
                          bottom: 0,
                          width: 2,
                          child: const ColoredBox(color: Colors.white),
                        ),
                        Positioned(
                          left: startX.clamp(0, width - 12),
                          top: 0,
                          bottom: 0,
                          width: 12,
                          child: const _Handle(left: true),
                        ),
                        Positioned(
                          left: (endX - 12).clamp(0, width - 12),
                          top: 0,
                          bottom: 0,
                          width: 12,
                          child: const _Handle(left: false),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TRIM IN', style: TextStyle(color: Colors.white30, fontSize: 8, letterSpacing: 0.6)),
            Text('Drag edges · drag strip to scrub', style: TextStyle(color: Colors.white30, fontSize: 8, letterSpacing: 0.4)),
            Text('TRIM OUT', style: TextStyle(color: Colors.white30, fontSize: 8, letterSpacing: 0.6)),
          ],
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb(this.dataUrl);

  final String dataUrl;

  @override
  Widget build(BuildContext context) {
    final comma = dataUrl.indexOf(',');
    if (comma < 0) return const ColoredBox(color: Colors.black);
    try {
      final bytes = base64Decode(dataUrl.substring(comma + 1));
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        height: 48,
        gaplessPlayback: true,
        opacity: const AlwaysStoppedAnimation(0.6),
      );
    } catch (_) {
      return const ColoredBox(color: Colors.black);
    }
  }
}

class _Handle extends StatelessWidget {
  const _Handle({required this.left});

  final bool left;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.horizontal(
          left: left ? const Radius.circular(2) : Radius.zero,
          right: left ? Radius.zero : const Radius.circular(2),
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 2,
          height: 16,
          child: ColoredBox(color: Color(0xB3000000)),
        ),
      ),
    );
  }
}
