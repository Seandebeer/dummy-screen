import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/form_factor.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the xbox series console uses the series dashboard', (
    tester,
  ) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'console-1',
      name: 'Stage console',
      projectId: 'sandbox',
      kind: 'console',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 960,
          height: 540,
          child: FormOs(store: store, device: device),
        ),
      ),
    );
    expect(find.byKey(const Key('xbox-home')), findsOneWidget);
    expect(find.text('Night Run'), findsOneWidget);
    expect(find.text('My games & apps'), findsOneWidget);
    expect(find.text('Game Pass'), findsOneWidget);
    expect(find.text('Customize'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.byKey(const Key('xbox-featured')), findsOneWidget);

    await tester.tap(find.byKey(const Key('xbox-tile-harbor')));
    await tester.pump();
    expect(find.text('Harbor'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('the playstation 5 console uses the games dashboard', (
    tester,
  ) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(960, 540));
    final device = PropDevice(
      id: 'console-2',
      name: 'Stage console',
      projectId: 'sandbox',
      kind: 'console',
      os: const OsSettings(shell: 'ps5'),
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FormOs(store: store, device: device),
      ),
    );
    expect(find.byKey(const Key('ps5-home')), findsOneWidget);
    expect(find.text('Games'), findsOneWidget);
    expect(find.text('Media'), findsOneWidget);
    expect(find.text('Trophies'), findsOneWidget);
    expect(find.text('Online Friends'), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.byKey(const Key('xbox-home')), findsNothing);

    await tester.tap(find.text('Media'));
    await tester.pump();
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Trophies'), findsNothing);

    await tester.tap(find.text('Games'));
    await tester.pump();
    expect(find.text('Welcome'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ps5-game-harbor')));
    await tester.pump();
    expect(find.text('Harbor'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('the playstation 2 console uses the memory card browser', (
    tester,
  ) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(960, 540));
    final device = PropDevice(
      id: 'console-ps2',
      name: 'Stage console',
      projectId: 'sandbox',
      kind: 'console',
      os: const OsSettings(shell: 'ps2'),
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FormOs(store: store, device: device),
      ),
    );
    expect(find.byKey(const Key('ps2-home')), findsOneWidget);
    expect(find.byKey(const Key('ps2-plate')), findsOneWidget);
    expect(find.byKey(const Key('ps5-home')), findsNothing);
    expect(find.text('Memory Card (PS2)/1'), findsOneWidget);
    expect(find.text('6,144 KB Free'), findsOneWidget);
    expect(find.text('Night Run'), findsOneWidget);
    expect(find.text('Enter'), findsOneWidget);
    expect(find.text('Options'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ps2-save-harbor')));
    await tester.pump();
    expect(find.text('Harbor'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ps2-enter')));
    await tester.pump();
    expect(find.text('Harbor'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('the playstation 2 browser uses a saved wallpaper', (
    tester,
  ) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'console-ps2-wall',
      name: 'Stage console',
      projectId: 'sandbox',
      kind: 'console',
      os: const OsSettings(
        shell: 'ps2',
        backgroundType: 'preset',
        backgroundPreset: 'sunset',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FormOs(store: store, device: device),
      ),
    );
    expect(find.byKey(const Key('ps2-wallpaper')), findsOneWidget);
    expect(find.byKey(const Key('ps2-plate')), findsNothing);
    expect(find.text('Memory Card (PS2)/1'), findsOneWidget);
  });

  testWidgets('the playstation 2 browser fits a short console frame', (
    tester,
  ) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(480, 270));
    final device = PropDevice(
      id: 'console-ps2-short',
      name: 'Stage console',
      projectId: 'sandbox',
      kind: 'console',
      os: const OsSettings(shell: 'ps2'),
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FormOs(store: store, device: device),
      ),
    );
    expect(find.byKey(const Key('ps2-home')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the playstation 5 dashboard fits a short console frame', (
    tester,
  ) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final device = PropDevice(
      id: 'console-ps5-short',
      name: 'Stage console',
      projectId: 'sandbox',
      kind: 'console',
      os: const OsSettings(shell: 'ps5'),
    );
    for (final size in const [
      Size(480, 270),
      Size(800, 600),
      Size(1280, 720),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: FormOs(store: store, device: device),
        ),
      );
      expect(find.byKey(const Key('ps5-home')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the xbox 360 console uses the tile dashboard', (tester) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'console-360',
      name: 'Stage console',
      projectId: 'sandbox',
      kind: 'console',
      os: const OsSettings(shell: 'x360'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 960,
          height: 540,
          child: FormOs(store: store, device: device),
        ),
      ),
    );
    expect(find.byKey(const Key('xbox360-home')), findsOneWidget);
    expect(find.text('home'), findsOneWidget);
    expect(find.text('My Games'), findsOneWidget);
    expect(find.text('My Pins'), findsOneWidget);
    expect(find.text('Select'), findsOneWidget);
    expect(find.byKey(const Key('xbox-home')), findsNothing);

    await tester.tap(find.byKey(const Key('xbox360-recent')));
    await tester.pump();
    expect(find.text('Recent'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('the 360 dashboard fits a short console frame', (tester) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'console-360-short',
      name: 'Stage console',
      projectId: 'sandbox',
      kind: 'console',
      os: const OsSettings(shell: 'x360'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 480,
          height: 270,
          child: FormOs(store: store, device: device),
        ),
      ),
    );
    expect(find.byKey(const Key('xbox360-home')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1200,
          height: 680,
          child: FormOs(store: store, device: device),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the series dashboard fits a short console frame', (
    tester,
  ) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'console-3',
      name: 'Stage console',
      projectId: 'sandbox',
      kind: 'console',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 480,
          height: 270,
          child: FormOs(store: store, device: device),
        ),
      ),
    );
    expect(find.byKey(const Key('xbox-home')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
