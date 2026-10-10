import 'package:dummy_phone/format.dart';
import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/clock_face.dart';
import 'package:dummy_phone/phone/home_view.dart';
import 'package:dummy_phone/phone/phone_shell.dart';
import 'package:dummy_phone/phone/settings_app.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a stopped clock stays on the set time', () {
    const os = OsSettings(clockHour: 3, clockMinute: 5);
    expect(os.clockRunning, isFalse);
    expect(formatClock(osNow(os)), '3:05');
    expect(osNow(os).second, 0);
    final later = osNow(os);
    expect(later.hour, 3);
    expect(later.minute, 5);
  });

  test('a set clock runs from the stored minute', () {
    final anchor = DateTime.now().millisecondsSinceEpoch - 120000;
    final os = OsSettings(
      clockRunning: true,
      clockSource: 'set',
      clockHour: 3,
      clockMinute: 5,
      clockAnchorMillis: anchor,
    );
    final shown = osNow(os);
    expect(shown.hour, 3);
    expect(shown.minute, 7);
  });

  test('local time runs only while the clock is started', () {
    final stopped = const OsSettings(clockSource: 'local', clockHour: 3, clockMinute: 5);
    expect(formatClock(osNow(stopped)), '3:05');
    final running = stopped.copyWith(clockRunning: true);
    final now = DateTime.now();
    expect(osNow(running).hour, now.hour);
    expect(osNow(running).minute, now.minute);
  });

  test('stopping freezes the minute that was on screen', () {
    final running = OsSettings(clockRunning: true, clockSource: 'local');
    final frozen = stopClock(running);
    final now = DateTime.now();
    expect(frozen.clockRunning, isFalse);
    expect(frozen.clockHour, now.hour);
    expect(frozen.clockMinute, now.minute);
    expect(formatClock(osNow(frozen)), formatClock(now));
  });

  testWidgets('time settings sit collapsed under the battery slider', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(420, 7000));
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(id: 'phone-clock', name: 'Hero phone', projectId: 'sandbox');
    store.upsertDevice(device);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          child: ListenableBuilder(
            listenable: store,
            builder: (context, _) => SettingsApp(
              store: store,
              device: store.deviceById(device.id)!,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('TIME'), findsOneWidget);
    expect(find.byKey(const Key('clock-style-digital')), findsNothing);
    final battery = tester.getTopLeft(find.textContaining('Battery'));
    final time = tester.getTopLeft(find.byKey(const Key('clock-section')));
    expect(time.dy, greaterThan(battery.dy));

    await tester.tap(find.byKey(const Key('clock-section')));
    await tester.pump();
    expect(find.byKey(const Key('clock-style-digital')), findsOneWidget);
    expect(find.byKey(const Key('clock-style-analog')), findsOneWidget);
    expect(find.byKey(const Key('clock-source-local')), findsOneWidget);
    expect(find.byKey(const Key('clock-source-zone')), findsOneWidget);
    expect(find.byKey(const Key('clock-source-set')), findsOneWidget);
    expect(tester.widget<Switch>(find.byKey(const Key('clock-running'))).value, isFalse);
    expect(tester.widget<Switch>(find.byKey(const Key('clock-show'))).value, isTrue);

    await tester.tap(find.byKey(const Key('clock-style-analog')));
    await tester.pump();
    expect(store.deviceById(device.id)!.os.clockStyle, 'analog');

    await tester.tap(find.byKey(const Key('clock-show')));
    await tester.pump();
    expect(store.deviceById(device.id)!.os.showClock, isFalse);
  });

  testWidgets('the status clock stays put, hides, and can be a face', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(400, 860));
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'status-clock',
      name: 'Hero phone',
      projectId: 'sandbox',
      os: const OsSettings(clockHour: 3, clockMinute: 5),
    );
    store.upsertDevice(device);

    Future<void> pump(OsSettings os) {
      return tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: PhoneShell(
            device: device.copyWith(os: os),
            onHome: () {},
            body: const SizedBox.expand(),
          ),
        ),
      );
    }

    await pump(device.os);
    expect(find.text('3:05'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('3:05'), findsOneWidget);

    await pump(device.os.copyWith(showClock: false));
    expect(find.text('3:05'), findsNothing);
    expect(find.byType(ClockFace), findsNothing);

    await pump(device.os.copyWith(clockStyle: 'analog'));
    expect(find.byType(ClockFace), findsWidgets);
    expect(find.text('3:05'), findsNothing);
  });

  testWidgets('current Android uses the ribbon home', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(400, 860));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SizedBox(
          width: 390,
          height: 800,
          child: PhoneHome(
            skin: 'android',
            os: const OsSettings(),
            onOpen: (_) {},
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('android-home')), findsOneWidget);
    expect(find.text('Seoul'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Store'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.byKey(const Key('android-search')), findsOneWidget);
    expect(find.byKey(const Key('dock-phone')), findsOneWidget);
    expect(find.byKey(const Key('dock-messages')), findsOneWidget);
    expect(find.byKey(const Key('dock-browser')), findsOneWidget);
    expect(find.byKey(const Key('dock-camera')), findsOneWidget);
    expect(find.byKey(const Key('dock-music')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
