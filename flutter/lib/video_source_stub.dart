import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:web/web.dart';

import 'models.dart';

Future<String?> persistPickedVideo(PlatformFile file) async {
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) return null;
  final ext = file.extension?.toLowerCase();
  final type = ext == 'mp4'
      ? 'video/mp4'
      : ext == 'mov'
      ? 'video/quicktime'
      : 'video/webm';
  return _blobUrl(bytes, type);
}

String _blobUrl(List<int> bytes, String type) {
  final blob = Blob(
    [bytes is Uint8List ? bytes.toJS : Uint8List.fromList(bytes).toJS].toJS,
    BlobPropertyBag(type: type),
  );
  return URL.createObjectURL(blob);
}

Future<void> deleteVideoFile(String? path) async {}

VideoPlayerController? playerForPath(String path) => null;

VideoPlayerController playerForClip(VideoClip clip) {
  final url = clip.url;
  if (url == null || url.isEmpty) {
    throw StateError('This clip is stored on the installed app.');
  }
  return VideoPlayerController.networkUrl(Uri.parse(url));
}
