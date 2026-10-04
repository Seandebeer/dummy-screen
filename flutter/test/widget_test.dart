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
    await tester.enterText(
      find.byKey(const Key('deck-message')),
      'Roll camera',
    );
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
}
