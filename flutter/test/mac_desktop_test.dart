import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/form_factor.dart';
import 'package:dummy_phone/store.dart';
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
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Insert card to begin.'), findsNothing);

    final documents = tester.getCenter(
      find.byKey(const Key('mac-file-Documents')),
    );
    final projects = tester.getCenter(
      find.byKey(const Key('mac-file-Projects')),
    );
    final finder = tester.getCenter(find.text('Finder'));
    expect(documents.dx, greaterThan(finder.dx));
    expect(projects.dy, greaterThan(documents.dy));

    await tester.tap(find.byKey(const Key('mac-file-Documents')));
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
    expect(find.text('Recycle Bin'), findsOneWidget);
    expect(find.text('Edge'), findsOneWidget);
    expect(find.text('Mail'), findsOneWidget);
    expect(find.text('Remote'), findsOneWidget);
    expect(find.byKey(const Key('win-taskbar')), findsOneWidget);
    await tester.tap(find.byKey(const Key('win-edge')));
    await tester.pump();
    expect(find.text('northline.example'), findsOneWidget);
    await tester.tap(find.byKey(const Key('win-window-close')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('win-start')));
    await tester.pump();
    expect(find.text('Call'), findsOneWidget);
    await tester.tap(find.byKey(const Key('win-pin-call')));
    await tester.pump();
    expect(find.text('Call'), findsOneWidget);
    await tester.tap(find.byTooltip('System'));
    await tester.pumpAndSettle();
    expect(find.text('Windows'), findsOneWidget);
    expect(find.text('Mac'), findsOneWidget);
    expect(find.text('Linux'), findsOneWidget);
    expect(find.text('Ubuntu'), findsNothing);
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
    expect(find.text('Theme'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mac-theme-midnight')));
    await tester.pump();
    expect(find.byKey(const Key('mac-wall-custom')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mac-bg-dune')));
    await tester.pump();
    expect(find.byKey(const Key('mac-wall-dune')), findsOneWidget);

    Future<void> page(String id) async {
      await tester.tap(find.byKey(Key('mac-settings-$id')));
      await tester.pump();
    }

    Future<void> show(Key key) => tester.dragUntilVisible(
      find.byKey(key),
      find.byKey(const Key('mac-settings-scroll')),
      const Offset(0, -80),
    );

    await page('menu');
    await show(const Key('mac-status-wifi'));
    await tester.tap(find.byKey(const Key('mac-status-wifi')));
    await tester.pump();
    expect(find.byKey(const Key('mac-menu-wifi-off')), findsOneWidget);

    await show(const Key('mac-battery-down'));
    await tester.tap(find.byKey(const Key('mac-battery-down')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('mac-menu-battery'))).data,
      '70%',
    );

    await show(const Key('mac-status-bluetooth'));
    await tester.tap(find.byKey(const Key('mac-status-bluetooth')));
    await tester.pump();
    expect(find.byKey(const Key('mac-menu-bluetooth')), findsOneWidget);

    await show(const Key('mac-status-network'));
    await tester.enterText(
      find.byKey(const Key('mac-status-network')),
      'Northline',
    );
    await tester.pump();
    expect(find.text('Northline'), findsWidgets);

    final beforeClock = tester
        .widget<Text>(find.byKey(const Key('mac-menu-clock')))
        .data;
    await show(const Key('mac-clock-forward'));
    await tester.tap(find.byKey(const Key('mac-clock-forward')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('mac-menu-clock'))).data,
      isNot(beforeClock),
    );

    await show(const Key('mac-show-search'));
    await tester.tap(find.byKey(const Key('mac-show-search')));
    await tester.pump();
    expect(find.byKey(const Key('mac-menu-search')), findsNothing);

    await page('icons');
    expect(find.text('Add to library'), findsOneWidget);
    await page('layout');
    await show(const Key('mac-dock-right-word'));
    final excelBefore = tester.getCenter(find.byKey(const Key('mac-dock-excel')));
    final wordBefore = tester.getCenter(find.byKey(const Key('mac-dock-word')));
    expect(wordBefore.dx, lessThan(excelBefore.dx));
    await tester.tap(find.byKey(const Key('mac-dock-right-word')));
    await tester.pump();
    expect(
      tester.getCenter(find.byKey(const Key('mac-dock-word'))).dx,
      greaterThan(tester.getCenter(find.byKey(const Key('mac-dock-excel'))).dx),
    );

    await show(const Key('mac-dock-desk-music'));
    await tester.tap(find.byKey(const Key('mac-dock-desk-music')));
    await tester.pump();
    expect(find.byKey(const Key('mac-dock-music')), findsNothing);
    expect(find.byKey(const Key('mac-desk-music')), findsOneWidget);

    await show(const Key('mac-nudge-left-file:Documents'));
    final documents = tester.getCenter(
      find.byKey(const Key('mac-file-Documents')),
    );
    await tester.tap(find.byKey(const Key('mac-nudge-left-file:Documents')));
    await tester.pump();
    expect(
      tester.getCenter(find.byKey(const Key('mac-file-Documents'))).dx,
      lessThan(documents.dx - 40),
    );

    await tester.tap(find.byKey(const Key('mac-window-close')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('mac-dock-appstore')));
    await tester.pump();
    expect(find.text('App Library'), findsWidgets);
    expect(find.text('Slate'), findsOneWidget);
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
    final before = tester.getCenter(find.byKey(const Key('mac-file-Projects')));
    final gesture = await tester.startGesture(before);
    await tester.pump();
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(-210, -20));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pump();
    final after = tester.getCenter(find.byKey(const Key('mac-file-Projects')));
    expect(after.dx, lessThan(before.dx - 80));
    expect(tester.takeException(), isNull);
  });
}
