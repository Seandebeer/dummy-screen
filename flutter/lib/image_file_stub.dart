import 'package:file_picker/file_picker.dart';
import 'package:flutter/painting.dart';

ImageProvider? imageProviderForPath(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  return null;
}

Future<String?> persistPickedImage(PlatformFile file) async => null;
