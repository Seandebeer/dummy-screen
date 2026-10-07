import 'package:dummy_phone/phone/route_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a straight leg reports distance, heading, and arrival', () {
    expect(haversine(-26.2, 28.0, -26.2, 28.0), 0);
    final route = buildRoute([
      (lat: -26.2041, lng: 28.0473),
      (lat: -26.2041, lng: 28.0573),
    ]);
    expect(route, isNotNull);
    expect(route!.total, greaterThan(900));
    expect(compass(route.legs.single.bearing), 'east');
    final start = positionAt(route, 0)!;
    expect(start.legIndex, 0);
    final end = positionAt(route, route.total)!;
    expect(end.lat, closeTo(-26.2041, 0.0001));
    expect(fmtDist(route.total), endsWith('km'));
    expect(turnName(0), 'Continue straight');
    expect(turnName(90), 'Turn right');
  });
}
