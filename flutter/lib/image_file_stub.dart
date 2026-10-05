import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/painting.dart';

ImageProvider? imageProviderForPath(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  return _memoryImage(path);
}

/// Browser builds cannot write a file, so a captured frame is a data URL.
Future<String?> persistImageBytes(Uint8List bytes) async {
  if (bytes.isEmpty) return null;
  final url = 'data:image/png;base64,${base64Encode(bytes)}';
  if (url.length > 400000) return null;
  return url;
}

Future<String?> persistPickedImage(PlatformFile file) async => null;

ImageProvider? _memoryImage(String path) {
  if (!path.startsWith('data:image')) return null;
  final comma = path.indexOf(',');
  if (comma < 0) return null;
  try {
    return MemoryImage(base64Decode(path.substring(comma + 1)));
  } catch (_) {
    return null;
  }
}
