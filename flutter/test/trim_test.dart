import 'package:dummy_phone/trim_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trim handles keep at least half a second', () {
    final inward = moveTrim(
      startEdge: true,
      at: 9000,
      start: 0,
      end: 4000,
      duration: 4000,
    );
    expect(inward.start, 3500);
    expect(inward.end, 4000);

    final outward = moveTrim(
      startEdge: false,
      at: 100,
      start: 1000,
      end: 4000,
      duration: 4000,
    );
    expect(outward.start, 1000);
    expect(outward.end, 1500);
    expect(clampSeek(0, 1000, 4000), 1000);
    expect(clampSeek(5000, 1000, 4000), 4000);
    expect(clampSeek(2000, 1000, 4000), 2000);
  });
}
