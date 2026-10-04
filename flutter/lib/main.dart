import 'package:flutter/material.dart';

import 'app.dart';
import 'lan_link.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = StageStore();
  await store.load();
  LanLink(store);
  runApp(DummyPhoneApp(store: store));
}
