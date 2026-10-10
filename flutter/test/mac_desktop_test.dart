import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/form_factor.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the mac desktop keeps files on the right and apps in the dock', (
    tester,
  ) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1024, 640));
    final device = PropDevice(
      id: 'mac-1',
      name: 'Stage mac',
      projectId: 'sandbox',
      kind: 'computer',
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FormOs(store: store, device: device),
      ),
    );
    expect(find.byKey(const Key('mac-desktop')), findsOneWidget);
    expect(find.text('Finder'), findsOneWidget);
    expect(find.text('Untitled Folder'), findsOneWidget);
    expect(find.text('Documents'), findsNothing);
    expect(find.text('Insert card to begin.'), findsNothing);

    final folder = tester.getCenter(
      find.byKey(const Key('mac-file-Untitled Folder')),
    );
    final finder = tester.getCenter(find.text('Finder'));
    expect(folder.dx, greaterThan(finder.dx));

    await tester.tap(find.byKey(const Key('mac-file-Untitled Folder')));
    await tester.pump();
    expect(find.text('Scene 47.txt'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mac-window-close')));
    await tester.pump();
    expect(find.text('Scene 47.txt'), findsNothing);

    await tester.tap(find.byKey(const Key('mac-dock-word')));
    await tester.pump();
    expect(find.text('Word'), findsWidgets);
    expect(
      find.text('Scene 47 — the call beats were trimmed.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('other computer shells keep their own desktop', (tester) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'win-1',
      name: 'Stage pc',
      projectId: 'sandbox',
      kind: 'computer',
      os: const OsSettings(shell: 'windows'),
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FormOs(store: store, device: device),
      ),
    );
    expect(find.byKey(const Key('mac-desktop')), findsNothing);
    expect(find.byKey(const Key('win-desktop')), findsOneWidget);
    expect(find.text('Untitled Folder'), findsOneWidget);
    expect(find.text('Recycle Bin'), findsNothing);
    expect(find.byKey(const Key('win-bar-phone')), findsOneWidget);
    expect(find.byKey(const Key('win-taskbar')), findsOneWidget);
    await tester.tap(find.byKey(const Key('win-edge')));
    await tester.pump();
    expect(find.text('northline.example'), findsOneWidget);
    await tester.tap(find.byKey(const Key('win-window-close')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('win-start')));
    await tester.pump();
    final pin = find.byKey(const Key('win-pin-calculator'));
    await tester.ensureVisible(pin);
    await tester.pump();
    await tester.tap(pin);
    await tester.pump();
    expect(find.text('AC'), findsOneWidget);
    await tester.tap(find.byKey(const Key('win-window-close')));
    await tester.pump();
    await tester.tap(find.byTooltip('System'));
    await tester.pumpAndSettle();
    expect(find.text('Windows'), findsOneWidget);
    expect(find.text('Mac'), findsOneWidget);
    expect(find.text('Ubuntu'), findsOneWidget);
    expect(find.text('Linux'), findsNothing);
    expect(find.text('Windows 95'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mac settings, app store, and icon layout', (tester) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1024, 640));
    final device = PropDevice(
      id: 'mac-layout',
      name: 'Stage mac',
      projectId: 'sandbox',
      kind: 'computer',
      os: const OsSettings(
        glyphs: [CustomGlyph(id: 'glyph-1', name: 'Slate', image: '')],
      ),
    );
    store.upsertDevice(device);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FormOs(store: store, device: device),
      ),
    );
    expect(find.byKey(const Key('mac-dock-settings')), findsOneWidget);
    expect(find.byKey(const Key('mac-dock-appstore')), findsOneWidget);
    expect(find.byKey(const Key('mac-wall-dune')), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mac-dock-settings')));
    await tester.pump();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('INTERFACE'), findsOneWidget);
    expect(find.text('MENU BAR'), findsOneWidget);
    expect(find.text('STATUS BAR'), findsNothing);
    expect(find.text('Battery'), findsOneWidget);
    expect(find.text('Clock'), findsWidgets);
    expect(find.text('Mac'), findsOneWidget);
    expect(find.text('Ring Duration'), findsNothing);
    expect(find.text('Contacts Dial Codes'), findsNothing);

    Future<void> toTop() async {
      await tester.drag(
        find.byKey(const Key('desk-settings-list')),
        const Offset(0, 6000),
      );
      await tester.pump();
    }

    // Scroll the row into the settings window, then settle it fully inside
    // the window so the title bar cannot cover the control being tapped.
    Future<void> show(Key key) async {
      final target = find.byKey(key);
      await tester.dragUntilVisible(
        target,
        find.byKey(const Key('desk-settings-list')),
        const Offset(0, -80),
      );
      await tester.ensureVisible(target);
      await tester.pump();
    }

    await show(const Key('desk-theme-midnight'));
    await tester.tap(find.byKey(const Key('desk-theme-midnight')));
    await tester.pump();
    expect(find.byKey(const Key('mac-wall-custom')), findsOneWidget);
    await show(const Key('desk-preset-default'));
    await tester.tap(find.byKey(const Key('desk-preset-default')));
    await tester.pump();
    expect(find.byKey(const Key('mac-wall-dune')), findsOneWidget);

    await toTop();
    await show(const Key('desk-status-wifi'));
    await tester.tap(find.byKey(const Key('desk-status-wifi')));
    await tester.pump();
    expect(find.byKey(const Key('mac-menu-wifi-off')), findsOneWidget);

    await show(const Key('desk-battery-down'));
    await tester.tap(find.byKey(const Key('desk-battery-down')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('mac-menu-battery'))).data,
      '70%',
    );

    await show(const Key('desk-status-bluetooth'));
    await tester.tap(find.byKey(const Key('desk-status-bluetooth')));
    await tester.pump();
    expect(find.byKey(const Key('mac-menu-bluetooth')), findsOneWidget);

    await show(const Key('desk-status-network'));
    await tester.enterText(
      find.byKey(const Key('desk-status-network')),
      'Northline',
    );
    await tester.pump();
    expect(find.text('Northline'), findsWidgets);

    final beforeClock = tester
        .widget<Text>(find.byKey(const Key('mac-menu-clock')))
        .data;
    await show(const Key('desk-clock-forward'));
    await tester.tap(find.byKey(const Key('desk-clock-forward')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('mac-menu-clock'))).data,
      isNot(beforeClock),
    );

    await show(const Key('desk-show-search'));
    expect(find.text('MENU BAR ITEMS'), findsOneWidget);
    await tester.tap(find.byKey(const Key('desk-show-search')));
    await tester.pump();
    expect(find.byKey(const Key('mac-menu-search')), findsNothing);

    await show(const Key('desk-style-battery-icon'));
    await tester.tap(find.byKey(const Key('desk-style-battery-icon')));
    await tester.pump();
    expect(find.byKey(const Key('mac-menu-battery')), findsNothing);
    await tester.tap(find.byKey(const Key('desk-style-clock-date')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('mac-menu-clock'))).data,
      isNot(contains(':')),
    );

    await show(const Key('desk-dock-right-word'));
    final excelBefore = tester.getCenter(find.byKey(const Key('mac-dock-excel')));
    final wordBefore = tester.getCenter(find.byKey(const Key('mac-dock-word')));
    expect(wordBefore.dx, lessThan(excelBefore.dx));
    await tester.tap(find.byKey(const Key('desk-dock-right-word')));
    await tester.pump();
    expect(
      tester.getCenter(find.byKey(const Key('mac-dock-word'))).dx,
      greaterThan(tester.getCenter(find.byKey(const Key('mac-dock-excel'))).dx),
    );

    await toTop();
    await show(const Key('desk-dock-desk-music'));
    await tester.tap(find.byKey(const Key('desk-dock-desk-music')));
    await tester.pump();
    expect(find.byKey(const Key('mac-dock-music')), findsNothing);
    expect(find.byKey(const Key('mac-desk-music')), findsOneWidget);

    await show(const Key('desk-nudge-left-folder:Untitled Folder'));
    final documents = tester.getCenter(
      find.byKey(const Key('mac-file-Untitled Folder')),
    );
    await tester.tap(find.byKey(const Key('desk-nudge-left-folder:Untitled Folder')));
    await tester.pump();
    expect(
      tester.getCenter(find.byKey(const Key('mac-file-Untitled Folder'))).dx,
      lessThan(documents.dx - 40),
    );

    await tester.dragUntilVisible(
      find.text('Add to library'),
      find.byKey(const Key('desk-settings-list')),
      const Offset(0, -80),
    );
    expect(find.text('Add to library'), findsOneWidget);
    await tester.dragUntilVisible(
      find.byKey(const Key('factory-reset')),
      find.byKey(const Key('desk-settings-list')),
      const Offset(0, -80),
    );
    expect(find.text('Factory Reset'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mac-window-close')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('mac-dock-appstore')));
    await tester.pump();
    expect(find.text('App Library'), findsWidgets);
    expect(find.text('Slate'), findsNothing);
    await tester.tap(find.byKey(const Key('mac-store-section-Custom')));
    await tester.pump();
    expect(find.text('Slate'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mac-store-section-Functional')));
    await tester.pump();
    final notes = find.byKey(const Key('mac-store-dock-notes'));
    await tester.dragUntilVisible(
      notes,
      find.byKey(const Key('mac-store-scroll')),
      const Offset(0, -200),
    );
    await tester.ensureVisible(notes);
    await tester.pump();
    await tester.tap(notes);
    await tester.pump();
    expect(find.byKey(const Key('mac-dock-notes')), findsOneWidget);
    final calculator = find.byKey(const Key('mac-store-desk-calculator'));
    await tester.ensureVisible(calculator);
    await tester.pump();
    await tester.tap(calculator);
    await tester.pump();
    expect(find.byKey(const Key('mac-desk-calculator')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop icons follow a drag', (tester) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1024, 640));
    final device = PropDevice(
      id: 'mac-drag',
      name: 'Stage mac',
      projectId: 'sandbox',
      kind: 'computer',
    );
    store.upsertDevice(device);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FormOs(store: store, device: device),
      ),
    );
    final before = tester.getCenter(find.byKey(const Key('mac-file-Untitled Folder')));
    final gesture = await tester.startGesture(before);
    await tester.pump();
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(-210, -20));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pump();
    final after = tester.getCenter(find.byKey(const Key('mac-file-Untitled Folder')));
    expect(after.dx, lessThan(before.dx - 80));
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop windows resize, folders rename, and tools cover the screen', (
    tester,
  ) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1024, 640));
    final device = PropDevice(
      id: 'mac-tools',
      name: 'Stage mac',
      projectId: 'sandbox',
      kind: 'computer',
    );
    store.upsertDevice(device);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FormOs(store: store, device: device),
      ),
    );

    await tester.tap(find.byKey(const Key('mac-dock-word')));
    await tester.pump();
    final window = find
        .ancestor(
          of: find.byKey(const Key('mac-window-close')),
          matching: find.byType(Material),
        )
        .first;
    final opened = tester.getSize(window);
    expect(opened.width, greaterThan(700));
    expect(opened.height, greaterThan(400));
    await tester.drag(
      find.byKey(const Key('desk-window-resize')),
      const Offset(-120, -80),
    );
    await tester.pump();
    final resized = tester.getSize(window);
    expect(resized.width, lessThan(opened.width - 60));
    expect(resized.height, lessThan(opened.height - 40));
    await tester.tap(find.byKey(const Key('mac-window-close')));
    await tester.pump();

    await tester.tap(
      find.byKey(const Key('mac-desk-area')),
      buttons: kSecondaryButton,
    );
    await tester.pump();
    expect(find.text('New Folder'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mac-label-folder:Untitled Folder')));
    await tester.pump();
    expect(find.byKey(const Key('desk-rename-field')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('desk-rename-field')), 'Sides');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Sides'), findsOneWidget);
    expect(find.text('Documents'), findsNothing);

    await tester.tap(find.byKey(const Key('mac-dock-tracking')));
    await tester.pump();
    expect(find.text('Fullscreen'), findsWidgets);
    await tester.tap(find.byKey(const Key('mac-dock-tracking')));
    await tester.pump();
    expect(find.text('Fullscreen'), findsNothing);

    await tester.tap(find.byKey(const Key('mac-dock-markers')));
    await tester.pump();
    expect(find.textContaining('Tap to add numbers'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mac-dock-markers')));
    await tester.pump();
    expect(find.textContaining('Tap to add numbers'), findsNothing);

    await tester.tap(find.byKey(const Key('mac-dock-video')));
    await tester.pump();
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('Add video from this device'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
