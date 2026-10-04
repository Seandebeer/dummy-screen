import 'dart:convert';

import 'place_search_web.dart' if (dart.library.io) 'place_search_io.dart'
    as net;

class PlaceHit {
  const PlaceHit({
    required this.lat,
    required this.lng,
    required this.name,
    required this.address,
  });

  final double lat;
  final double lng;
  final String name;
  final String address;
}

Future<List<PlaceHit>> searchPlaces(String query) async {
  final raw = await net.fetchPlaceJson(query);
  final data = jsonDecode(raw);
  if (data is! List) return const [];
  final hits = <PlaceHit>[];
  for (final item in data) {
    if (item is! Map) continue;
    final lat = double.tryParse('${item['lat']}');
    final lng = double.tryParse('${item['lon']}');
    if (lat == null || lng == null) continue;
    final display = item['display_name'] as String? ?? '';
    final name = display.split(',').first.trim();
    hits.add(
      PlaceHit(
        lat: lat,
        lng: lng,
        name: name.isEmpty ? 'Place' : name,
        address: display,
      ),
    );
  }
  return hits;
}
