import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

import 'models.dart';

Future<String?> persistPickedVideo(PlatformFile file) async => null;

Future<void> deleteVideoFile(String? path) async {}

VideoPlayerController playerForClip(VideoClip clip) {
  final url = clip.url;
  if (url == null || url.isEmpty) {
    throw StateError('This clip is stored on the installed app.');
  }
  return VideoPlayerController.networkUrl(Uri.parse(url));
}
