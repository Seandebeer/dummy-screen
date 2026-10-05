import 'package:flutter/material.dart';

import 'media/call_media.dart';
import 'screens/shell.dart';
import 'store.dart';
import 'theme.dart';

class StoreScope extends InheritedNotifier<StageStore> {
  const StoreScope({super.key, required StageStore store, required super.child})
    : super(notifier: store);

  static StageStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StoreScope>();
    assert(scope != null, 'StoreScope is missing above this widget');
    return scope!.notifier!;
  }
}

class DummyPhoneApp extends StatelessWidget {
  const DummyPhoneApp({super.key, required this.store, this.media});

  final StageStore store;
  final CallMedia? media;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: CallMediaScope(
        media: media,
        child: MaterialApp(
          title: 'Dummy Phone',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: const Shell(),
        ),
      ),
    );
  }
}
