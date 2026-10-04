import 'package:dummy_phone/phone/app_catalog.dart';
import 'package:dummy_phone/phone/social_feed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('social feeds and the app catalog match the Base44 defaults', () {
    expect(grapevinePosts(), hasLength(20));
    expect(lumePosts(), hasLength(20));
    expect(streamlyVideos(), hasLength(20));
    expect(flickdeckPosts(), hasLength(20));
    expect(mockCatalog.fold<int>(0, (n, section) => n + section.apps.length), 200);

    final topped = topUpFeed([
      {'id': 'fp-1', 'text': 'kept'},
    ], grapevinePosts());
    expect(topped, hasLength(20));
    expect(topped.first['text'], 'kept');
    expect(topped.first['id'], 'fp-1');
    expect(topped[1]['id'], 'fp-2');
  });
}
