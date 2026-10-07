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
    expect(find.text('INTERFACE'), findsOneWidget);
    expect(find.text('Current OS'), findsOneWidget);
    expect(find.text('LOCK SCREEN METHOD'), findsOneWidget);
    expect(find.text('CONTACTS DIAL CODES'), findsOneWidget);
    expect(find.text('ANSWER CALLS'), findsOneWidget);
    expect(find.text('RING DURATION'), findsOneWidget);
    expect(find.text('Turn screen with device'), findsOneWidget);
    expect(find.text('Factory Reset'), findsOneWidget);

    expect(find.text('Show Control Center'), findsNothing);
    expect(find.text('DESKTOP'), findsNothing);
    expect(find.byKey(const Key('desk-shell-macos')), findsNothing);
    expect(find.text('LEGACY'), findsOneWidget);
    expect(find.text('BlackBerry'), findsNothing);

    await tester.tap(find.byKey(const Key('legacy-skins')));
    await tester.pump();
    expect(find.text('BlackBerry'), findsOneWidget);
    expect(find.text('OS 5'), findsOneWidget);
    expect(find.text('LEGACY'), findsOneWidget);
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
    expect(find.text('INTERFACE'), findsOneWidget);
    expect(find.text('TASKBAR'), findsOneWidget);
    expect(find.text('STATUS BAR'), findsNothing);
    expect(find.text('WALLPAPER'), findsOneWidget);
    expect(find.text('APP BRANDING'), findsOneWidget);
    expect(find.text('CUSTOM ICONS'), findsOneWidget);
    expect(find.text('Factory Reset'), findsOneWidget);

    expect(find.text('CONTACTS DIAL CODES'), findsNothing);
    expect(find.text('RING DURATION'), findsNothing);
    expect(find.text('LOCK SCREEN METHOD'), findsNothing);
    expect(find.text('Turn screen with device'), findsNothing);
    // The menu bar and the icon arrangement belong to the Mac desktop.
    expect(find.text('MENU BAR'), findsNothing);
    expect(find.text('DOCK'), findsNothing);

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

    expect(find.text('MENU BAR'), findsOneWidget);
    expect(find.text('Show Control Center'), findsOneWidget);
    expect(find.text('DOCK'), findsOneWidget);
    expect(find.text('DESKTOP'), findsOneWidget);

    await tester.tap(find.byKey(const Key('desk-dock-right-word')));
    await tester.tap(find.byKey(const Key('desk-dock-desk-music')));
    await tester.tap(find.byKey(const Key('desk-nudge-left-folder:Untitled Folder')));
    await tester.pump();
    expect(moved, ['word:1', 'desktop:music', 'nudge:folder:Untitled Folder']);

    await tester.tap(find.byKey(const Key('desk-status-wifi')));
    await tester.pump();
    expect(store.deviceById(device.id)?.os.wifi, isFalse);

    await tester.tap(find.byKey(const Key('desk-battery-down')));
    await tester.pump();
    expect(store.deviceById(device.id)?.os.battery, 70);
    expect(tester.takeException(), isNull);
  });
}
