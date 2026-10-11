import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/desk_settings.dart';
import 'package:dummy_phone/phone/settings_app.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Settings carries the settings the device in front of you has. The surface
/// is tall enough to build the whole scroll, so a section that is missing is
/// missing because that device does not have it.
void main() {
  testWidgets('a phone keeps the phone settings', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(420, 7000));
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'phone-settings',
      name: 'Hero phone',
      projectId: 'sandbox',
    );
    store.upsertDevice(device);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(child: SettingsApp(store: store, device: device)),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('os-build-footer')), findsOneWidget);
    expect(find.text('Display'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Lock'), findsOneWidget);
    expect(find.text('Calls'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Apps'), findsOneWidget);
    expect(find.text('Factory Reset'), findsOneWidget);
    expect(find.text('Current OS'), findsNothing);
    expect(find.text('Turn screen with device'), findsNothing);

    expect(find.text('Show Control Center'), findsNothing);
    expect(find.byKey(const Key('desk-shell-macos')), findsNothing);
    expect(find.text('Nokia Belle'), findsNothing);
    expect(find.text('BlackBerry'), findsNothing);

    await tester.tap(find.byKey(const Key('settings-cat-display')));
    await tester.pump();
    expect(find.text('Current OS'), findsOneWidget);
    expect(find.text('Legacy'), findsOneWidget);
    expect(find.text('Turn screen with device'), findsOneWidget);

    await tester.tap(find.byKey(const Key('legacy-skins')));
    await tester.pump();
    expect(find.text('iPhone OS'), findsOneWidget);
    expect(find.text('iOS 6'), findsOneWidget);
    expect(find.text('iOS 7'), findsOneWidget);
    expect(find.text('Windows Phone'), findsOneWidget);
    expect(find.text('Android Holo'), findsOneWidget);
    expect(find.text('webOS'), findsOneWidget);
    expect(find.text('Nokia Belle'), findsOneWidget);
    expect(find.text('OS 5'), findsNothing);
    expect(find.text('BlackBerry'), findsNothing);
    expect(find.text('Legacy'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-back')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('settings-cat-calls')));
    await tester.pump();
    expect(find.text('Contacts Dial Codes'), findsOneWidget);
    expect(find.text('Answer Calls'), findsOneWidget);
    expect(find.text('Ring duration'), findsOneWidget);
  });

  testWidgets('a computer keeps the computer settings', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(520, 5000));
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'computer-settings',
      name: 'Stage pc',
      projectId: 'sandbox',
      kind: 'computer',
      os: const OsSettings(shell: 'windows'),
    );
    store.upsertDevice(device);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          child: ComputerSettings(store: store, device: device),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('os-build-footer')), findsOneWidget);
    expect(find.text('Display'), findsOneWidget);
    expect(find.text('Taskbar'), findsOneWidget);
    expect(find.text('Status bar'), findsNothing);
    expect(find.text('Wallpaper'), findsNothing);
    expect(find.text('Factory Reset'), findsOneWidget);

    expect(find.text('Contacts Dial Codes'), findsNothing);
    expect(find.text('Ring duration'), findsNothing);
    expect(find.text('Turn screen with device'), findsNothing);
    expect(find.text('Menu bar'), findsNothing);
    expect(find.text('Dock'), findsNothing);

    await tester.tap(find.byKey(const Key('desk-cat-display')));
    await tester.pump();
    expect(find.text('Interface'), findsOneWidget);
    expect(find.text('Wallpaper'), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings-back')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('desk-cat-apps')));
    await tester.pump();
    expect(find.text('App branding'), findsOneWidget);
    expect(find.text('Custom apps'), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings-back')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('desk-cat-display')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('desk-shell-macos')));
    await tester.pump();
    expect(store.deviceById(device.id)?.os.shell, 'macos');
  });

  testWidgets('the mac settings arrange the dock and the desktop', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(520, 9000));
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'mac-settings',
      name: 'Stage mac',
      projectId: 'sandbox',
      kind: 'computer',
      os: const OsSettings(shell: 'macos'),
    );
    store.upsertDevice(device);
    final moved = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          child: ComputerSettings(
            store: store,
            device: device,
            onShiftDock: (id, delta) => moved.add('$id:$delta'),
            onToDesktop: (id) => moved.add('desktop:$id'),
            onToDock: (id) => moved.add('dock:$id'),
            onNudge: (id, dx, dy) => moved.add('nudge:$id'),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('desk-cat-bar')));
    await tester.pump();
    expect(find.text('Menu bar'), findsWidgets);
    expect(find.text('Show Control Center'), findsOneWidget);
    await tester.tap(find.byKey(const Key('desk-status-wifi')));
    await tester.pump();
    expect(store.deviceById(device.id)?.os.wifi, isFalse);
    await tester.tap(find.byKey(const Key('desk-battery-down')));
    await tester.pump();
    expect(store.deviceById(device.id)?.os.battery, 70);

    await tester.tap(find.byKey(const Key('settings-back')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('desk-cat-layout')));
    await tester.pump();
    expect(find.text('Dock'), findsWidgets);
    expect(find.text('Desktop'), findsWidgets);

    await tester.tap(find.byKey(const Key('desk-dock-right-word')));
    await tester.tap(find.byKey(const Key('desk-dock-desk-music')));
    await tester.tap(find.byKey(const Key('desk-nudge-left-folder:Untitled Folder')));
    await tester.pump();
    expect(moved, ['word:1', 'desktop:music', 'nudge:folder:Untitled Folder']);
    expect(tester.takeException(), isNull);
  });
}
