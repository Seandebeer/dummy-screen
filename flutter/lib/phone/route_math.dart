import 'dart:math' as math;

const _earth = 6371000.0;
const _dirs = [
  'north',
  'northeast',
  'east',
  'southeast',
  'south',
  'southwest',
  'west',
  'northwest',
];

double haversine(double lat1, double lng1, double lat2, double lng2) {
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final x =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earth * math.asin(math.sqrt(x));
}

double bearing(double lat1, double lng1, double lat2, double lng2) {
  final y = math.sin(_rad(lng2 - lng1)) * math.cos(_rad(lat2));
  final x =
      math.cos(_rad(lat1)) * math.sin(_rad(lat2)) -
      math.sin(_rad(lat1)) * math.cos(_rad(lat2)) * math.cos(_rad(lng2 - lng1));
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

class RouteLeg {
  const RouteLeg({
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.length,
    required this.bearing,
    required this.turnDelta,
  });

  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final double length;
  final double bearing;
  final double turnDelta;
}

class RoutePath {
  const RoutePath({required this.legs, required this.total});

  final List<RouteLeg> legs;
  final double total;
}

RoutePath? buildRoute(List<({double lat, double lng})> points) {
  if (points.length < 2) return null;
  final legs = <RouteLeg>[];
  var total = 0.0;
  for (var i = 0; i < points.length - 1; i++) {
    final from = points[i];
    final to = points[i + 1];
    final len = haversine(from.lat, from.lng, to.lat, to.lng);
    final head = bearing(from.lat, from.lng, to.lat, to.lng);
    final prev = legs.isEmpty ? null : legs.last.bearing;
    final turn = prev == null ? 0.0 : ((head - prev + 540) % 360) - 180;
    legs.add(
      RouteLeg(
        fromLat: from.lat,
        fromLng: from.lng,
        toLat: to.lat,
        toLng: to.lng,
        length: len,
        bearing: head,
        turnDelta: turn,
      ),
    );
    total += len;
  }
  return RoutePath(legs: legs, total: total);
}

class RouteFix {
  const RouteFix({
    required this.lat,
    required this.lng,
    required this.legIndex,
    required this.bearing,
    required this.legRemaining,
  });

  final double lat;
  final double lng;
  final int legIndex;
  final double bearing;
  final double legRemaining;
}

RouteFix? positionAt(RoutePath route, double dist) {
  if (route.legs.isEmpty) return null;
  final d = dist.clamp(0, route.total).toDouble();
  var acc = 0.0;
  for (var i = 0; i < route.legs.length; i++) {
    final leg = route.legs[i];
    if (d <= acc + leg.length || i == route.legs.length - 1) {
      final t = leg.length == 0
          ? 0.0
          : ((d - acc) / leg.length).clamp(0, 1).toDouble();
      return RouteFix(
        lat: leg.fromLat + (leg.toLat - leg.fromLat) * t,
        lng: leg.fromLng + (leg.toLng - leg.fromLng) * t,
        legIndex: i,
        bearing: leg.bearing,
        legRemaining: leg.length * (1 - t),
      );
    }
    acc += leg.length;
  }
  return null;
}

String compass(double deg) {
  final wrapped = ((deg % 360) + 360) % 360;
  return _dirs[(wrapped / 45).round() % 8];
}

String turnName(double delta) {
  final d = delta.abs();
  if (d < 20) return 'Continue straight';
  if (d < 55) return delta > 0 ? 'Keep right' : 'Keep left';
  if (d < 140) return delta > 0 ? 'Turn right' : 'Turn left';
  return 'Make a U-turn';
}

String fmtDist(double meters) {
  if (meters < 950) {
    final rounded = math.max(10, (meters / 10).round() * 10);
    return '$rounded m';
  }
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

String fmtEta(double seconds) {
  final s = math.max(0, seconds.round());
  if (s < 3600) {
    final m = s ~/ 60;
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }
  return '${s ~/ 3600}h ${(s % 3600) ~/ 60}m';
}

double _rad(double deg) => deg * math.pi / 180;
