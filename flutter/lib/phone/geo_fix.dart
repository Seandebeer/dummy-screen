import 'geo_fix_web.dart' if (dart.library.io) 'geo_fix_io.dart' as geo;

Future<({double lat, double lng})?> currentFix() => geo.currentFix();
