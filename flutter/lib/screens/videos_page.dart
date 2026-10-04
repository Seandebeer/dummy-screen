import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../app.dart';
import '../deck/chrome.dart';
import '../store.dart';
import '../models.dart';
import '../theme.dart';
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
      _error = null;
    });
    next.addListener(_tick);
    await next.play();
  }

  void _tick() {
    final controller = _controller;
    final clip = widget.clips[widget.index];
    if (controller == null || !controller.value.isInitialized) return;
    final end = clip.playEndMs == 0 ? controller.value.duration.inMilliseconds : clip.playEndMs;
    final now = controller.value.position.inMilliseconds;
    if (now >= end - 50) {
      if (_loop) {
        controller.seekTo(Duration(milliseconds: clip.trimStartMs));
      } else if (widget.index < widget.clips.length - 1) {
        widget.onIndex(widget.index + 1);
      } else {
        controller.pause();
        controller.seekTo(Duration(milliseconds: clip.trimStartMs));
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
                                '${widget.index + 1} of ${widget.clips.length}',
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
                          _Timeline(controller: controller, clip: clip),
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

class _Timeline extends StatelessWidget {
  const _Timeline({required this.controller, required this.clip});

  final VideoPlayerController controller;
  final VideoClip clip;

  @override
  Widget build(BuildContext context) {
    final duration = controller.value.duration.inMilliseconds;
    final position = controller.value.position.inMilliseconds;
    String stamp(int ms) {
      final seconds = (ms / 1000).floor();
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(stamp(clip.trimStartMs), style: const TextStyle(color: Colors.white54, fontSize: 9)),
            Text(stamp(position), style: const TextStyle(color: Colors.white, fontSize: 9)),
            Text(stamp(duration), style: const TextStyle(color: Colors.white54, fontSize: 9)),
          ],
        ),
        Slider(
          value: duration == 0 ? 0 : (position / duration).clamp(0, 1).toDouble(),
          onChanged: (value) {
            controller.seekTo(Duration(milliseconds: (value * duration).round()));
          },
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TRIM IN', style: TextStyle(color: Colors.white30, fontSize: 8, letterSpacing: 0.6)),
            Text('Drag edges · drag strip to scrub', style: TextStyle(color: Colors.white30, fontSize: 8)),
            Text('TRIM OUT', style: TextStyle(color: Colors.white30, fontSize: 8, letterSpacing: 0.6)),
          ],
        ),
      ],
    );
  }
}
