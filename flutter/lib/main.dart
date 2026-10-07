import 'package:flutter/material.dart';

import 'app.dart';
import 'lan_link.dart';
import 'media/call_media.dart';
import 'media/signal_hub.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = StageStore();
  await store.load();
  final hub = SignalHub();
  LanLink(store, hub);
  final media = CallMedia(store, hub);
  runApp(DummyPhoneApp(store: store, media: media));
}
