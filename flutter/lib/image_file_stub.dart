import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/painting.dart';
import 'package:web/web.dart';

ImageProvider? imageProviderForPath(String path) {
  if (path.startsWith('http://') ||
      path.startsWith('https://') ||
      path.startsWith('blob:')) {
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

Future<String?> persistPickedImage(PlatformFile file) async {
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) return null;
  final data = await persistImageBytes(bytes);
  if (data != null) return data;
  return _blobUrl(bytes, 'image/jpeg');
}

String _blobUrl(Uint8List bytes, String type) {
  final blob = Blob([bytes.toJS].toJS, BlobPropertyBag(type: type));
  return URL.createObjectURL(blob);
}

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
