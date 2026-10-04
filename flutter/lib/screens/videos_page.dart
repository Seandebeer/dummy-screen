import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../app.dart';
import '../models.dart';
import '../theme.dart';
import '../video_source.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  VideoPlayerController? _controller;
  String? _activeId;
  String? _error;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _play(VideoClip clip) async {
    final previous = _controller;
    _controller = null;
    await previous?.dispose();
    final next = playerForClip(clip);
    try {
      await next.initialize();
    } catch (_) {
      await next.dispose();
      if (mounted) setState(() => _error = 'This clip could not be opened.');
      return;
    }
    if (next.value.duration.inSeconds > 600) {
      await next.dispose();
      if (mounted) setState(() => _error = 'Clips are limited to 10 minutes.');
      return;
    }
    if (!mounted) {
      await next.dispose();
      return;
    }
    setState(() {
      _controller = next;
      _activeId = clip.id;
      _error = null;
    });
    await next.play();
  }

  Future<void> _import() async {
    final store = StoreScope.of(context);
    if (store.clips.length >= 5) {
      setState(() => _error = 'The queue holds five clips.');
      return;
    }
    final file = await FilePicker.pickFile(
      type: FileType.video,
      dialogTitle: 'Import clip',
    );
    if (file == null || !mounted) return;
    final path = await persistPickedVideo(file);
    if (!mounted) return;
    if (path == null) {
      setState(
        () => _error = 'Import a clip from the iOS, Android, Windows, or Mac app. Sample playback still works here.',
      );
      return;
    }
    store.addClip(
      VideoClip(
        id: 'clip-${DateTime.now().microsecondsSinceEpoch}',
        name: file.name,
        path: path,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final controller = _controller;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        const Text(
          'Playback',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Up to five clips, kept on this device.',
          style: TextStyle(color: kMuted),
        ),
        const SizedBox(height: 16),
        if (controller != null && controller.value.isInitialized)
          AspectRatio(
            aspectRatio: controller.value.aspectRatio == 0
                ? 16 / 9
                : controller.value.aspectRatio,
            child: VideoPlayer(controller),
          )
        else
          Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'No clip playing',
              style: TextStyle(color: kMuted),
            ),
          ),
        if (controller != null) ...[
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(playedColor: kAccent),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() {
                  controller.value.isPlaying
                      ? controller.pause()
                      : controller.play();
                }),
                icon: Icon(
                  controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
              ),
              Text(_activeId == null ? '' : 'Playing'),
            ],
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: kAlert)),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _import,
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Import'),
            ),
            OutlinedButton.icon(
              onPressed: store.clips.length >= 5
                  ? null
                  : () {
                      final clip = VideoClip(
                        id: 'sample-${DateTime.now().microsecondsSinceEpoch}',
                        name: 'Sample clip',
                        url: kSampleClipUrl,
                      );
                      store.addClip(clip);
                      _play(clip);
                    },
              icon: const Icon(Icons.movie_outlined),
              label: const Text('Load sample'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final clip in store.clips)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.play_circle_outline),
            title: Text(clip.name),
            selected: clip.id == _activeId,
            onTap: () => _play(clip),
            trailing: IconButton(
              tooltip: 'Remove',
              onPressed: () async {
                if (_activeId == clip.id) {
                  await _controller?.dispose();
                  _controller = null;
                  _activeId = null;
                }
                await deleteVideoFile(clip.path);
                store.removeClip(clip.id);
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ),
      ],
    );
  }
}
