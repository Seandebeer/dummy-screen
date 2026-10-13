import 'package:dummy_phone/app.dart';
import 'package:dummy_phone/screens/vfx_page.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a horizontal swipe cycles the stage colour', (tester) async {
    final store = StageStore.demo();
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      StoreScope(
        store: store,
        child: const MaterialApp(home: VfxPage()),
      ),
    );
    await tester.pump();

    expect(store.screenConfig['colorId'], anyOf(isNull, 'green'));
    // Marks sit on the centre and corners, so the swipe starts on empty stage.
    await tester.flingFrom(const Offset(240, 400), const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
    expect(store.screenConfig['colorId'], 'blue');

    await tester.flingFrom(const Offset(240, 400), const Offset(300, 0), 1500);
    await tester.pumpAndSettle();
    expect(store.screenConfig['colorId'], 'green');
  });
}
