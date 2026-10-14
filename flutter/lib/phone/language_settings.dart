import 'package:flutter/material.dart';

import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';
import '../theme.dart';

/// The language grid used by every device settings menu.
class LanguageChoices extends StatelessWidget {
  const LanguageChoices({
    super.key,
    required this.store,
    required this.device,
    this.keyPrefix = 'os-language',
  });

  final StageStore store;
  final PropDevice device;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final code = device.os.language;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 3.4,
      children: [
        for (final language in osLanguages)
          OutlinedButton(
            key: Key('$keyPrefix-${language.code}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: code == language.code
                  ? kAccent
                  : const Color(0xD9FFFFFF),
              backgroundColor: code == language.code
                  ? kAccent.withValues(alpha: 0.1)
                  : Colors.transparent,
              side: BorderSide(
                color: code == language.code ? kAccent : const Color(0x33FFFFFF),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () => store.updateOs(
              device.id,
              (current) => current.copyWith(language: language.code),
            ),
            child: Text(
              language.native,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
      ],
    );
  }
}
