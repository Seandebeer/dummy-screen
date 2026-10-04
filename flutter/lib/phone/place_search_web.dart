import 'dart:js_interop';

import 'package:web/web.dart';

Future<String> fetchPlaceJson(String query) async {
  final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
    'format': 'json',
    'limit': '5',
    'q': query,
  });
  final response = await window.fetch(uri.toString().toJS).toDart;
  if (!response.ok) throw StateError('place search failed');
  return (await response.text().toDart).toDart;
}
