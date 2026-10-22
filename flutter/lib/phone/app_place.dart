import 'package:flutter/material.dart';

import '../models.dart';
import 'catalog.dart';
import 'console_apps.dart';
import 'desk_settings.dart';
import 'mac_desk.dart';

/// Living-room tiles that are on a new TV before anyone edits the app list.
const kTvTiles = {
  'flixiq',
  'vidtube',
  'news',
  'shows',
  'sport',
  'films',
  'disney',
  'prime',
};

const _spotArea = Size(1024, 640);

/// Apps the eye treats as on the device. Computers use the desktop and the
/// dock. A TV uses its app row. Phones and tablets use the home screen.
Set<String> appSurfaceIds(PropDevice device) {
  final os = device.os;
  switch (device.kind) {
    case 'computer':
      return _computerIcons(os);
    case 'console':
      return device.os.consolePins.toSet();
    case 'tv':
      return _tvShown(os);
    default:
      final order = os.homeOrder.isEmpty ? kHomeOrder : os.homeOrder;
      return order.toSet();
  }
}

/// The library eye. Phone dock apps stay visible and locked.
Set<String> libraryShown(PropDevice device) {
  final surface = appSurfaceIds(device);
  if (device.kind == 'computer' || device.kind == 'tv' || device.kind == 'console') {
    return surface;
  }
  return {...surface, ...kDockIds};
}

Set<String> libraryLocked(PropDevice device) {
  if (device.kind == 'computer' || device.kind == 'tv' || device.kind == 'console') {
    return const {};
  }
  return kDockIds.toSet();
}

bool tvTileVisible(OsSettings os, String id) => !os.homeHidden.contains('tv-off:$id');

/// Apps added to a TV from the list, beyond the built-in row.
List<String> tvExtraApps(OsSettings os) => [
  for (final item in os.homeHidden)
    if (item.startsWith('tv-on:'))
      if (tvTileVisible(os, item.substring('tv-on:'.length)))
        item.substring('tv-on:'.length),
];

/// [shown] puts [id] on that device's home surface. Hiding takes it off.
OsSettings placeShownApp(
  OsSettings os,
  String id, {
  required String kind,
  required bool shown,
}) {
  if (id.isEmpty || id.startsWith('folder:') || id.startsWith('file:')) return os;
  switch (kind) {
    case 'computer':
      return shown ? _revealComputer(os, id) : _concealComputer(os, id);
    case 'console':
      return shown ? ConsoleLayout.pin(os, id) : ConsoleLayout.unpin(os, id);
    case 'tv':
      return _placeTv(os, id, shown: shown);
    default:
      if (kDockIds.contains(id)) return os;
      return _placeHome(os, id, shown: shown);
  }
}

Set<String> _computerIcons(OsSettings os) {
  final mac = computerShell(os.shell) == 'macos';
  final desk = mac ? MacLayout.desktop(os) : deskGridIds(os);
  final dock = mac ? MacLayout.dock(os) : deskBarIds(os);
  return {
    for (final id in [...desk, ...dock])
      if (!id.startsWith('folder:') && !id.startsWith('file:') && id != '-') id,
  };
}

Set<String> _tvShown(OsSettings os) => {
  for (final id in kTvTiles)
    if (tvTileVisible(os, id)) id,
  ...tvExtraApps(os),
};

OsSettings _placeHome(OsSettings os, String id, {required bool shown}) {
  final current = os.homeOrder.isEmpty ? [...kHomeOrder] : [...os.homeOrder];
  if (shown) {
    if (!current.contains(id)) current.add(id);
  } else {
    current.remove(id);
  }
  var next = os.copyWith(homeOrder: current);
  if (!shown || !next.dockOrder.contains(id)) return next;
  final dock = [for (final item in next.dockOrder) if (item != id) item];
  return next.copyWith(dockOrder: dock.isEmpty ? const ['-'] : dock);
}

OsSettings _placeTv(OsSettings os, String id, {required bool shown}) {
  final hidden = [
    for (final item in os.homeHidden)
      if (item != 'tv-on:$id' && item != 'tv-off:$id') item,
  ];
  if (shown) {
    if (!kTvTiles.contains(id)) hidden.add('tv-on:$id');
  } else {
    hidden.add('tv-off:$id');
  }
  return os.copyWith(homeHidden: hidden);
}

OsSettings _revealComputer(OsSettings os, String id) {
  if (computerShell(os.shell) == 'macos') return _revealMac(os, id);
  final grid = [...deskGridIds(os)];
  if (grid.contains(id)) return os;
  return writeDeskLayout(os, grid: [...grid, id]);
}

OsSettings _concealComputer(OsSettings os, String id) {
  if (computerShell(os.shell) == 'macos') return _concealMac(os, id);
  final grid = [...deskGridIds(os)];
  final bar = [...deskBarIds(os)];
  final onGrid = grid.remove(id);
  final onBar = bar.remove(id);
  if (!onGrid && !onBar) return os;
  return writeDeskLayout(
    os,
    grid: onGrid ? grid : null,
    bar: onBar ? bar : null,
  );
}

OsSettings _revealMac(OsSettings os, String id) {
  if (MacLayout.desktop(os).contains(id)) return os;
  final spots = Map<String, Offset>.from(MacLayout.spots(os, _spotArea));
  final index = spots.length;
  spots[id] = MacLayout.clampSpot(
    Offset(16 + (index % 6) * 116, 16 + (index ~/ 6) * 86),
    _spotArea,
  );
  return MacLayout.writeDesktop(os, spots, _spotArea);
}

OsSettings _concealMac(OsSettings os, String id) {
  var next = os;
  if (MacLayout.desktop(os).contains(id)) {
    final spots = Map<String, Offset>.from(MacLayout.spots(os, _spotArea))..remove(id);
    next = MacLayout.writeDesktop(next, spots, _spotArea);
  }
  final dock = [...MacLayout.dock(next)];
  if (!dock.contains(id)) return next;
  dock.remove(id);
  return MacLayout.writeDock(next, dock);
}
