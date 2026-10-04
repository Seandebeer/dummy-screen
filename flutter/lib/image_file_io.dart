import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

ImageProvider? imageProviderForPath(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  final file = File(path);
  if (!file.existsSync()) return null;
  return FileImage(file);
}

Future<String?> persistPickedImage(PlatformFile file) async {
  try {
    final root = await getApplicationDocumentsDirectory();
    final folder = Directory('${root.path}/wallpapers');
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
