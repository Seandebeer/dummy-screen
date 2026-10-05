import 'package:dummy_phone/app.dart';
import 'package:dummy_phone/lan_link.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the control deck delivers a text to the prop phone', (
    tester,
  ) async {
    final store = StageStore.demo();
    LanLink(store);
    await tester.binding.setSurfaceSize(const Size(1400, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(DummyPhoneApp(store: store));
    await tester.pump();

    expect(find.text('Dummy Phone'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-control')));
    await tester.pump();
    await tester.tap(find.text('Message'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('deck-message')),
      'Roll camera',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('deck-send')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('nav-os')));
    await tester.pump();
    expect(find.byKey(const Key('lock-unlock')), findsOneWidget);

    await tester.tap(find.byKey(const Key('lock-unlock')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('dock-messages')));
    await tester.pump();

    expect(find.text('Roll camera'), findsWidgets);
    expect(find.text('Sarah Chen'), findsWidgets);
  });

  testWidgets('an incoming call from the deck rings the phone', (tester) async {
    final store = StageStore.demo();
    LanLink(store);
    await tester.binding.setSurfaceSize(const Size(1400, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(DummyPhoneApp(store: store));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nav-control')));
    await tester.pump();
    await tester.tap(find.text('Call'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('deck-call')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nav-os')));
    await tester.pump();

    expect(find.text('Incoming call'), findsOneWidget);
    expect(find.text('Sarah Chen'), findsWidgets);
    await tester.tap(find.byKey(const Key('call-accept')));
    await tester.pump();
    expect(find.text('Connected'), findsOneWidget);
  });

  testWidgets('os settings follow the base44 settings screen', (tester) async {
    final store = StageStore.demo();
    LanLink(store);
    await tester.binding.setSurfaceSize(const Size(1400, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(DummyPhoneApp(store: store));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nav-os')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('lock-unlock')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('home-settings')));
    await tester.pump();

    expect(find.text('Current OS'), findsOneWidget);
    expect(find.text('Current Android'), findsOneWidget);
    expect(find.text('Graphite'), findsOneWidget);
    expect(find.text('LEGACY'), findsOneWidget);

    await tester.tap(find.byKey(const Key('skin-android')));
    await tester.pump();
    expect(store.deviceById('d-hero')!.skin, 'android');
    expect(store.deviceById('d-hero')!.os.backgroundPreset, 'droid');

    for (
      var i = 0;
      i < 12 && find.byKey(const Key('os-build-footer')).evaluate().isEmpty;
      i++
    ) {
      final origin = tester.getTopLeft(find.byKey(const Key('os-settings-list')));
      await tester.dragFrom(origin + const Offset(30, 120), const Offset(0, -450));
      await tester.pump();
    }
    expect(find.text('TAKEOVER OS · PROP BUILD 1.0'), findsOneWidget);
    expect(find.text('Factory Reset'), findsOneWidget);
  });
}
