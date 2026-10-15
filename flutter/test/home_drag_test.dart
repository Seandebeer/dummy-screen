import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/home_drag.dart';
import 'package:dummy_phone/phone/home_view.dart';
import 'package:dummy_phone/phone/tv_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a home app swaps into an occupied dock slot', () {
    final placed = placeApp(
      home: const ['videocall', 'calendar', 'photos'],
      dock: const ['phone', 'browser', 'messages', 'music'],
      id: 'photos',
      remove: false,
      dockIndex: 1,
    );
    expect(placed.dock, ['phone', 'photos', 'messages', 'music']);
    expect(placed.home, ['videocall', 'calendar', 'browser']);
  });

  test('an occupied home slot swaps the two apps', () {
    const ids = ['videocall', 'calendar', 'photos', 'camera'];
    final swapped = movedOrder(ids, 'videocall', remove: false, index: 2);
    expect(swapped, ['photos', 'calendar', 'videocall', 'camera']);
    final removed = movedOrder(ids, 'calendar', remove: true, index: null);
    expect(removed, ['videocall', 'photos', 'camera']);
  });

  testWidgets('dragging one home icon onto another swaps them', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(400, 800));
    List<String>? order;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhoneHome(
            skin: 'modern',
            os: const OsSettings(),
            onOpen: (_) {},
            onOrder: (next) => order = next,
          ),
        ),
      ),
    );
    await tester.pump();

    final from = tester.getCenter(find.byKey(const Key('home-videocall')));
    final to = tester.getCenter(find.byKey(const Key('home-photos')));
    final gesture = await tester.startGesture(from);
    await gesture.moveTo(to);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(order, isNotNull);
    expect(order!.first, 'photos');
    expect(order![2], 'videocall');
  });

  testWidgets('dragging a home icon off the device removes it', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(800, 800));
    List<String>? order;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 640,
              child: PhoneHome(
                skin: 'modern',
                os: const OsSettings(),
                onOpen: (_) {},
                onOrder: (next) => order = next,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final from = tester.getCenter(find.byKey(const Key('home-videocall')));
    final gesture = await tester.startGesture(from);
    await gesture.moveTo(const Offset(20, 20));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(order, isNotNull);
    expect(order!, isNot(contains('videocall')));
  });

  testWidgets('the smart tv home shows the living-room shelves', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    await tester.pumpWidget(
      MaterialApp(
        home: TvHome(
          os: const OsSettings(clockHour: 14, clockMinute: 45, clockFormat: '12', clockSource: 'set'),
          shell: 'aurora',
          onShell: (_) {},
          onOpen: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('tv-search')), findsOneWidget);
    expect(find.text('Apps'), findsOneWidget);
    expect(find.text('Watch Next'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
    expect(find.byKey(const Key('tv-app-vidtube')), findsOneWidget);
    expect(find.text('YouTube'), findsWidgets);
    await tester.tap(find.byKey(const Key('tv-app-vidtube')));
    await tester.pump();
  });
}
