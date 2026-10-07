import 'dart:async';

/// Carries WebRTC offer, answer, and ICE messages.
///
/// The deck and the phone on one machine share this hub directly. A second
/// machine receives the same messages over the deck link.
class SignalHub {
  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  void Function(Map<String, dynamic> message)? transport;

  /// Joined prop phones. The deck skips its own phone peer while this is set,
  /// so one answer comes back from the machine that is actually on camera.
  int remotePeers = 0;

  Stream<Map<String, dynamic>> get messages => _messages.stream;

  void publish(Map<String, dynamic> message) {
    if (!_messages.isClosed) _messages.add(message);
    transport?.call(message);
  }

  void deliver(Map<String, dynamic> message) {
    if (!_messages.isClosed) _messages.add(message);
  }

  void dispose() {
    _messages.close();
  }
}

/// The deck captures the mic. A joined phone answers; otherwise this machine does.
bool controlMediaHere(String role) => role != 'client';

bool phoneMediaHere(String role, int remotePeers) {
  if (role == 'client') return true;
  if (role == 'host' && remotePeers > 0) return false;
  return true;
}
