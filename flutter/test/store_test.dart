import 'package:dummy_phone/store.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recorder implements StageSync {
  _Recorder(this.role);

  @override
  LinkRole role;

  @override
  String status = '';

  @override
  String? address;

  Map<String, dynamic>? snapshot;
  final patches = <Map<String, dynamic>>[];

  @override
  Future<String?> host({int? port}) async => null;

  @override
  Future<void> join(String input) async {}

  @override
  Future<void> disconnect() async {}

  @override
  void broadcastState() {}

  @override
  void sendPatch(Map<String, dynamic> patch) => patches.add(patch);
}

void main() {
  test('a deck message reaches the phone through a snapshot', () {
    final host = StageStore.demo();
    final client = StageStore.demo();
    host.attach(_Recorder(LinkRole.host));
    final clientLink = _Recorder(LinkRole.client);
    client.attach(clientLink);

    client.sendMessage(
      deviceId: 'd-hero',
      sender: 'phone',
      text: 'Rolling',
      senderName: 'Hero phone',
      thread: 'Sarah Chen',
    );
    expect(clientLink.patches, hasLength(1));

    host.applyPatch(clientLink.patches.single);
    expect(host.messages.single.text, 'Rolling');

    client.importState(host.exportState());
    expect(
      client.messages.where((message) => message.text == 'Rolling'),
      hasLength(1),
    );
  });

  test('control calls replace one another on the same device', () {
    final store = StageStore.demo();
    store.startCall(
      deviceId: 'd-hero',
      contactName: 'Sarah Chen',
      contactNumber: '026',
      direction: 'incoming',
    );
    store.startCall(
      deviceId: 'd-hero',
      contactName: 'Marcus Webb',
      contactNumber: '034',
      direction: 'incoming',
    );
    expect(store.calls, hasLength(1));
    expect(store.callFor('d-hero')!.contactName, 'Marcus Webb');
    store.setCallStatus('d-hero', 'active');
    expect(store.callFor('d-hero')!.status, 'active');
    store.endCall('d-hero');
    expect(store.callFor('d-hero'), isNull);
  });

  test('saved layouts round-trip the screen color and skin', () {
    final store = StageStore.demo();
    store.setSkin('d-hero', 'tiles');
    store.setVfxColor('blue');
    store.saveLayout('Night exterior');
    store.setSkin('d-hero', 'modern');
    store.setVfxColor('green');
    store.applyLayout(store.saved.single, 'd-hero');
    expect(store.deviceById('d-hero')!.skin, 'tiles');
    expect(store.vfxColor, 'blue');
    expect(store.saved.single.name, 'Night exterior');
  });
}
