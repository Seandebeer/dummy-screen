import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

Future<({double lat, double lng})?> currentFix() {
  final done = Completer<({double lat, double lng})?>();
  window.navigator.geolocation.getCurrentPosition(
    (GeolocationPosition position) {
      if (done.isCompleted) return;
      done.complete((
        lat: position.coords.latitude,
        lng: position.coords.longitude,
      ));
    }.toJS,
    (GeolocationPositionError _) {
      if (!done.isCompleted) done.complete(null);
    }.toJS,
    PositionOptions(enableHighAccuracy: true, timeout: 8000),
  );
  return done.future.timeout(
    const Duration(seconds: 8),
    onTimeout: () => null,
  );
}
