import 'media/signal_hub.dart';
import 'store.dart';

/// Browser builds have no server socket. The installed iOS, Android,
/// Windows, and Mac apps host and join the deck over the local network.
/// Offer and answer still meet in [SignalHub] on this one machine.
class LanLink implements StageSync {
  LanLink(this.store, [SignalHub? hub]) {
    store.attach(this);
    hub?.transport = (_) {};
  }

  final StageStore store;

  @override
  LinkRole role = LinkRole.solo;

  @override
  String status =
      'On this device. Install the iOS, Android, Windows, or Mac app to link a second screen.';

  @override
  String? address;

  @override
  Future<String?> host({int? port}) async {
    status = 'Hosting a deck needs the installed app, not a browser tab.';
    store.refresh();
    return null;
  }

  @override
  Future<void> join(String input) async {
    status = 'Joining a deck needs the installed app.';
    store.refresh();
  }

  @override
  Future<void> disconnect() async {
    role = LinkRole.solo;
    address = null;
    status = 'On this device.';
    store.refresh();
  }

  @override
  void broadcastState() {}

  @override
  void sendPatch(Map<String, dynamic> patch) {}
}
