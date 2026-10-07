import 'package:dummy_phone/phone/phone_apps.dart';
import 'package:dummy_phone/phone/phone_shell.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the message keypad stays on the phone and offers emoji', (tester) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(400, 860));
    final device = store.devices.firstWhere((item) => item.kind == 'phone');
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PhoneShell(
          device: device,
          timeLabel: '9:41',
          onHome: () {},
          body: MessagesApp(
            store: store,
            deviceId: device.id,
            onClose: () {},
            initialThread: 'Sarah Chen',
          ),
        ),
      ),
    );
    expect(find.text('iMessage'), findsOneWidget);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('return'), findsOneWidget);
    expect(find.text('😊'), findsOneWidget);
    final phone = tester.getRect(find.byType(PhoneShell));
    final key = tester.getRect(find.text('return'));
    expect(phone.contains(key.center), isTrue);

    await tester.tap(find.text('😊'));
    await tester.pump();
    expect(find.text('😀'), findsOneWidget);
    expect(phone.contains(tester.getRect(find.text('😀')).center), isTrue);
    expect(tester.takeException(), isNull);
  });
}
