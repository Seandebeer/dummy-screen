import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'models.dart';

Future<String?> persistPickedVideo(PlatformFile file) async {
  try {
    final root = await getApplicationDocumentsDirectory();
    final folder = Directory('${root.path}/clips');
    await folder.create(recursive: true);
    final safe = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final dest = File(
      '${folder.path}/${DateTime.now().microsecondsSinceEpoch}_$safe',
    );
    final source = file.path;
    if (source != null && source.isNotEmpty) {
      await File(source).copy(dest.path);
      return dest.path;
    }
    final bytes = await file.readAsBytes();
    await dest.writeAsBytes(bytes, flush: true);
    return dest.path;
  } catch (_) {}
  return null;
}

Future<void> deleteVideoFile(String? path) async {
  if (path == null || path.isEmpty) return;
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {}
}

VideoPlayerController playerForClip(VideoClip clip) {
  final path = clip.path;
  if (path != null && path.isNotEmpty) {
    return VideoPlayerController.file(File(path));
  }
  final url = clip.url;
  if (url == null || url.isEmpty) {
    throw StateError('Clip has no media');
  }
  return VideoPlayerController.networkUrl(Uri.parse(url));
}
