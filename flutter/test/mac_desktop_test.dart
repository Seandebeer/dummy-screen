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
    expect(find.text('Windows'), findsOneWidget);
    expect(find.text('Call'), findsWidgets);
    await tester.tap(find.byTooltip('System'));
    await tester.pumpAndSettle();
    expect(find.text('Mac'), findsOneWidget);
    expect(find.text('Linux'), findsOneWidget);
    expect(find.text('Ubuntu'), findsNothing);
    expect(find.text('Windows 95'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
