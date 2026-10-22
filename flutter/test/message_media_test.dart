import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/desk_apps.dart';
import 'package:dummy_phone/phone/desk_os_apps.dart';
import 'package:dummy_phone/phone/phone_apps.dart';
import 'package:dummy_phone/phone/phone_shell.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('message text edits and mail items round-trip', () {
    final store = StageStore.demo();
    addTearDown(store.dispose);
    store.sendMessage(
      deviceId: 'd-hero',
      sender: 'phone',
      text: 'Hold',
      senderName: 'Sarah Chen',
      thread: 'Sarah Chen',
      media: 'swatch:4278255360',
      mediaType: 'photo',
    );
    final id = store.messages.single.id;
    store.updateMessageText(id, '  Hold the roll  ');
    expect(store.messages.single.text, 'Hold the roll');
    store.updateMessageText(id, '   ');
    expect(store.messages.single.text, '');
    expect(store.messages.single.mediaType, 'photo');
    store.sendMessage(
      deviceId: 'd-hero',
      sender: 'phone',
      text: 'Stay',
      senderName: 'Sarah Chen',
      thread: 'Sarah Chen',
    );
    final plain = store.messages.first.id;
    store.updateMessageText(plain, '   ');
    expect(store.messages.first.text, 'Stay');

    store.saveMailItem(
      deviceId: 'd-hero',
      mail: {
        'id': 1,
        'from': 'Production Desk',
        'subject': 'Call sheet - Day 14',
        'time': 'Now',
        'unread': false,
        'thread': [
          {'who': 'them', 'body': 'New call time', 'time': 'Now'},
        ],
      },
    );
    final page = store.pages['mail-d-hero'] as Map;
    final item = (page['items'] as List).single as Map;
    expect(item['thread'], [
      {'who': 'them', 'body': 'New call time', 'time': 'Now'},
    ]);
    final merged = mergeInbox([
      for (final mail in page['items'] as List) Map<String, dynamic>.from(mail as Map),
    ]);
    expect(merged.where((mail) => mail['id'] == 1), hasLength(1));
    expect((merged.firstWhere((mail) => mail['id'] == 1)['thread'] as List).first['body'], 'New call time');
  });

  testWidgets('a phone message can carry a camera-roll photo and be edited', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(400, 860));
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = store.devices.firstWhere((item) => item.kind == 'phone');
    store.addPhoto(device.id, 0xFF30D158);
    store.addPhoto(device.id, 0xFFFF453A, kind: 'video');
    final photo = store.photos[device.id]!.first;
    final video = store.photos[device.id]!.last;
    store.sendMessage(
      deviceId: device.id,
      sender: 'control',
      text: 'Hi',
      senderName: 'Sarah Chen',
      thread: 'Sarah Chen',
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PhoneShell(
          device: device,
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
    await tester.pump();

    await tester.tap(find.byKey(const Key('msg-attach')));
    await tester.pumpAndSettle();
    expect(find.text('Camera Roll'), findsOneWidget);
    await tester.tap(find.byKey(Key('roll-pick-${photo.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('msg-pending')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();
    final sent = store.messagesFor(device.id).first;
    expect(sent.mediaType, 'photo');
    expect(sent.media, 'swatch:${photo.color}');
    expect(find.byKey(Key('msg-media-${sent.id}')), findsOneWidget);

    await tester.tap(find.byKey(const Key('msg-attach')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('roll-pick-${video.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();
    expect(store.messagesFor(device.id).first.mediaType, 'video');
    expect(find.byIcon(Icons.play_circle_fill), findsWidgets);

    final hi = store.messagesFor(device.id).lastWhere((message) => message.text == 'Hi');
    await tester.tap(find.byKey(Key('msg-text-${hi.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('msg-edit')), findsOneWidget);
    expect(find.text('return'), findsOneWidget);
    await tester.tap(find.text('x'));
    await tester.pump();
    await tester.tap(find.text('return'));
    await tester.pump();
    expect(
      store.messagesFor(device.id).any((message) => message.text == 'Hix'),
      isTrue,
    );
    expect(find.text('Hix'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone mail sends a roll photo and edits the open text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(400, 860));
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = store.devices.firstWhere((item) => item.kind == 'phone');
    store.addPhoto(device.id, 0xFF318DF6);
    final photo = store.photos[device.id]!.single;
    Map<String, dynamic>? saved;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PhoneShell(
          device: device,
          onHome: () {},
          body: InboxApp(
            photos: store.photos[device.id] ?? const [],
            onSave: (mail) => saved = mail,
            extra: const [
              {
                'id': 90,
                'from': 'Unit',
                'subject': 'Sides',
                'time': 'Now',
                'unread': true,
                'thread': [
                  {'who': 'them', 'body': 'Bring the roll', 'time': 'Now'},
                ],
              },
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Unit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mail-body-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mail-edit')), findsOneWidget);
    await tester.tap(find.text('x'));
    await tester.pump();
    await tester.tap(find.text('return'));
    await tester.pump();
    expect(find.text('Bring the rollx'), findsOneWidget);
    expect(saved, isNotNull);
    expect((saved!['thread'] as List).first['body'], 'Bring the rollx');

    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mail-attach')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('roll-pick-${photo.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mail-pending')), findsOneWidget);
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_circle_fill), findsNothing);
    expect(find.byKey(const Key('mail-media-1')), findsOneWidget);
    final thread = saved!['thread'] as List;
    expect(thread, hasLength(2));
    expect(thread.last['mediaType'], 'photo');
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop messages and mail send roll media and edit in place', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(720, 480));
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'desk-media',
      name: 'Stage pc',
      projectId: 'sandbox',
      kind: 'computer',
    );
    store.upsertDevice(device);
    store.addPhoto(device.id, 0xFF5E5CE6, kind: 'video');
    final video = store.photos[device.id]!.single;
    store.sendMessage(
      deviceId: device.id,
      sender: 'deck',
      text: 'Picture is up.',
      senderName: 'Unit',
      thread: 'Unit',
    );

    Future<void> open(String id) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: DeskAppView(
            store: store,
            device: device,
            appId: id,
            onOpen: (_, {String? thread}) {},
          ),
        ),
      );
      await tester.pump();
    }

    await open('messages');
    await tester.tap(find.byKey(const Key('desk-attach')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('roll-pick-${video.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('desk-pending')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('desk-reply')), 'Clip attached');
    await tester.tap(find.byKey(const Key('desk-send')));
    await tester.pump();
    final sent = store.messagesFor(device.id).firstWhere(
      (message) => message.text == 'Clip attached',
    );
    expect(sent.mediaType, 'video');
    expect(find.byKey(Key('desk-media-${sent.id}')), findsOneWidget);

    await tester.tap(find.text('Picture is up.'));
    await tester.pump();
    expect(find.byKey(const Key('desk-msg-edit')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('desk-msg-edit')), 'Picture is locked.');
    await tester.tap(find.byKey(const Key('desk-msg-done')));
    await tester.pump();
    expect(find.text('Picture is locked.'), findsOneWidget);
    expect(
      store.messagesFor(device.id).any((message) => message.text == 'Picture is locked.'),
      isTrue,
    );

    await open('email');
    expect(find.text('Call sheet - Day 14'), findsWidgets);
    await tester.tap(find.byKey(const Key('desk-mail-body-0')));
    await tester.pump();
    expect(find.byKey(const Key('desk-mail-edit')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('desk-mail-edit')), 'Call time moved.');
    await tester.tap(find.byKey(const Key('desk-mail-done')));
    await tester.pump();
    expect(find.text('Call time moved.'), findsOneWidget);
    final edited = store.pages['mail-${device.id}'] as Map;
    final first = ((edited['items'] as List).first as Map)['thread'] as List;
    expect(first.first['body'], 'Call time moved.');

    await tester.tap(find.byKey(const Key('desk-mail-compose')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('desk-mail-to')), 'Sarah Chen');
    await tester.enterText(find.byKey(const Key('desk-mail-subject')), 'Stills');
    await tester.enterText(find.byKey(const Key('desk-mail-body')), 'From the roll');
    await tester.tap(find.byKey(const Key('desk-mail-attach')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('roll-pick-${video.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('desk-mail-send')));
    await tester.pump();
    expect(find.text('Stills'), findsWidgets);
    expect(find.byKey(const Key('desk-mail-media-0')), findsOneWidget);
    final sentMail = (store.pages['mail-${device.id}'] as Map)['items'] as List;
    final newest = sentMail.first as Map;
    expect(newest['subject'], 'Stills');
    expect((newest['thread'] as List).first['mediaType'], 'video');

    await tester.enterText(find.byKey(const Key('desk-mail-reply')), 'Received');
    await tester.tap(find.byKey(const Key('desk-mail-reply-attach')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('roll-pick-${video.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('desk-mail-reply-send')));
    await tester.pump();
    expect(find.text('Received'), findsOneWidget);
    expect(find.byKey(const Key('desk-mail-media-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
