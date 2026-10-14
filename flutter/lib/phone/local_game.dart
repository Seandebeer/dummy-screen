import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_game_launch.dart';

const _pathKey = 'dummy-screen-local-game-path';
const _nameKey = 'dummy-screen-local-game-name';

/// A program that already lives on this computer. The path is kept in
/// local preferences, not in the stage, so another machine does not see it.
class LocalGameLink {
  const LocalGameLink(this.path, this.name);

  final String path;
  final String name;

  static final changes = ValueNotifier<int>(0);

  static Future<LocalGameLink?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_pathKey) ?? '';
    final name = prefs.getString(_nameKey) ?? '';
    if (path.isEmpty && name.isEmpty) return null;
    return LocalGameLink(path, name.isEmpty ? path : name);
  }

  /// Remembers the chosen file. Nothing is copied into the app.
  static Future<LocalGameLink?> pick() async {
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null) return null;
    final path = file.path ?? '';
    final name = file.name.trim().isEmpty ? 'Game' : file.name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pathKey, path);
    await prefs.setString(_nameKey, name);
    changes.value++;
    return LocalGameLink(path, name);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pathKey);
    await prefs.remove(_nameKey);
    changes.value++;
  }

  static Future<bool> launch() async {
    final link = await read();
    if (link == null || link.path.isEmpty) return false;
    return launchStoredGame(link.path);
  }
}

/// Opens the linked program when one is chosen on this computer.
/// Otherwise [fallback] runs.
Future<void> openDeviceGame(BuildContext context, VoidCallback fallback) async {
  final link = await LocalGameLink.read();
  if (link == null) {
    fallback();
    return;
  }
  final started = await LocalGameLink.launch();
  if (started || !context.mounted) return;
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text(
        '“${link.name}” is linked on this computer. The installed app starts it.',
      ),
    ),
  );
}

/// The linked game's name, or [fallback] when this computer has none.
class LocalGameName extends StatelessWidget {
  const LocalGameName({
    super.key,
    required this.fallback,
    required this.style,
    this.maxLines = 2,
  });

  final String fallback;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: LocalGameLink.changes,
      builder: (context, _, _) {
        return FutureBuilder<LocalGameLink?>(
          future: LocalGameLink.read(),
          builder: (context, snapshot) {
            final name = snapshot.data?.name;
            return Text(
              name == null || name.isEmpty ? fallback : name,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: style,
            );
          },
        );
      },
    );
  }
}
