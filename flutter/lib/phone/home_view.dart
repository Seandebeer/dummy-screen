import 'package:flutter/material.dart';

import '../theme.dart';
import 'catalog.dart';

class PhoneHome extends StatelessWidget {
  const PhoneHome({super.key, required this.skin, required this.onOpen});

  final String skin;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    if (skin == 'tiles') {
      return GridView.count(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.1,
        children: [
          for (final app in kPropApps)
            _Tile(app: app, onTap: () => onOpen(app.id)),
        ],
      );
    }
    final grid = kPropApps.where((app) => !kDockIds.contains(app.id)).toList();
    final dock = [for (final id in kDockIds) propAppById(id)!];
    return Column(
      children: [
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            children: [
              for (final app in grid)
                _IconApp(
                  app: app,
                  glossy: skin == 'classic',
                  onTap: () => onOpen(app.id),
                ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: skin == 'classic' ? 0.16 : 0.08,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final app in dock)
                _IconApp(
                  key: Key('dock-${app.id}'),
                  app: app,
                  glossy: skin == 'classic',
                  onTap: () => onOpen(app.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconApp extends StatelessWidget {
  const _IconApp({
    super.key,
    required this.app,
    required this.onTap,
    this.glossy = false,
  });

  final PropApp app;
  final VoidCallback onTap;
  final bool glossy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: app.color,
              borderRadius: BorderRadius.circular(glossy ? 12 : 14),
              gradient: glossy
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white.withValues(alpha: 0.45), app.color],
                    )
                  : null,
            ),
            child: Icon(app.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            app.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.app, required this.onTap});

  final PropApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: app.color,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(app.icon, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  app.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LockView extends StatelessWidget {
  const LockView({
    super.key,
    required this.timeLabel,
    required this.dateLabel,
    required this.onUnlock,
  });

  final String timeLabel;
  final String dateLabel;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < -200) onUnlock();
      },
      child: Column(
        children: [
          const Spacer(),
          FittedBox(
            child: Text(
              timeLabel,
              style: const TextStyle(
                fontSize: 84,
                fontWeight: FontWeight.w200,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(dateLabel, style: const TextStyle(color: kMuted, fontSize: 16)),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_up, color: kMuted),
          TextButton(
            key: const Key('lock-unlock'),
            onPressed: onUnlock,
            child: const Text('Unlock'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
