import 'package:dummy_phone/app.dart';
import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/app_place.dart';
import 'package:dummy_phone/phone/catalog.dart';
import 'package:dummy_phone/phone/form_factor.dart';
import 'package:dummy_phone/phone/mac_desk.dart';
import 'package:dummy_phone/phone/tv_home.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('showing an app puts it on each computer desktop', () {
    for (final shell in ['macos', 'windows', 'linux']) {
      final os = placeShownApp(
        OsSettings(shell: shell),
        'notes',
        kind: 'computer',
        shown: true,
      );
      if (shell == 'macos') {
        expect(MacLayout.desktop(os), contains('folder:Untitled Folder'));
        expect(MacLayout.desktop(os), contains('notes'));
      } else {
        expect(deskGridIds(os), contains('folder:Untitled Folder'));
        expect(deskGridIds(os), contains('notes'));
      }
      final hidden = placeShownApp(os, 'notes', kind: 'computer', shown: false);
      final icons = shell == 'macos' ? MacLayout.desktop(hidden) : deskGridIds(hidden);
      expect(icons, isNot(contains('notes')));
    }
  });

  test('hiding a docked computer app takes it off the shelf', () {
    final hidden = placeShownApp(
      const OsSettings(),
      'music',
      kind: 'computer',
      shown: false,
    );
    expect(MacLayout.dock(hidden), isNot(contains('music')));
    final back = placeShownApp(hidden, 'music', kind: 'computer', shown: true);
    expect(MacLayout.desktop(back), contains('music'));
    expect(appSurfaceIds(_computer('macos', back)), contains('music'));
  });

  test('showing a docked phone app puts it on the home screen', () {
    const os = OsSettings(dockOrder: ['notes', 'calendar']);
    final shown = placeShownApp(os, 'notes', kind: 'phone', shown: true);
    expect(shown.homeOrder, contains('notes'));
    expect(shown.dockOrder, isNot(contains('notes')));
    expect(shown.dockOrder, contains('calendar'));
  });

  test('the phone dock stays fixed', () {
    final os = placeShownApp(const OsSettings(), 'phone', kind: 'phone', shown: true);
    expect(os.homeOrder, isEmpty);
    expect(os.dockOrder, isEmpty);
  });

  testWidgets('a shown app is drawn on the mac, windows, and ubuntu desktops', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1024, 640));
    for (final shell in ['macos', 'windows', 'linux']) {
      final store = StageStore.demo();
      addTearDown(store.dispose);
      final device = PropDevice(
        id: 'show-$shell',
        name: 'Stage $shell',
        projectId: 'sandbox',
        kind: 'computer',
        os: placeShownApp(OsSettings(shell: shell), 'notes', kind: 'computer', shown: true),
      );
      store.upsertDevice(device);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: FormOs(key: ValueKey(shell), store: store, device: device),
        ),
      );
      await tester.pump();
      final key = switch (shell) {
        'windows' => 'win-desk-notes',
        'linux' => 'linux-desk-notes',
        _ => 'mac-desk-notes',
      };
      expect(find.byKey(Key(key)), findsOneWidget, reason: shell);
      expect(tester.takeException(), isNull, reason: shell);
    }
  });

  testWidgets('the header app list puts a shown app on the mac desktop', (tester) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    final device = PropDevice(
      id: 'header-mac',
      name: 'Header mac',
      projectId: 'p-hero',
      kind: 'computer',
      locked: false,
    );
    store.upsertDevice(device);
    store.bindDevice(device.id);
    store.openTab(1);
    await tester.pumpWidget(DummyPhoneApp(store: store));
    await tester.pump();

    await tester.tap(find.byKey(const Key('os-apps')));
    await tester.pump();
    await tester.tap(find.text('Functional'));
    await tester.pump();
    final row = find.byKey(const Key('os-app-notes'));
    await tester.ensureVisible(row);
    await tester.pump();
    await tester.tap(find.descendant(of: row, matching: find.byIcon(Icons.visibility_off)));
    await tester.pump();

    expect(MacLayout.desktop(store.deviceById(device.id)!.os), contains('notes'));
    expect(find.byKey(const Key('mac-desk-notes')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('showing an app adds it to the tv row and hiding removes a tile', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    final shown = placeShownApp(const OsSettings(), 'calculator', kind: 'tv', shown: true);
    final hidden = placeShownApp(shown, 'vidtube', kind: 'tv', shown: false);
    await tester.pumpWidget(
      MaterialApp(
        home: TvHome(
          os: hidden,
          shell: 'aurora',
          onShell: (_) {},
          onOpen: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('tv-app-calculator')), findsOneWidget);
    expect(find.byKey(const Key('tv-app-vidtube')), findsNothing);
    expect(find.text('Calculator'), findsWidgets);
  });
}

PropDevice _computer(String shell, OsSettings os) => PropDevice(
  id: 'c',
  name: 'Computer',
  projectId: 'sandbox',
  kind: 'computer',
  os: os.copyWith(shell: shell),
);
