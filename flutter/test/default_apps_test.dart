import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/catalog.dart';
import 'package:dummy_phone/phone/form_factor.dart';
import 'package:dummy_phone/phone/home_view.dart';
import 'package:dummy_phone/phone/mac_desk.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The functional apps every interface starts with: four in the dock and
/// twenty on the first home page, matching `defaultHomeOrder` on the web.
const _functional = [...kDockIds, ...kHomeOrder];

void main() {
  test('page one carries every functional app', () {
    final page = homePageOne();
    expect(page.length, kPageSize);
    expect(kDockIds.length, 4);
    for (final id in page) {
      expect(propAppById(id), isNotNull, reason: id);
      expect(kDockIds.contains(id), isFalse, reason: id);
    }
    expect(_functional.take(24).toSet().length, 24);
  });

  testWidgets('a phone and a tablet open with the same first page', (
    tester,
  ) async {
    Future<List<String>> icons(Size size, {required bool wide}) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PhoneHome(
              skin: 'ios',
              os: const OsSettings(),
              wide: wide,
              onOpen: (_) {},
            ),
          ),
        ),
      );
      final found = <String>[];
      for (final id in homePageOne()) {
        if (tester.any(find.byKey(Key('home-$id')))) found.add(id);
      }
      for (final id in kDockIds) {
        expect(find.byKey(Key('dock-$id')), findsOneWidget, reason: id);
      }
      return found;
    }

    addTearDown(() => tester.binding.setSurfaceSize(null));
    expect(await icons(const Size(390, 844), wide: false), homePageOne());
    expect(await icons(const Size(834, 1112), wide: true), homePageOne());
  });

  test('a computer desktop starts with the same apps plus the desk tools', () {
    final ids = [for (final app in deskApps(const OsSettings())) app.$1];
    expect(ids.take(kPageSize).toList(), homePageOne());
    expect(ids, containsAll(['word', 'excel', 'terminal']));

    final mac = MacLayout.defaultDesktop();
    for (final id in homePageOne()) {
      expect(
        mac.contains(id) || kMacDockIds.contains(id),
        isTrue,
        reason: id,
      );
    }
  });

  testWidgets('every computer shell opens a shared app in a window', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1180, 760));
    for (final shell in ['macos', 'windows', 'linux']) {
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
          home: FormOs(store: store, device: device),
        ),
      );
      final calculator = find.text('Calculator').first;
      await tester.ensureVisible(calculator);
      await tester.tap(calculator);
      await tester.pump();
      expect(find.text('AC'), findsOneWidget, reason: shell);
      expect(tester.takeException(), isNull, reason: shell);
    }
  });
}
