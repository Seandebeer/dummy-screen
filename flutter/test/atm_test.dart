import 'package:dummy_phone/format.dart';
import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/atm_chrome.dart';
import 'package:dummy_phone/phone/atm_home.dart';
import 'package:dummy_phone/phone/form_factor.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _digits(WidgetTester tester, String pin) async {
  if (find.byKey(const Key('atm-welcome')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('atm-welcome')));
    await tester.pump();
  }
  for (final digit in pin.split('')) {
    await tester.tap(find.byKey(Key('atm-digit-$digit')));
    await tester.pump();
  }
}

void main() {
  test('standard notes make 40 and 70 but not 30', () {
    expect(atmCanDispense(40, kAtmDefaultNotes), isTrue);
    expect(atmCanDispense(70, kAtmDefaultNotes), isTrue);
    expect(atmCanDispense(20, kAtmDefaultNotes), isTrue);
    expect(atmCanDispense(30, kAtmDefaultNotes), isFalse);
    expect(parseAtmNotes('100, 20, 20, 50'), [20, 50, 100]);
  });

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
    expect(find.byKey(const Key('atm-welcome')), findsOneWidget);
    expect(find.byKey(const Key('atm-enter-pin')), findsNothing);
    expect(find.text('Please select your transaction'), findsNothing);
    expect(find.text('Northline Mutual'), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);

    await tester.tap(find.byKey(const Key('atm-welcome')));
    await tester.pump();
    expect(find.byKey(const Key('atm-enter-pin')), findsOneWidget);

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
    expect(find.text('Please wait'), findsOneWidget);
    expect(store.deviceById('atm-1')!.os.bankBalance, 2460);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('USD 20'), findsWidgets);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Please remove your card'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Please remove your cash'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Please take your receipt'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Thank you'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('atm-welcome')), findsOneWidget);

    await tester.tap(find.byKey(const Key('atm-service')));
    await tester.pump();
    expect(find.text('Out of service'), findsOneWidget);
    await tester.tap(find.byKey(const Key('atm-restore')));
    await tester.pump();
    expect(find.byKey(const Key('atm-welcome')), findsOneWidget);
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
    expect(find.text('USD 10'), findsOneWidget);
    final balance = tester.widget<Text>(find.text('USD 10'));
    expect(balance.style!.fontSize, greaterThan(40));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Another transaction'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('atm-withdraw')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('atm-account-checking')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('atm-amount-20')));
    await tester.pump();
    expect(find.text('Insufficient funds.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Please select your transaction'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('atm settings changes skin, currency, language, and layout', (
    tester,
  ) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    final device = PropDevice(
      id: 'atm-1',
      name: 'Lobby atm',
      projectId: 'sandbox',
      kind: 'atm',
      os: const OsSettings(
        backgroundType: 'image',
        backgroundUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      ),
    );
    store.upsertDevice(device);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AtmScreen(store: store, device: device),
      ),
    );
    expect(find.byKey(const Key('atm-custom-background')), findsOneWidget);
    await _digits(tester, '11111');
    expect(find.text('PIN Change'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byKey(const Key('atm-settings')));
    await tester.pump();
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Bank name'), findsOneWidget);
    expect(find.text('User name'), findsOneWidget);
    expect(find.text('Account balance'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Temperature'), findsOneWidget);
    expect(find.text('Note sizes'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('atm-bank-name')),
      'Harbor Trust',
    );
    await tester.pump();
    expect(store.deviceById('atm-1')!.os.bankName, 'Harbor Trust');
    await tester.enterText(
      find.byKey(const Key('atm-user-name')),
      'Mara Quinn',
    );
    await tester.pump();
    expect(store.deviceById('atm-1')!.os.bankHolder, 'Mara Quinn');
    await tester.enterText(
      find.byKey(const Key('atm-account-balance')),
      '5000',
    );
    await tester.pump();
    expect(store.deviceById('atm-1')!.os.bankBalance, 5000);

    await tester.ensureVisible(find.byKey(const Key('atm-time')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('atm-time')), '21:15');
    await tester.pump();
    final shown = propNow(store.deviceById('atm-1')!.clockOffsetMinutes);
    expect(shown.hour, 21);
    expect(shown.minute, 15);
    await tester.enterText(find.byKey(const Key('atm-temperature')), '27');
    await tester.pump();
    expect(store.deviceById('atm-1')!.os.temperature, 27);
    expect(find.byKey(const Key('atm-upload-background')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('atm-skin-gold')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('atm-skin-gold')));
    await tester.pump();
    expect(store.deviceById('atm-1')!.os.shell, 'gold');

    expect(kAtmCurrencies.length, greaterThanOrEqualTo(150));
    expect(
      kAtmCurrencies.map((item) => item.code),
      containsAll(['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'UYU', 'XOF', 'ZWG']),
    );

    await tester.ensureVisible(find.byKey(const Key('atm-currency')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('atm-currency')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('atm-currency-UAH')));
    await tester.pumpAndSettle();
    expect(store.deviceById('atm-1')!.os.bankCurrency, 'UAH');
    expect(find.textContaining('UAH — Ukrainian hryvnia'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('atm-notes')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('atm-notes')), '10, 20, 50');
    await tester.pump();
    expect(store.deviceById('atm-1')!.os.bankNotes, [10, 20, 50]);

    await tester.ensureVisible(find.byKey(const Key('atm-language-es')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('atm-language-es')));
    await tester.pump();
    expect(store.deviceById('atm-1')!.os.language, 'es');

    await tester.ensureVisible(find.byKey(const Key('atm-remove-background')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('atm-remove-background')));
    await tester.pump();
    expect(store.deviceById('atm-1')!.os.backgroundType, 'preset');
    expect(find.byKey(const Key('atm-custom-background')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('atm-edit-layout')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('atm-edit-layout')));
    await tester.pump();
    expect(
      find.text('Toque dos paneles para intercambiarlos.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('atm-withdraw')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('atm-balance')));
    await tester.pump();
    expect(store.deviceById('atm-1')!.os.homeOrder.first, 'balance');
    await tester.tap(find.byKey(const Key('atm-layout-done')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('atm-settings-done')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('atm-settings-done')));
    await tester.pump();
    expect(find.text('Seleccione su transacción'), findsOneWidget);
    expect(find.text('Harbor Trust'), findsOneWidget);
    expect(find.textContaining('Mara Quinn'), findsOneWidget);
    expect(find.textContaining('21:15'), findsOneWidget);
    expect(find.text('27°C'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('atm-slot-0')),
        matching: find.text('Consulta de saldo'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a custom withdrawal must match the note sizes', (tester) async {
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
    await _digits(tester, '12345');
    await tester.tap(find.byKey(const Key('atm-withdraw')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('atm-account-checking')));
    await tester.pump();
    expect(find.byKey(const Key('atm-amount-20')), findsOneWidget);
    expect(find.byKey(const Key('atm-amount-50')), findsOneWidget);
    expect(find.byKey(const Key('atm-amount-100')), findsOneWidget);
    expect(find.byKey(const Key('atm-amount-40')), findsNothing);
    expect(find.byKey(const Key('atm-custom-amount')), findsNothing);

    await tester.tap(find.byKey(const Key('atm-custom-open')));
    await tester.pump();
    expect(find.text('Custom amount'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('atm-custom-amount')), '30');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('atm-custom-use')));
    await tester.tap(find.byKey(const Key('atm-custom-use')));
    await tester.pump();
    expect(
      find.text('That amount cannot be made from these notes.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Back'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('atm-custom-amount')), '40');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('atm-custom-use')));
    await tester.tap(find.byKey(const Key('atm-custom-use')));
    await tester.pump();
    expect(find.text('Confirm withdrawal'), findsOneWidget);
    await tester.tap(find.byKey(const Key('atm-confirm')));
    await tester.pump();
    expect(store.deviceById('atm-1')!.os.bankBalance, 2440);
    expect(tester.takeException(), isNull);
  });
}
