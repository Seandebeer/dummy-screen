import 'package:dummy_phone/app.dart';
import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/catalog.dart';
import 'package:dummy_phone/phone/desk_os_apps.dart';
import 'package:dummy_phone/phone/form_factor.dart';
import 'package:dummy_phone/phone/home_view.dart';
import 'package:dummy_phone/phone/mac_desk.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The functional apps every interface starts with: four in the dock and
/// twenty on the first home page, matching `defaultHomeOrder` on the web.
const _functional = [...kDockIds, ...kHomeOrder];

void main() {
  test('page one carries every functional app', () {
    final page = homePageOne();
    expect(page.length, kPageSize);
    expect(kDockIds.length, 4);
    for (final id in page) {
      expect(propAppById(id), isNotNull, reason: id);
      expect(kDockIds.contains(id), isFalse, reason: id);
    }
    expect(_functional.take(24).toSet().length, 24);
  });

  testWidgets('a phone and a tablet open with the same first page', (
    tester,
  ) async {
    Future<List<String>> icons(Size size, {required bool wide}) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PhoneHome(
              skin: 'ios',
              os: const OsSettings(),
              wide: wide,
              onOpen: (_) {},
            ),
          ),
        ),
      );
      final found = <String>[];
      for (final id in homePageOne()) {
        if (tester.any(find.byKey(Key('home-$id')))) found.add(id);
      }
      for (final id in kDockIds) {
        expect(find.byKey(Key('dock-$id')), findsOneWidget, reason: id);
      }
      return found;
    }

    addTearDown(() => tester.binding.setSurfaceSize(null));
    expect(await icons(const Size(390, 844), wide: false), homePageOne());
    expect(await icons(const Size(834, 1112), wide: true), homePageOne());
  });

  test('a computer desktop starts with the same apps plus the desk tools', () {
    final ids = [for (final app in deskApps(const OsSettings())) app.$1];
    expect(ids.take(kPageSize).toList(), homePageOne());
    expect(ids, containsAll(['word', 'excel', 'terminal']));

    final mac = MacLayout.defaultDesktop();
    for (final id in homePageOne()) {
      expect(
        mac.contains(id) || kMacDockIds.contains(id),
        isTrue,
        reason: id,
      );
    }
  });

  testWidgets('every shared app has a desktop build that fits a window', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'desk-apps',
      name: 'Stage pc',
      projectId: 'sandbox',
      kind: 'computer',
    );
    store.upsertDevice(device);
    store.addPhoto(device.id, 0xFF318DF6);
    for (final size in [const Size(560, 360), const Size(460, 280)]) {
      await tester.binding.setSurfaceSize(size);
      for (final id in [...kDockIds, ...homePageOne()]) {
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: StoreScope(
              store: store,
              child: DeskAppView(
                store: store,
                device: device,
                appId: id,
                onOpen: (_, {String? thread}) {},
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$id at $size');
      }
    }
  });

  testWidgets('the desktop apps drive the same store as the phone', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(560, 360));
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'desk-store',
      name: 'Stage pc',
      projectId: 'sandbox',
      kind: 'computer',
    );
    store.upsertDevice(device);
    store.sendMessage(
      deviceId: device.id,
      sender: 'deck',
      text: 'Picture is up.',
      senderName: 'Unit',
      thread: 'Unit',
    );

    Future<void> open(String id) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: StoreScope(
            store: store,
            child: DeskAppView(
              store: store,
              device: store.deviceById(device.id)!,
              appId: id,
              onOpen: (_, {String? thread}) {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await open('messages');
    expect(find.text('Picture is up.'), findsWidgets);
    await tester.enterText(find.byKey(const Key('desk-reply')), 'Copy that.');
    await tester.tap(find.byKey(const Key('desk-send')));
    await tester.pump();
    expect(
      store.messagesFor(device.id).any((item) => item.text == 'Copy that.'),
      isTrue,
    );

    await open('notes');
    await tester.enterText(find.byKey(const Key('desk-note')), 'Scene 47 beat');
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.deviceById(device.id)?.notes, 'Scene 47 beat');

    await open('phone');
    await tester.tap(find.byKey(const Key('desk-dial-Elena Frost')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('desk-call')));
    await tester.pump();
    expect(store.callFor(device.id)?.contactNumber, '049 555 0177');
    store.endCall(device.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every computer shell opens a shared app in a window', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1180, 760));
    for (final shell in ['macos', 'windows', 'linux']) {
      final store = StageStore.demo();
      addTearDown(store.dispose);
      final device = PropDevice(
        id: 'desk-$shell',
        name: 'Stage $shell',
        projectId: 'sandbox',
        kind: 'computer',
        os: OsSettings(shell: shell),
      );
      store.upsertDevice(device);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: FormOs(
          key: ValueKey(shell),
          store: store,
          device: device,
        ),
        ),
      );
      final calculator = find.byKey(
        Key(
          switch (shell) {
            'windows' => 'win-icon-calculator',
            'linux' => 'linux-icon-calculator',
            _ => 'mac-desk-calculator',
          },
        ),
      );
      await tester.ensureVisible(calculator);
      await tester.tap(calculator);
      await tester.pump();
      expect(find.text('AC'), findsOneWidget, reason: shell);
      expect(find.text('Tape'), findsOneWidget, reason: shell);
      await tester.tap(find.text('7'));
      await tester.tap(find.text('+'));
      await tester.tap(find.text('5'));
      await tester.tap(find.text('='));
      await tester.pump();
      expect(find.text('12'), findsOneWidget, reason: shell);
      expect(tester.takeException(), isNull, reason: shell);
    }
  });
}
