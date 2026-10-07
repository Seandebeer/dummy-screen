import 'dart:async';

import 'package:dummy_phone/lan_link_io.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('two machines share a message over the local link', () async {
    final hostStore = StageStore.demo();
    final clientStore = StageStore.demo();
    final host = LanLink(hostStore);
    final client = LanLink(clientStore);
    addTearDown(() async {
      await host.disconnect();
      await client.disconnect();
    });

    final address = await host.host(port: 0);
    expect(address, isNotNull);
    expect(host.boundPort, isNotNull);

    await client.join('127.0.0.1:${host.boundPort}');
    expect(client.role, LinkRole.client);

    final arrived = Completer<void>();
    void listener() {
      if (!arrived.isCompleted &&
          clientStore.messages.any((message) => message.text == 'Action')) {
        arrived.complete();
      }
    }

    clientStore.addListener(listener);
    hostStore.sendMessage(
      deviceId: 'd-hero',
      sender: 'control',
      text: 'Action',
      senderName: 'Sarah Chen',
      thread: 'Sarah Chen',
    );
    await arrived.future.timeout(const Duration(seconds: 2));
    clientStore.removeListener(listener);
    expect(clientStore.messages.single.text, 'Action');
  });
}
