import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/desk_grid.dart';
import 'package:dummy_phone/phone/form_factor.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a desktop drop snaps to the cell and swaps the occupant', () {
    final grid = DeskGrid.of(const Size(960, 540));
    final spots = {
      'folder:a': grid.origin(0),
      'notes': grid.origin(1),
    };
    final moved = snapMove(
      grid: grid,
      spots: spots,
      id: 'notes',
      drop: grid.origin(0) + const Offset(6, 4),
    );
    expect(moved.displaced, isNull);
    expect(moved.spots['notes'], grid.origin(0));
    expect(moved.spots['folder:a'], grid.origin(1));
  });

  test('a dock app landing on a desktop app takes its cell', () {
    final grid = DeskGrid.of(const Size(960, 540));
    final spots = {'notes': grid.origin(2)};
    final moved = snapMove(
      grid: grid,
      spots: spots,
      id: 'photos',
      drop: grid.origin(2) + const Offset(2, 2),
    );
    expect(moved.displaced, 'notes');
    expect(moved.spots['photos'], grid.origin(2));
    expect(moved.spots.containsKey('notes'), isFalse);
  });

  testWidgets('mac dock icons snap onto the desktop and swap back', (tester) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1024, 640));
    final device = PropDevice(
      id: 'mac-snap',
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
    await tester.pump();

    final docked = tester.getCenter(find.byKey(const Key('mac-dock-music')));
    final out = await tester.startGesture(docked);
    await out.moveTo(const Offset(180, 160));
    await tester.pump();
    await out.up();
    await tester.pump();
    expect(find.byKey(const Key('mac-desk-music')), findsOneWidget);
    expect(find.byKey(const Key('mac-dock-music')), findsNothing);

    final desk = tester.getCenter(find.byKey(const Key('mac-desk-music')));
    final phone = tester.getCenter(find.byKey(const Key('mac-dock-phone')));
    final back = await tester.startGesture(desk);
    await back.moveTo(phone);
    await tester.pump();
    await back.up();
    await tester.pump();
    expect(find.byKey(const Key('mac-dock-music')), findsOneWidget);
    expect(find.byKey(const Key('mac-desk-music')), findsNothing);
    expect(find.byKey(const Key('mac-desk-phone')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('windows and ubuntu icons snap between the desktop and the dock', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1024, 640));
    for (final shell in ['windows', 'linux']) {
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
          home: FormOs(key: ValueKey(shell), store: store, device: device),
        ),
      );
      await tester.pump();

      final barKey = Key(shell == 'windows' ? 'win-bar-phone' : 'linux-bar-phone');
      final deskKey = Key(shell == 'windows' ? 'win-desk-phone' : 'linux-desk-phone');
      final from = tester.getCenter(find.byKey(barKey));
      final out = await tester.startGesture(from);
      await out.moveTo(const Offset(420, 160));
      await tester.pump();
      await out.up();
      await tester.pump();
      expect(find.byKey(deskKey), findsOneWidget, reason: shell);
      expect(find.byKey(barKey), findsNothing, reason: shell);

      final desk = tester.getCenter(find.byKey(deskKey));
      final otherKey = Key(shell == 'windows' ? 'win-bar-browser' : 'linux-bar-browser');
      final other = tester.getCenter(find.byKey(otherKey));
      final back = await tester.startGesture(desk);
      await back.moveTo(other);
      await tester.pump();
      await back.up();
      await tester.pump();
      expect(find.byKey(barKey), findsOneWidget, reason: shell);
      expect(find.byKey(deskKey), findsNothing, reason: shell);
      final swapped = Key(shell == 'windows' ? 'win-desk-browser' : 'linux-desk-browser');
      expect(find.byKey(swapped), findsOneWidget, reason: shell);
      expect(tester.takeException(), isNull, reason: shell);
    }
  });
}
