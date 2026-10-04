import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'models.dart';
import 'store.dart';

/// Local-network link so the control deck and the prop phone can be two
/// machines. The deck hosts; the phone joins the address shown on screen.
class LanLink implements StageSync {
  LanLink(this.store) {
    store.attach(this);
  }

  final StageStore store;
  final List<WebSocket> _clients = [];
  HttpServer? _server;
  WebSocket? _socket;
  Timer? _timer;
  bool _pending = false;
  int? boundPort;

  @override
  LinkRole role = LinkRole.solo;

  @override
  String status =
      'On this device only. Host the deck, then join from the prop phone.';

  @override
  String? address;

  @override
  Future<String?> host({int? port}) async {
    await disconnect();
    try {
      final server = await _bind(port);
      _server = server;
      boundPort = server.port;
      final ip = await _bestIp();
      address = '$ip:${server.port}';
      role = LinkRole.host;
      status = 'Deck is live at $address';
      server
          .transform(WebSocketTransformer())
          .listen(_accept, onError: (Object _) {});
      store.refresh();
      return address;
    } catch (_) {
      role = LinkRole.solo;
      address = null;
      status = 'Could not open a port for the deck.';
      store.refresh();
      return null;
    }
  }

  @override
  Future<void> join(String input) async {
    var raw = input.trim();
    if (raw.isEmpty) return;
    await disconnect();
    raw = raw.replaceFirst(RegExp(r'^ws://'), '');
    raw = raw.replaceFirst(RegExp(r'/.*$'), '');
    if (!raw.contains(':')) raw = '$raw:8765';
    final ready = Completer<void>();
    try {
      final socket = await WebSocket.connect('ws://$raw')
          .timeout(const Duration(seconds: 4));
      _socket = socket;
      role = LinkRole.client;
      address = raw;
      status = 'Joined deck at $raw';
      socket.listen(
        (data) {
          _onClientData(data);
          if (!ready.isCompleted) ready.complete();
        },
        onDone: () {
          if (role == LinkRole.client) {
            role = LinkRole.solo;
            status = 'The deck disconnected.';
            store.refresh();
          }
          if (!ready.isCompleted) ready.complete();
        },
        onError: (Object _) {
          if (!ready.isCompleted) ready.complete();
        },
      );
      socket.add(jsonEncode({'op': 'hello'}));
      await ready.future.timeout(const Duration(seconds: 4));
      store.refresh();
    } catch (_) {
      role = LinkRole.solo;
      address = null;
      status =
          'Could not join $raw. Check the address and that both machines share Wi-Fi.';
      store.refresh();
    }
  }

  @override
  Future<void> disconnect() async {
    _timer?.cancel();
    _timer = null;
    _pending = false;
    final clients = List<WebSocket>.of(_clients);
    _clients.clear();
    for (final client in clients) {
      try {
        await client.close();
      } catch (_) {}
    }
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
    boundPort = null;
    role = LinkRole.solo;
    address = null;
    status =
        'On this device only. Host the deck, then join from the prop phone.';
    store.refresh();
  }

  @override
  void broadcastState() {
    if (role != LinkRole.host) return;
    _pending = true;
    if (_timer != null) return;
    _timer = Timer(const Duration(milliseconds: 40), () {
      _timer = null;
      if (!_pending || role != LinkRole.host) return;
      _pending = false;
      _sendState(_clients);
    });
  }

  @override
  void sendPatch(Map<String, dynamic> patch) {
    try {
      _socket?.add(jsonEncode({'op': 'patch', 'patch': patch}));
    } catch (_) {}
  }

  void _accept(WebSocket socket) {
    _clients.add(socket);
    socket.listen(
      (data) => _onHostData(socket, data),
      onDone: () => _clients.remove(socket),
      onError: (Object _) => _clients.remove(socket),
    );
  }

  void _onHostData(WebSocket socket, dynamic data) {
    final message = _decode(data);
    if (message == null) return;
    final op = message['op'];
    if (op == 'hello') {
      try {
        socket.add(jsonEncode({'op': 'state', 'state': store.exportState()}));
      } catch (_) {}
    } else if (op == 'patch') {
      store.applyPatch(jsonMap(message['patch']));
    }
  }

  void _onClientData(dynamic data) {
    final message = _decode(data);
    if (message == null) return;
    if (message['op'] == 'state') {
      store.importState(jsonMap(message['state']));
    }
  }

  void _sendState(List<WebSocket> sockets) {
    final frame = jsonEncode({'op': 'state', 'state': store.exportState()});
    for (final socket in List<WebSocket>.of(sockets)) {
      try {
        socket.add(frame);
      } catch (_) {
        _clients.remove(socket);
      }
    }
  }

  Future<HttpServer> _bind(int? requested) async {
    if (requested != null) {
      return HttpServer.bind(InternetAddress.anyIPv4, requested);
    }
    for (var port = 8765; port < 8775; port++) {
      try {
        return await HttpServer.bind(InternetAddress.anyIPv4, port);
      } catch (_) {}
    }
    return HttpServer.bind(InternetAddress.anyIPv4, 0);
  }

  Future<String> _bestIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      final addresses = <String>[];
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback) addresses.add(address.address);
        }
      }
      addresses.sort((a, b) => _rank(a).compareTo(_rank(b)));
      if (addresses.isNotEmpty) return addresses.first;
    } catch (_) {}
    return '127.0.0.1';
  }
}

Map<String, dynamic>? _decode(dynamic data) {
  try {
    final text = data is String
        ? data
        : data is List<int>
        ? utf8.decode(data)
        : null;
    if (text == null) return null;
    final decoded = jsonDecode(text);
    if (decoded is! Map) return null;
    return jsonMap(decoded);
  } catch (_) {
    return null;
  }
}

int _rank(String ip) {
  if (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) {
    return 0;
  }
  return 1;
}
