import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('each legacy skin paints its own home', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));

    Future<void> pump(String skin) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PhoneHome(skin: skin, os: const OsSettings(), onOpen: (_) {}),
          ),
        ),
      );
      await tester.pump();
    }

    await pump('iphoneos');
    expect(find.byKey(const Key('legacy-iphoneos')), findsOneWidget);
    expect(find.byKey(const Key('dock-phone')), findsOneWidget);

    await pump('aqua');
    expect(find.byKey(const Key('legacy-iphoneos')), findsOneWidget);

    await pump('ios6');
    expect(find.byKey(const Key('legacy-ios6')), findsOneWidget);
    expect(find.text('Mail'), findsWidgets);

    await pump('ios7');
    expect(find.byKey(const Key('legacy-ios7')), findsOneWidget);

    await pump('winphone');
    expect(find.byKey(const Key('legacy-winphone')), findsOneWidget);
    expect(find.text('Pictures'), findsOneWidget);
    expect(find.text('Games'), findsOneWidget);

    await pump('tiles');
    expect(find.byKey(const Key('legacy-winphone')), findsOneWidget);

    await pump('holo');
    expect(find.byKey(const Key('legacy-holo')), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.byKey(const Key('holo-drawer')), findsOneWidget);

    await pump('material');
    expect(find.byKey(const Key('legacy-holo')), findsOneWidget);

    await pump('webos');
    expect(find.byKey(const Key('legacy-webos')), findsOneWidget);
    expect(find.byKey(const Key('webos-launcher')), findsOneWidget);

    await pump('belle');
    expect(find.byKey(const Key('legacy-belle')), findsOneWidget);
    expect(find.byKey(const Key('belle-today')), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Fiona'), findsOneWidget);
    expect(find.text('Rachel'), findsOneWidget);

    await pump('blackberry');
    expect(find.byKey(const Key('legacy-belle')), findsOneWidget);

    await pump('ios');
    expect(find.byKey(const Key('legacy-iphoneos')), findsNothing);
    await pump('android');
    expect(find.byKey(const Key('legacy-android')), findsNothing);
    expect(find.byKey(const Key('dock-phone')), findsOneWidget);
  });
}
