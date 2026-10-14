import 'dart:io';

/// Starts [path] on this computer. The file stays where it is.
Future<bool> launchStoredGame(String path) async {
  if (path.isEmpty) return false;
  try {
    if (Platform.isMacOS && path.endsWith('.app')) {
      await Process.start('open', [path], mode: ProcessStartMode.detached);
    } else if (Platform.isLinux) {
      await Process.start(path, const [], mode: ProcessStartMode.detached);
    } else {
      await Process.start(
        path,
        const [],
        mode: ProcessStartMode.detached,
        runInShell: true,
      );
    }
    return true;
  } catch (_) {
    return false;
  }
}
