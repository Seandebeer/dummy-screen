import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/atm_home.dart';
import 'package:dummy_phone/phone/form_factor.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an atm uses a landscape ipad frame', () {
    final metrics = metricsFor('atm');
    expect(metrics.aspect, 4 / 3);
    expect(metrics.frame, 'kiosk');
  });

  testWidgets('the atm opens on the transaction dashboard', (tester) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    final device = PropDevice(
      id: 'atm-1',
      name: 'Lobby atm',
      projectId: 'sandbox',
      kind: 'atm',
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AtmScreen(store: store, device: device),
      ),
    );
    expect(find.byKey(const Key('atm-home')), findsOneWidget);
    expect(find.text('Northline Mutual'), findsOneWidget);
    expect(find.text('Please select your transaction'), findsOneWidget);
    expect(find.textContaining('Good '), findsOneWidget);
    expect(find.text('A. Ellis'), findsNothing);
    expect(find.textContaining('A. Ellis'), findsOneWidget);

    await tester.tap(find.byKey(const Key('atm-withdraw')));
    await tester.pump();
    expect(find.text('Money Withdrawal'), findsOneWidget);
    await tester.tap(find.byKey(const Key('atm-amount-20')));
    await tester.pump();
    expect(find.text('Confirmed'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.text('Please select your transaction'), findsOneWidget);

    await tester.tap(find.byKey(const Key('atm-service')));
    await tester.pump();
    expect(find.text('Out of service'), findsOneWidget);
    await tester.tap(find.byKey(const Key('atm-restore')));
    await tester.pump();
    expect(find.text('Please select your transaction'), findsOneWidget);
  });

  testWidgets('the atm dashboard fits a short landscape frame', (tester) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(640, 480));
    final device = PropDevice(
      id: 'atm-short',
      name: 'Lobby atm',
      projectId: 'sandbox',
      kind: 'atm',
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AtmScreen(store: store, device: device),
      ),
    );
    expect(find.byKey(const Key('atm-home')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('atm-balance')));
    await tester.pump();
    expect(find.text('Balance Inquiry'), findsOneWidget);
    expect(find.textContaining('2480'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
