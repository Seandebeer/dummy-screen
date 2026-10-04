import 'dart:convert';
import 'dart:io';

Future<String> fetchPlaceJson(String query) async {
  final client = HttpClient();
  try {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'json',
      'limit': '5',
      'q': query,
    });
    final request = await client.getUrl(uri);
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'DummyPhone/1.0 (prop maps)',
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw HttpException('place search ${response.statusCode}');
    }
    return body;
  } finally {
    client.close();
  }
}
