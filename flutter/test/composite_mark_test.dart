import 'dart:ui' as ui;

import 'package:dummy_phone/app.dart';
import 'package:dummy_phone/store.dart';
import 'package:dummy_phone/vfx/composite_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ui.Image raster(String kind, {Color color = const Color(0xFFFFFFFF)}) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    paintCompositeMark(
      canvas,
      const Size(100, 100),
      kind: kind,
      color: color,
      thickness: 1,
    );
    final image = recorder.endRecording().toImageSync(100, 100);
    return image;
  }

  Future<List<int>> sample(ui.Image image, int x, int y) async {
    final bytes = (await image.toByteData())!;
    final i = (y * image.width + x) * 4;
    return [bytes.getUint8(i), bytes.getUint8(i + 1), bytes.getUint8(i + 2), bytes.getUint8(i + 3)];
  }

  test('solid tri punches a centre hole and keeps the corner dot', () async {
    final image = raster('solidtri');
    addTearDown(image.dispose);
    expect(await sample(image, 50, 52), [0, 0, 0, 0]);
    expect(await sample(image, 50, 40), [255, 255, 255, 255]);
    expect(await sample(image, 7, 7), [255, 255, 255, 255]);

    final black = raster('solidtri', color: const Color(0xFF000000));
    addTearDown(black.dispose);
    expect(await sample(black, 50, 40), [0, 0, 0, 255]);
    expect(await sample(black, 50, 52), [0, 0, 0, 0]);
  });

  test('square tri punches the inner triangle and corner squares', () async {
    final image = raster('squaretri');
    addTearDown(image.dispose);
    expect(await sample(image, 50, 40), [255, 255, 255, 255]);
    expect(await sample(image, 50, 58), [0, 0, 0, 0]);
    expect(await sample(image, 12, 12), [0, 0, 0, 0]);
    expect(await sample(image, 50, 7), [255, 255, 255, 255]);
  });

  test('inverse tri punches the upward triangle out of the solid', () async {
    final image = raster('invtri');
    addTearDown(image.dispose);
    expect(await sample(image, 50, 50), [0, 0, 0, 0]);
    expect(await sample(image, 50, 66), [255, 255, 255, 255]);
    expect(await sample(image, 8, 8), [255, 255, 255, 255]);
  });

  test('plus grid is a thick plus with pluses on the tips', () async {
    final image = raster('plusgrid');
    addTearDown(image.dispose);
    expect(await sample(image, 50, 50), [255, 255, 255, 255]);
    expect(await sample(image, 50, 6), [255, 255, 255, 255]);
    expect(await sample(image, 8, 8), [0, 0, 0, 0]);
  });

  test('dot circle, quads, squads, and crosshair fill only their shapes', () async {
    final dot = raster('dotcircle');
    addTearDown(dot.dispose);
    expect(await sample(dot, 50, 50), [255, 255, 255, 255]);
    expect(await sample(dot, 50, 24), [0, 0, 0, 0]);

    final quads = raster('quads');
    addTearDown(quads.dispose);
    expect(await sample(quads, 70, 30), [255, 255, 255, 255]);
    expect(await sample(quads, 40, 65), [255, 255, 255, 255]);
    expect(await sample(quads, 40, 35), [0, 0, 0, 0]);

    final squads = raster('squads');
    addTearDown(squads.dispose);
    expect(await sample(squads, 62, 38), [255, 255, 255, 255]);
    expect(await sample(squads, 42, 40), [0, 0, 0, 0]);
    expect(await sample(squads, 13, 13), [0, 0, 0, 0]);

    final hair = raster('crosshair');
    addTearDown(hair.dispose);
    expect(await sample(hair, 50, 50), [255, 255, 255, 255]);
    expect(await sample(hair, 35, 35), [0, 0, 0, 0]);
  });

  testWidgets('the screens stage fills the page', (tester) async {
    final store = StageStore.demo();
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(DummyPhoneApp(store: store));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nav-screens')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Hold & drag'), findsOneWidget);
    expect(find.byTooltip('Tracking marks'), findsOneWidget);
  });

  test('tri circle draws the centre and corner pluses', () async {
    final image = raster('circtriplus');
    addTearDown(image.dispose);
    expect(await sample(image, 50, 53), [255, 255, 255, 255]);
    expect(await sample(image, 8, 8), [255, 255, 255, 255]);
  });
}
