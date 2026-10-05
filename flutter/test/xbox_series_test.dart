import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/form_factor.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the xbox series console uses the series dashboard', (tester) async {
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

  testWidgets('other console shells keep their own home', (tester) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'console-2',
      name: 'Stage console',
      projectId: 'sandbox',
      kind: 'console',
      os: const OsSettings(shell: 'ps5'),
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
    expect(find.byKey(const Key('xbox-home')), findsNothing);
    expect(find.text('PlayStation 5'), findsOneWidget);
    expect(find.text('Night Run'), findsOneWidget);
  });

  testWidgets('the series dashboard fits a short console frame', (tester) async {
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
