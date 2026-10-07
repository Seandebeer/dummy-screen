import 'package:dummy_phone/vfx/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('marker snap lines sit in the button gaps and on the centre', () {
    final lines = markerSnapLines(604, 904);
    expect(lines.xs, hasLength(6));
    expect(lines.ys, hasLength(8));
    expect(lines.xs.first, closeTo(102, 0.01));
    expect(lines.xs.last, 302);
    expect(
      snapMarkerPercent(100, 604, lines.xs),
      closeTo(102 / 604 * 100, 0.01),
    );
    expect(snapMarkerPercent(99, 100, [99]), 98);
    expect(snapMarkerPercent(1, 100, [1]), 2);
  });
}