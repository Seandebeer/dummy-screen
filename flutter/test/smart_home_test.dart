import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/form_factor.dart';
import 'package:dummy_phone/phone/smart_home.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smart home has a wall panel and a phone screen', () {
    final wall = metricsFor('smarthome');
    expect(wall.aspect, 4 / 3);
    expect(wall.frame, 'panel');
    final phone = metricsFor('homephone');
    expect(phone.aspect, 390 / 844);
    expect(phone.frame, 'phone');
  });

  testWidgets('the wall panel toggles lights and an away scene', (
    tester,
  ) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    final device = PropDevice(
      id: 'home-1',
      name: 'Harbor panel',
      projectId: 'sandbox',
      kind: 'smarthome',
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePanel(store: store, device: device),
      ),
    );
    expect(find.byKey(const Key('home-wall')), findsOneWidget);
    expect(find.text('Smart home'), findsOneWidget);
    expect(find.text('On'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('home-lights')));
    await tester.pump();
    expect(find.text('Off'), findsWidgets);

    await tester.tap(find.byKey(const Key('home-scene-away')));
    await tester.pump();
    expect(store.alarms['home-1'], isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the phone panel fits a vertical phone frame', (tester) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final device = PropDevice(
      id: 'home-phone',
      name: 'Harbor phone',
      projectId: 'sandbox',
      kind: 'homephone',
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePanel(store: store, device: device, portrait: true),
      ),
    );
    expect(find.byKey(const Key('home-phone')), findsOneWidget);
    expect(find.text('Smart home'), findsOneWidget);
    expect(find.byKey(const Key('home-lights')), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-temp-up')));
    await tester.pump();
    expect(find.text('22°'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
