import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/atm_home.dart';
import 'package:dummy_phone/phone/form_factor.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _digits(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.byKey(Key('atm-digit-$digit')));
    await tester.pump();
  }
}

void main() {
  test('an atm uses a landscape ipad frame', () {
    final metrics = metricsFor('atm');
    expect(metrics.aspect, 4 / 3);
    expect(metrics.frame, 'kiosk');
  });

  testWidgets('the atm opens on a 5 digit pin', (tester) async {
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
    store.upsertDevice(device);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AtmScreen(store: store, device: device),
      ),
    );
    expect(find.byKey(const Key('atm-enter-pin')), findsOneWidget);
    expect(find.text('Please select your transaction'), findsNothing);
    expect(find.text('Northline Mutual'), findsOneWidget);

    await _digits(tester, '9999');
    expect(find.byKey(const Key('atm-enter-pin')), findsOneWidget);

    await tester.tap(find.byKey(const Key('atm-digit-1')));
    await tester.pump();
    expect(find.text('Please select your transaction'), findsOneWidget);
    expect(find.textContaining('A. Ellis'), findsOneWidget);

    await tester.tap(find.byKey(const Key('atm-withdraw')));
    await tester.pump();
    expect(find.text('Which account?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('atm-account-checking')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('atm-amount-20')));
    await tester.pump();
    expect(find.text('Confirm withdrawal'), findsOneWidget);
    await tester.tap(find.byKey(const Key('atm-confirm')));
    await tester.pump();
    expect(find.text('Please take your cash'), findsOneWidget);
    expect(store.deviceById('atm-1')!.os.bankBalance, 2460);

    await tester.tap(find.byKey(const Key('atm-cash-taken')));
    await tester.pump();
    expect(find.text('Would you like a receipt?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('atm-no-receipt')));
    await tester.pump();
    expect(find.text('Another transaction?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('atm-no-another')));
    await tester.pump();
    expect(find.text('Please take your card'), findsOneWidget);
    await tester.tap(find.byKey(const Key('atm-card-done')));
    await tester.pump();
    expect(find.byKey(const Key('atm-enter-pin')), findsOneWidget);

    await tester.tap(find.byKey(const Key('atm-service')));
    await tester.pump();
    expect(find.text('Out of service'), findsOneWidget);
    await tester.tap(find.byKey(const Key('atm-restore')));
    await tester.pump();
    expect(find.byKey(const Key('atm-enter-pin')), findsOneWidget);
  });

  testWidgets('a short landscape frame still takes a withdrawal pin', (
    tester,
  ) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(640, 480));
    final device = PropDevice(
      id: 'atm-short',
      name: 'Lobby atm',
      projectId: 'sandbox',
      kind: 'atm',
      os: const OsSettings(bankBalance: 10),
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AtmScreen(store: store, device: device),
      ),
    );
    expect(tester.takeException(), isNull);
    await _digits(tester, '00000');
    expect(find.text('Please select your transaction'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('atm-balance')));
    await tester.pump();
    expect(find.text('Balance Inquiry'), findsOneWidget);
    expect(find.textContaining('10'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Another transaction'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('atm-withdraw')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('atm-account-checking')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('atm-amount-20')));
    await tester.pump();
    expect(find.text('That amount is not available.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
