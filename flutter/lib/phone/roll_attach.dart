import 'package:flutter/material.dart';

import '../image_file.dart';
import '../models.dart';

/// Path stored on a message or mail part. A roll item with no file keeps its
/// colour so the tile still shows.
String rollMediaRef(PropPhoto photo) =>
    photo.image.isNotEmpty ? photo.image : 'swatch:${photo.color}';

String rollMediaType(PropPhoto photo) => photo.isVideo ? 'video' : 'photo';

/// List line for a message that may be a photo or video with no caption.
String messagePreview(String text, String mediaType) {
  final trimmed = text.trim();
  if (trimmed.isNotEmpty) return trimmed;
  if (mediaType == 'video') return 'Video';
  if (mediaType == 'photo') return 'Photo';
  return '';
}

/// Inbox row snippet. A part that is only an attachment reads as Photo or Video.
String mailSnippet(dynamic part) {
  final map = jsonMap(part);
  return messagePreview('${map['body'] ?? ''}', '${map['mediaType'] ?? ''}');
}

/// Deep copy so an edit does not alias the store's page map.
Map<String, dynamic> copyMail(Map<String, dynamic> mail) {
  final copy = Map<String, dynamic>.from(mail);
  final thread = copy['thread'];
  if (thread is List) {
    copy['thread'] = [
      for (final part in thread)
        if (part is Map) Map<String, dynamic>.from(jsonMap(part)) else part,
    ];
  }
  return copy;
}

/// One camera-roll tile, used in the picker and inside a sent message.
class RollFrame extends StatelessWidget {
  const RollFrame({super.key, required this.media, required this.mediaType});

  final String media;
  final String mediaType;

  @override
  Widget build(BuildContext context) {
    final swatch = _swatch(media);
    final provider = swatch == null ? imageProviderForPath(media) : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color(swatch ?? 0xFF5E5CE6),
        image: provider == null
            ? null
            : DecorationImage(image: provider, fit: BoxFit.cover),
      ),
      child: mediaType == 'video'
          ? const Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
            )
          : const SizedBox.expand(),
    );
  }
}

/// Fixed-size frame for a bubble, a mail part, or the pending attachment.
class RollStill extends StatelessWidget {
  const RollStill({
    super.key,
    required this.media,
    required this.mediaType,
    this.width = 180,
    this.height = 120,
  });

  final String media;
  final String mediaType;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: width,
          height: height,
          child: RollFrame(media: media, mediaType: mediaType),
        ),
      ),
    );
  }
}

int? _swatch(String media) {
  if (!media.startsWith('swatch:')) return null;
  return int.tryParse(media.substring('swatch:'.length));
}

/// Picks one photo or video already on this device's camera roll.
Future<PropPhoto?> pickCameraRoll(
  BuildContext context,
  List<PropPhoto> photos,
) {
  final newest = photos.reversed.toList();
  return showModalBottomSheet<PropPhoto>(
    context: context,
    backgroundColor: const Color(0xFF1C1C1E),
    builder: (context) {
      if (newest.isEmpty) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'The camera roll is empty.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        );
      }
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(
                'Camera Roll',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              height: 220,
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: [
                  for (final photo in newest)
                    GestureDetector(
                      key: Key('roll-pick-${photo.id}'),
                      onTap: () => Navigator.pop(context, photo),
                      child: RollFrame(
                        media: rollMediaRef(photo),
                        mediaType: rollMediaType(photo),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
