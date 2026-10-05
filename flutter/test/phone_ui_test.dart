import 'package:dummy_phone/phone/desk_apps.dart';
import 'package:dummy_phone/phone/phone_apps.dart';
import 'package:dummy_phone/phone/utility_apps.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the phone app uses the iPhone tab bar and letter keypad', (tester) async {
    final store = StageStore.demo();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: PhoneDialer(store: store, deviceId: 'd-hero'),
        ),
      ),
    );
    expect(find.text('Favourites'), findsOneWidget);
    expect(find.text('Recents'), findsOneWidget);
    expect(find.text('Keypad'), findsOneWidget);
    expect(find.text('Voicemail'), findsOneWidget);
    expect(find.text('ABC'), findsOneWidget);
    expect(find.text('DEF'), findsOneWidget);
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.phone).first);
    await tester.pump();
    expect(store.callFor('d-hero')?.contactNumber, '2');
    store.dispose();
  });

  testWidgets('a new contact opens the iPhone contact sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContactsApp(onMessage: (_) {}, onCall: (_) {}, onAdd: (_) {}),
        ),
      ),
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('New Contact'), findsOneWidget);
    expect(find.text('First name'), findsOneWidget);
    expect(find.text('Company'), findsOneWidget);
    expect(find.text('add phone'), findsOneWidget);
  });

  testWidgets('messages and mail use their phone layouts', (tester) async {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    store.sendMessage(
      deviceId: 'd-hero',
      sender: 'control',
      text: 'On set in ten',
      senderName: 'Sarah Chen',
      thread: 'Sarah Chen',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: MessagesApp(store: store, deviceId: 'd-hero', onClose: () {}),
        ),
      ),
    );
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('On set in ten'), findsOneWidget);
    await tester.tap(find.text('Sarah Chen'));
    await tester.pump();
    expect(find.text('iMessage'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 390, height: 844, child: InboxApp()),
      ),
    );
    expect(find.text('Inbox'), findsWidgets);
    expect(find.text('Search'), findsOneWidget);
  });

  testWidgets('the browser uses the mobile Safari bar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 390, height: 844, child: PropBrowser()),
      ),
    );
    expect(find.text('Favourites'), findsOneWidget);
    expect(find.text('Search or enter website'), findsOneWidget);
    expect(find.byIcon(Icons.ios_share), findsOneWidget);
  });

  testWidgets('the calculator uses the iPhone keypad', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 390, height: 844, child: CalculatorApp()),
      ),
    );
    expect(find.text('AC'), findsOneWidget);
    expect(find.text('±'), findsOneWidget);
    expect(find.text('÷'), findsOneWidget);
    Finder key(String label) => find.byWidgetPredicate(
      (widget) => widget is Text && widget.data == label && (widget.style?.fontSize ?? 0) < 40,
    );
    await tester.tap(key('2'));
    await tester.pump();
    await tester.tap(key('+'));
    await tester.pump();
    await tester.tap(key('2'));
    await tester.pump();
    await tester.tap(key('='));
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == '4' && widget.style?.fontSize == 72,
      ),
      findsOneWidget,
    );
  });
}
