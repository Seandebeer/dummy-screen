import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'geo_fix.dart';
import 'place_search.dart';
import 'ios_keyboard.dart';
import 'route_math.dart';

const _speeds = [1, 8, 32];
const _baseSpeed = 50 / 3.6;

/// Maps chrome from MapsApp.jsx: search, basemap, tap-to-route, and playback.
/// Tiles are OpenStreetMap, Esri, and OpenTopoMap. A painted land colour
/// shows through when a tile cannot load.
class MapsApp extends StatefulWidget {
  const MapsApp({super.key});

  @override
  State<MapsApp> createState() => _MapsAppState();
}

class _Geo {
  _Geo(this.lat, this.lng);

  double lat;
  double lng;
}

class _MapsAppState extends State<MapsApp> {
  _Geo? _origin;
  final _stops = <_Geo>[];
  _Geo? _me;
  _Geo? _place;
  String _placeName = '';
  String _placeAddress = '';
  String _layer = 'map';
  final _query = TextEditingController();
  List<PlaceHit>? _results;
  bool _searching = false;
  bool _locating = false;
  bool _playing = false;
  double _dist = 0;
  int _speed = 1;
  int _zoom = 13;
  double _lat = -26.2041;
  double _lng = 28.0473;
  int? _selectedStop;
  Timer? _play;
  int _lastTick = 0;
  Offset? _lastFocal;
  int? _dragStop;
  double _moved = 0;
  int _gestureZoom = 13;
  bool _zoomed = false;

  @override
  void dispose() {
    _play?.cancel();
    _query.dispose();
    super.dispose();
  }

  List<({double lat, double lng})> get _points => [
    if (_origin != null) (lat: _origin!.lat, lng: _origin!.lng),
    for (final stop in _stops) (lat: stop.lat, lng: stop.lng),
  ];

  RoutePath? get _route => buildRoute(_points);

  void _addPoint(double lat, double lng) {
    setState(() {
      _dist = 0;
      _playing = false;
      _place = null;
      if (_origin == null) {
        _origin = _Geo(lat, lng);
      } else {
        _stops.add(_Geo(lat, lng));
      }
      _fit(_points);
    });
  }

  void _fit(List<({double lat, double lng})> points) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      _lat = points.first.lat;
      _lng = points.first.lng;
      _zoom = 14;
      return;
    }
    var minLat = points.first.lat;
    var maxLat = minLat;
    var minLng = points.first.lng;
    var maxLng = minLng;
    for (final point in points) {
      minLat = math.min(minLat, point.lat);
      maxLat = math.max(maxLat, point.lat);
      minLng = math.min(minLng, point.lng);
      maxLng = math.max(maxLng, point.lng);
    }
    _lat = (minLat + maxLat) / 2;
    _lng = (minLng + maxLng) / 2;
    final dLat = math.max(0.002, maxLat - minLat);
    final dLng = math.max(0.002, maxLng - minLng);
    final zLng = math.log(360 / dLng * 1.4) / math.ln2;
    final zLat = math.log(170 / dLat * 1.1) / math.ln2;
    _zoom = math.min(zLng, zLat).round().clamp(3, 16);
  }

  void _fly(double lat, double lng, int zoom) {
    _lat = lat;
    _lng = lng;
    _zoom = zoom;
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _results = null;
    });
    try {
      final hits = await searchPlaces(q);
      if (!mounted) return;
      setState(() {
        _results = hits;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _searching = false;
      });
    }
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    final fix = await currentFix();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (fix == null) return;
      _me = _Geo(fix.lat, fix.lng);
      _origin ??= _Geo(fix.lat, fix.lng);
      _fly(fix.lat, fix.lng, 15);
    });
  }

  void _resetTrip() {
    _play?.cancel();
    setState(() {
      _dist = 0;
      _playing = false;
    });
    _togglePlay();
  }

  void _clear() {
    _play?.cancel();
    setState(() {
      _origin = null;
      _stops.clear();
      _dist = 0;
      _playing = false;
      _selectedStop = null;
      _place = null;
    });
  }

  void _togglePlay() {
    final route = _route;
    if (route == null) return;
    if (!_playing && _dist >= route.total) _dist = 0;
    setState(() => _playing = !_playing);
    _play?.cancel();
    if (!_playing) return;
    _lastTick = DateTime.now().millisecondsSinceEpoch;
    _play = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final route = _route;
      if (!mounted || route == null) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      final dt = (now - _lastTick) / 1000;
      _lastTick = now;
      final speed = _baseSpeed * _speeds[_speed];
      setState(() {
        _dist = math.min(_dist + dt * speed, route.total);
        if (_dist >= route.total) {
          _playing = false;
          _play?.cancel();
        }
      });
    });
  }

  void _cycleLayer() {
    setState(() {
      _layer = _layer == 'map'
          ? 'satellite'
          : _layer == 'satellite'
          ? 'terrain'
          : 'map';
    });
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    final pos = route == null ? null : positionAt(route, _dist);
    final arrived = route != null && _dist >= route.total;
    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            children: [
              Positioned.fill(child: _map(size, route, pos)),
              Positioned(
                left: 8,
                right: 8,
                top: 8,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Chip(child: Text('Maps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    const Spacer(),
                    _IconChip(
                      onTap: _cycleLayer,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.layers, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _layer == 'map' ? 'Map' : _layer,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    _IconChip(
                      onTap: _locating ? null : _locate,
                      child: _locating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                            )
                          : const Icon(Icons.my_location, size: 14),
                    ),
                    if (_origin != null || _stops.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _IconChip(
                        onTap: _resetTrip,
                        child: const Text('Reset', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      _IconChip(
                        onTap: _clear,
                        child: const Icon(Icons.delete_outline, size: 14),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(left: 8, right: 8, top: 48, child: _searchBar()),
              if (_results == null && _place == null && _origin == null)
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 92,
                  child: _Hint('Tap the map to set your start point'),
                )
              else if (_results == null && _place == null && _stops.isEmpty)
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 92,
                  child: _Hint('Tap to add stops · drag pins to adjust'),
                ),
              Positioned(
                right: 8,
                top: size.height / 2 - 28,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xBF000000),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      _zoomButton('+', () => setState(() => _zoom = math.min(18, _zoom + 1))),
                      Container(height: 1, width: 28, color: Colors.white24),
                      _zoomButton('−', () => setState(() => _zoom = math.max(3, _zoom - 1))),
                    ],
                  ),
                ),
              ),
              if (_selectedStop != null && _selectedStop! < _stops.length)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: route == null ? 12 : 108,
                  child: Center(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xE6EF4444)),
                      onPressed: () => setState(() {
                        _stops.removeAt(_selectedStop!);
                        _selectedStop = null;
                        _dist = 0;
                      }),
                      child: const Text('Remove stop'),
                    ),
                  ),
                ),
              if (route != null && pos != null)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: _navCard(route, pos, arrived),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _zoomButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 28,
        child: Center(
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xCC000000),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              _searching
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white70),
                    )
                  : const Icon(Icons.search, size: 14, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _query,
                  readOnly: true,
                  showCursor: true,
                  onTap: () => openIosKeyboard(
                    context,
                    _query,
                    onChanged: (_) => setState(() {}),
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Search places…',
                    hintStyle: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  onSubmitted: (_) => _search(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_query.text.isNotEmpty)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() {
                    _query.clear();
                    _results = null;
                  }),
                  icon: const Icon(Icons.close, size: 14, color: Colors.white60),
                ),
            ],
          ),
        ),
        if (_results != null)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: const Color(0xE6000000),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: _results!.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No places found', style: TextStyle(fontSize: 11, color: Colors.white60)),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < _results!.length; i++)
                        InkWell(
                          onTap: () => setState(() {
                            final hit = _results![i];
                            _place = _Geo(hit.lat, hit.lng);
                            _placeName = hit.name;
                            _placeAddress = hit.address;
                            _results = null;
                            _query.clear();
                            _fly(hit.lat, hit.lng, 15);
                          }),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: i == 0
                                  ? null
                                  : const Border(top: BorderSide(color: Colors.white24)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _results![i].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  _results![i].address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        if (_place != null && _results == null)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: BoxDecoration(
              color: const Color(0xE6FFFFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _placeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _placeAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final place = _place;
                    if (place == null) return;
                    _addPoint(place.lat, place.lng);
                  },
                  child: Text(_origin == null ? 'Set as start' : 'Add as stop'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _navCard(RoutePath route, RouteFix pos, bool arrived) {
    final leg = route.legs[pos.legIndex];
    final instruction = arrived
        ? 'You have arrived'
        : pos.legIndex == 0
        ? 'Head ${compass(leg.bearing)}'
        : '${turnName(leg.turnDelta)}, then head ${compass(leg.bearing)}';
    final remaining = route.total - _dist;
    final speed = _baseSpeed * _speeds[_speed];
    final next = pos.legIndex < _stops.length
        ? 'Stop ${pos.legIndex + 1} in ${fmtDist(pos.legRemaining)}'
        : '';
    final detail = arrived
        ? '${_stops.length} stop${_stops.length == 1 ? '' : 's'} · ${fmtDist(route.total)} total'
        : '${next.isEmpty ? 'Approaching destination' : next} · ${fmtDist(remaining)} left · ETA ${fmtEta(remaining / speed)}';
    final progress = route.total == 0 ? 0.0 : (_dist / route.total).clamp(0, 1).toDouble();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _roundIcon(
                  Icons.replay,
                  () => setState(() {
                    _dist = 0;
                    _playing = false;
                    _play?.cancel();
                  }),
                ),
                const SizedBox(width: 8),
                Material(
                  color: const Color(0xFF0A84FF),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _togglePlay,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(_playing ? Icons.pause : Icons.play_arrow, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instruction,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    for (var i = 0; i < _speeds.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: GestureDetector(
                          onTap: () => setState(() => _speed = i),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: i == _speed ? Colors.white : Colors.white10,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Text(
                                '${_speeds[i]}×',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: i == _speed ? Colors.black : Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.white24,
                color: const Color(0xFF0A84FF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white10,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 32, height: 32, child: Icon(icon, size: 14)),
      ),
    );
  }

  Widget _map(Size size, RoutePath? route, RouteFix? puck) {
    return GestureDetector(
      onScaleStart: (details) {
        _lastFocal = details.localFocalPoint;
        _moved = 0;
        _gestureZoom = _zoom;
        _zoomed = false;
        _dragStop = _hitStop(details.localFocalPoint, size);
      },
      onScaleUpdate: (details) {
        final previous = _lastFocal ?? details.localFocalPoint;
        final delta = details.localFocalPoint - previous;
        _lastFocal = details.localFocalPoint;
        _moved += delta.distance;
        setState(() {
          if (_dragStop != null && _dragStop! < _stops.length) {
            final at = _latLngAt(details.localFocalPoint, size);
            _stops[_dragStop!].lat = at.lat;
            _stops[_dragStop!].lng = at.lng;
            return;
          }
          final center = _project(_lat, _lng, _zoom);
          final next = _unproject(center.dx - delta.dx, center.dy - delta.dy, _zoom);
          _lat = next.lat.clamp(-85, 85);
          _lng = next.lng;
          if (!_zoomed && details.scale > 1.18) {
            _zoom = math.min(18, _gestureZoom + 1);
            _zoomed = true;
          } else if (!_zoomed && details.scale < 0.84) {
            _zoom = math.max(3, _gestureZoom - 1);
            _zoomed = true;
          }
        });
      },
      onScaleEnd: (_) {
        if (_moved < 8 && !_zoomed && _dragStop == null && _lastFocal != null) {
          final at = _latLngAt(_lastFocal!, size);
          _addPoint(at.lat, at.lng);
        } else if (_moved < 8 && _dragStop != null) {
          setState(() => _selectedStop = _dragStop);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: _wash),
          ..._tiles(size),
          CustomPaint(
            painter: _OverlayPainter(
              zoom: _zoom,
              centerLat: _lat,
              centerLng: _lng,
              origin: _origin,
              stops: _stops,
              me: _me,
              place: _place,
              puck: puck == null || _dist <= 0 ? null : puck,
              route: _points,
            ),
          ),
        ],
      ),
    );
  }

  Color get _wash {
    switch (_layer) {
      case 'satellite':
        return const Color(0xFF1A1A1A);
      case 'terrain':
        return const Color(0xFFE6E1D6);
      default:
        return const Color(0xFFAAD3DF);
    }
  }

  List<Widget> _tiles(Size size) {
    final n = 1 << _zoom;
    final center = _project(_lat, _lng, _zoom);
    final left = center.dx - size.width / 2;
    final top = center.dy - size.height / 2;
    final x0 = (left / 256).floor() - 1;
    final y0 = (top / 256).floor() - 1;
    final x1 = ((left + size.width) / 256).ceil() + 1;
    final y1 = ((top + size.height) / 256).ceil() + 1;
    final tiles = <Widget>[];
    for (var x = x0; x <= x1; x++) {
      for (var y = y0; y <= y1; y++) {
        if (y < 0 || y >= n) continue;
        final wrapped = ((x % n) + n) % n;
        final dx = size.width / 2 + (x * 256 - center.dx);
        final dy = size.height / 2 + (y * 256 - center.dy);
        tiles.add(
          Positioned(
            left: dx,
            top: dy,
            width: 256,
            height: 256,
            child: Image.network(
              _tileUrl(wrapped, y),
              width: 256,
              height: 256,
              fit: BoxFit.fill,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        );
      }
    }
    return tiles;
  }

  String _tileUrl(int x, int y) {
    switch (_layer) {
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$_zoom/$y/$x';
      case 'terrain':
        final sub = 'abc'[(x + y) % 3];
        return 'https://$sub.tile.opentopomap.org/$_zoom/$x/$y.png';
      default:
        final sub = 'abc'[(x + y) % 3];
        return 'https://$sub.tile.openstreetmap.org/$_zoom/$x/$y.png';
    }
  }

  int? _hitStop(Offset point, Size size) {
    for (var i = _stops.length - 1; i >= 0; i--) {
      final screen = _screen(_stops[i].lat, _stops[i].lng, size);
      if ((screen - point).distance < 18) return i;
    }
    return null;
  }

  ({double lat, double lng}) _latLngAt(Offset point, Size size) {
    final center = _project(_lat, _lng, _zoom);
    return _unproject(
      center.dx + (point.dx - size.width / 2),
      center.dy + (point.dy - size.height / 2),
      _zoom,
    );
  }

  Offset _screen(double lat, double lng, Size size) {
    final point = _project(lat, lng, _zoom);
    final center = _project(_lat, _lng, _zoom);
    return Offset(
      size.width / 2 + (point.dx - center.dx),
      size.height / 2 + (point.dy - center.dy),
    );
  }

  Offset _project(double lat, double lng, int zoom) {
    final world = 256.0 * math.pow(2, zoom);
    final x = (lng + 180) / 360 * world;
    final s = math.sin(lat.clamp(-85, 85) * math.pi / 180);
    final y = (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * world;
    return Offset(x, y);
  }

  ({double lat, double lng}) _unproject(double x, double y, int zoom) {
    final world = 256.0 * math.pow(2, zoom);
    final lng = x / world * 360 - 180;
    final n = math.pi - 2 * math.pi * y / world;
    final lat = math.atan((math.exp(n) - math.exp(-n)) / 2) * 180 / math.pi;
    return (lat: lat, lng: lng);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: child,
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCC000000),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xBF000000),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  _OverlayPainter({
    required this.zoom,
    required this.centerLat,
    required this.centerLng,
    required this.origin,
    required this.stops,
    required this.me,
    required this.place,
    required this.puck,
    required this.route,
  });

  final int zoom;
  final double centerLat;
  final double centerLng;
  final _Geo? origin;
  final List<_Geo> stops;
  final _Geo? me;
  final _Geo? place;
  final RouteFix? puck;
  final List<({double lat, double lng})> route;

  @override
  void paint(Canvas canvas, Size size) {
    Offset at(double lat, double lng) {
      final world = 256.0 * math.pow(2, zoom);
      Offset project(double pLat, double pLng) {
        final x = (pLng + 180) / 360 * world;
        final s = math.sin(pLat.clamp(-85, 85) * math.pi / 180);
        final y = (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * world;
        return Offset(x, y);
      }

      final point = project(lat, lng);
      final center = project(centerLat, centerLng);
      return Offset(
        size.width / 2 + (point.dx - center.dx),
        size.height / 2 + (point.dy - center.dy),
      );
    }

    if (route.length >= 2) {
      final path = Path()..moveTo(at(route.first.lat, route.first.lng).dx, at(route.first.lat, route.first.lng).dy);
      for (final point in route.skip(1)) {
        final screen = at(point.lat, point.lng);
        path.lineTo(screen.dx, screen.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xD90A84FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final start = origin;
    if (start != null) {
      final screen = at(start.lat, start.lng);
      canvas.drawCircle(screen, 9, Paint()..color = Colors.white);
      canvas.drawCircle(screen, 6, Paint()..color = const Color(0xFF0A84FF));
    }
    for (var i = 0; i < stops.length; i++) {
      final screen = at(stops[i].lat, stops[i].lng);
      canvas.drawCircle(screen, 12, Paint()..color = Colors.white);
      canvas.drawCircle(
        screen,
        10,
        Paint()
          ..color = const Color(0xFFFF3B30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      final text = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 11, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, screen - Offset(text.width / 2, text.height / 2));
    }
    final here = me;
    if (here != null) {
      final screen = at(here.lat, here.lng);
      canvas.drawCircle(screen, 10, Paint()..color = const Color(0x4D0A84FF));
      canvas.drawCircle(screen, 6, Paint()..color = const Color(0xFF0A84FF));
      canvas.drawCircle(
        screen,
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final pin = place;
    if (pin != null) {
      final screen = at(pin.lat, pin.lng);
      final path = Path()
        ..moveTo(screen.dx, screen.dy)
        ..cubicTo(screen.dx - 8, screen.dy - 14, screen.dx - 12, screen.dy - 28, screen.dx, screen.dy - 28)
        ..cubicTo(screen.dx + 12, screen.dy - 28, screen.dx + 8, screen.dy - 14, screen.dx, screen.dy);
      canvas.drawPath(path, Paint()..color = const Color(0xFFEA4335));
      canvas.drawCircle(screen + const Offset(0, -20), 4, Paint()..color = Colors.white);
    }
    if (puck != null) {
      final screen = at(puck!.lat, puck!.lng);
      canvas.save();
      canvas.translate(screen.dx, screen.dy);
      canvas.rotate(puck!.bearing * math.pi / 180);
      final arrow = Path()
        ..moveTo(0, -16)
        ..lineTo(5, -6)
        ..lineTo(-5, -6)
        ..close();
      canvas.drawPath(arrow, Paint()..color = const Color(0xFF0A84FF));
      canvas.restore();
      canvas.drawCircle(screen, 8, Paint()..color = Colors.white);
      canvas.drawCircle(screen, 5, Paint()..color = const Color(0xFF0A84FF));
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) => true;
}
