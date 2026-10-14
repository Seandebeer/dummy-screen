import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../image_file.dart';
import '../models.dart';
import '../store.dart';
import '../video_source.dart';
import 'settings_kit.dart';

const kCctvMax = 16;

const _defaultNames = [
  'Gate',
  'Lobby',
  'Loading bay',
  'Stage',
  'Yard',
  'Desk',
  'Hall',
  'Lift',
  'Roof',
  'Dock',
  'Store',
  'Stairs',
  'Cafe',
  'Lab',
  'Bay',
  'Lane',
];

int cctvSlots(OsSettings os) => os.cctvCount.clamp(1, kCctvMax);

String cctvName(OsSettings os, int index) {
  if (index < os.cctvNames.length && os.cctvNames[index].trim().isNotEmpty) {
    return os.cctvNames[index].trim();
  }
  if (index < _defaultNames.length) return _defaultNames[index];
  return 'Camera ${index + 1}';
}

String cctvMediaAt(OsSettings os, int index) {
  if (index >= os.cctvMedia.length) return '';
  return os.cctvMedia[index];
}

String cctvKindAt(OsSettings os, int index) {
  if (index >= os.cctvKinds.length) return '';
  return os.cctvKinds[index];
}

List<String> _pad(List<String> source, int count) {
  return [
    for (var i = 0; i < count; i++) i < source.length ? source[i] : '',
  ];
}

OsSettings cctvWrite(
  OsSettings os, {
  int? count,
  List<String>? names,
  List<String>? media,
  List<String>? kinds,
}) {
  final next = (count ?? os.cctvCount).clamp(1, kCctvMax);
  return os.copyWith(
    cctvCount: next,
    cctvNames: _pad(names ?? os.cctvNames, next),
    cctvMedia: _pad(media ?? os.cctvMedia, next),
    cctvKinds: _pad(kinds ?? os.cctvKinds, next),
  );
}

/// Columns and rows that keep every camera inside the wall.
(int, int) cctvGrid(int count) {
  if (count <= 1) return (1, 1);
  if (count <= 2) return (2, 1);
  if (count <= 4) return (2, 2);
  if (count <= 6) return (3, 2);
  if (count <= 9) return (3, 3);
  if (count <= 12) return (4, 3);
  return (4, 4);
}

/// Camera wall. Every square stays on screen. Play starts every video at once.
class CctvWall extends StatelessWidget {
  const CctvWall({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final live = store.deviceById(device.id) ?? device;
        return _CctvBody(store: store, device: live);
      },
    );
  }
}

class _CctvBody extends StatefulWidget {
  const _CctvBody({required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<_CctvBody> createState() => _CctvBodyState();
}

class _CctvBodyState extends State<_CctvBody> {
  final _players = <int, VideoPlayerController>{};
  bool _playing = false;
  Duration _offset = Duration.zero;
  Duration _anchorOffset = Duration.zero;
  DateTime? _anchor;
  Timer? _tick;
  int? _full;
  double _in = 0;
  double _out = 1;
  bool _trim = false;

  OsSettings get os => widget.device.os;

  @override
  void initState() {
    super.initState();
    _in = os.cctvIn.clamp(0, 0.98);
    _out = os.cctvOut.clamp(_in + 0.02, 1);
    _syncPlayers();
  }

  @override
  void didUpdateWidget(covariant _CctvBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_trim &&
        (oldWidget.device.os.cctvIn != os.cctvIn || oldWidget.device.os.cctvOut != os.cctvOut)) {
      _in = os.cctvIn.clamp(0, 0.98);
      _out = os.cctvOut.clamp(_in + 0.02, 1);
    }
    _syncPlayers();
  }

  @override
  void dispose() {
    _tick?.cancel();
    for (final player in _players.values) {
      player.dispose();
    }
    super.dispose();
  }

  void _syncPlayers() {
    final count = cctvSlots(os);
    final drop = _players.keys.where((index) => index >= count).toList();
    for (final index in drop) {
      _players.remove(index)?.dispose();
    }
    for (var i = 0; i < count; i++) {
      final path = cctvMediaAt(os, i);
      final kind = cctvKindAt(os, i);
      final current = _players[i];
      if (kind != 'video' || path.isEmpty) {
        current?.dispose();
        _players.remove(i);
        continue;
      }
      final source = current?.dataSource;
      if (current != null && source == path) continue;
      current?.dispose();
      final next = playerForPath(path);
      if (next == null) {
        _players.remove(i);
        continue;
      }
      _players[i] = next;
      next.setLooping(true);
      next.initialize().then((_) {
        if (!mounted || _players[i] != next) return;
        if (_playing) next.play();
        setState(() {});
      });
    }
  }

  Duration get _span {
    var maxMs = 0;
    for (final player in _players.values) {
      if (!player.value.isInitialized) continue;
      final ms = player.value.duration.inMilliseconds;
      if (ms > maxMs) maxMs = ms;
    }
    if (maxMs < 1000) maxMs = 60000;
    return Duration(milliseconds: maxMs);
  }

  Duration _clamped(VideoPlayerController player, Duration offset) {
    if (!player.value.isInitialized) return Duration.zero;
    final length = player.value.duration;
    if (offset <= Duration.zero) return Duration.zero;
    if (length <= Duration.zero || offset < length) return offset;
    return length;
  }

  void _seekAll(Duration offset) {
    for (final player in _players.values) {
      if (player.value.isInitialized) player.seekTo(_clamped(player, offset));
    }
  }

  Duration get _loopIn => _span * _in;
  Duration get _loopOut => _span * _out;

  void _togglePlay() {
    setState(() => _playing = !_playing);
    _tick?.cancel();
    if (_playing) {
      if (_offset < _loopIn || _offset >= _loopOut) _offset = _loopIn;
      _anchor = DateTime.now();
      _anchorOffset = _offset;
      _seekAll(_offset);
      for (final player in _players.values) {
        if (player.value.isInitialized) player.play();
      }
      _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted || !_playing || _anchor == null) return;
        final next = _anchorOffset + DateTime.now().difference(_anchor!);
        final end = _loopOut;
        final start = _loopIn;
        setState(() {
          if (next >= end) {
            _offset = start;
            _anchorOffset = start;
            _anchor = DateTime.now();
            _seekAll(start);
          } else {
            _offset = next;
          }
        });
      });
    } else {
      for (final player in _players.values) {
        if (player.value.isInitialized) player.pause();
      }
    }
  }

  void _scrub(double fraction) {
    final clamped = fraction.clamp(_in, _out);
    final next = _span * clamped;
    setState(() {
      _offset = next;
      _anchorOffset = next;
      _anchor = DateTime.now();
    });
    _seekAll(next);
  }

  void _rememberLoop() {
    widget.store.updateOs(
      widget.device.id,
      (current) => current.copyWith(cctvIn: _in, cctvOut: _out),
    );
  }

  DateTime _stamp() {
    final now = DateTime.now();
    final year = os.dateYear > 0 ? os.dateYear : now.year;
    final month = os.dateMonth > 0 ? os.dateMonth : now.month;
    final day = os.dateDay > 0 ? os.dateDay : now.day;
    final start = DateTime(year, month, day, os.cctvHour, os.cctvMinute, os.cctvSecond);
    return start.add(_offset);
  }

  String _clock(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }

  String _date(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)}';
  }

  Future<void> _upload(int index) async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const [
      'png',
      'jpg',
      'jpeg',
      'gif',
      'webp',
      'mp4',
      'mov',
      'webm',
    ]);
    if (file == null || !mounted) return;
    final ext = (file.extension ?? '').toLowerCase();
    final video = ext == 'mp4' || ext == 'mov' || ext == 'webm';
    final path = video ? await persistPickedVideo(file) : await persistPickedImage(file);
    if (path == null || !mounted) return;
    final count = cctvSlots(os);
    final media = _pad(os.cctvMedia, count);
    final kinds = _pad(os.cctvKinds, count);
    media[index] = path;
    kinds[index] = video ? 'video' : 'image';
    widget.store.updateOs(
      widget.device.id,
      (current) => cctvWrite(current, media: media, kinds: kinds),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = cctvSlots(os);
    final stamp = _stamp();
    final grid = cctvGrid(count);
    return ColoredBox(
      color: const Color(0xFF050607),
      child: Column(
        children: [
          Expanded(
            child: _full == null
                ? _grid(count, grid.$1, grid.$2, stamp)
                : _cell(_full!, stamp, large: true),
          ),
          _bar(),
        ],
      ),
    );
  }

  Widget _grid(int count, int cols, int rows, DateTime stamp) {
    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Expanded(
            child: Row(
              children: [
                for (var col = 0; col < cols; col++)
                  Expanded(
                    child: () {
                      final index = row * cols + col;
                      if (index >= count) return const SizedBox.expand();
                      return _cell(index, stamp);
                    }(),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(int index, DateTime stamp, {bool large = false}) {
    final path = cctvMediaAt(os, index);
    final kind = cctvKindAt(os, index);
    final player = _players[index];
    final image = kind == 'image' ? imageProviderForPath(path) : null;
    return GestureDetector(
      key: Key('cctv-cell-$index'),
      onTap: () => setState(() => _full = large ? null : index),
      child: Container(
        margin: const EdgeInsets.all(3),
        color: const Color(0xFF101418),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (player != null && player.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: player.value.size.width,
                  height: player.value.size.height,
                  child: VideoPlayer(player),
                ),
              )
            else if (image != null)
              Image(image: image, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink())
            else
              const Center(child: Icon(Icons.videocam, color: Colors.white24, size: 28)),
            Positioned(
              left: 6,
              top: 4,
              right: 28,
              child: Text(
                cctvName(os, index),
                key: Key('cctv-name-$index'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            Positioned(
              right: 2,
              top: 0,
              child: IconButton(
                key: Key('cctv-upload-$index'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => _upload(index),
                icon: const Icon(Icons.file_upload_outlined, color: Colors.white70, size: 16),
              ),
            ),
            Positioned(
              left: 6,
              bottom: 4,
              child: Text(
                '${_date(stamp)}  ${_clock(stamp)}',
                key: Key('cctv-clock-$index'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: large ? 14 : 10,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar() {
    final span = _span.inMilliseconds;
    final fraction = span == 0 ? 0.0 : (_offset.inMilliseconds / span).clamp(0.0, 1.0);
    return Container(
      height: 36,
      color: const Color(0xFF121418),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Text(
            _clock(_stamp()),
            key: const Key('cctv-timecode'),
            style: const TextStyle(
              color: Color(0xFFE6C15A),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ClipTrack(
              key: const Key('cctv-scrub'),
              playhead: fraction,
              loopIn: _in,
              loopOut: _out,
              onScrub: _scrub,
              onTrim: (start, end) {
                final nextHead = fraction < start ? start : (fraction > end ? end : fraction);
                setState(() {
                  _trim = true;
                  _in = start;
                  _out = end;
                  if (nextHead != fraction) {
                    final next = _span * nextHead;
                    _offset = next;
                    _anchorOffset = next;
                    _anchor = DateTime.now();
                  }
                });
                if (nextHead != fraction) _seekAll(_span * nextHead);
              },
              onTrimEnd: () {
                _trim = false;
                _rememberLoop();
              },
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            key: const Key('cctv-play'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: _togglePlay,
            icon: Icon(_playing ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Slim editor clip. The handles shorten the loop; playback stays inside it.
class _ClipTrack extends StatelessWidget {
  const _ClipTrack({
    super.key,
    required this.playhead,
    required this.loopIn,
    required this.loopOut,
    required this.onScrub,
    required this.onTrim,
    required this.onTrimEnd,
  });

  final double playhead;
  final double loopIn;
  final double loopOut;
  final ValueChanged<double> onScrub;
  final void Function(double start, double end) onTrim;
  final VoidCallback onTrimEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double at(double local) => width <= 0 ? 0 : (local / width).clamp(0.0, 1.0);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => onScrub(at(details.localPosition.dx)),
          onHorizontalDragUpdate: (details) => onScrub(at(details.localPosition.dx)),
          child: CustomPaint(
            painter: _ClipPainter(playhead: playhead, loopIn: loopIn, loopOut: loopOut),
            child: Stack(
              children: [
                _trimHandle(
                  fraction: loopIn,
                  width: width,
                  at: at,
                  onDrag: (next) => onTrim(next.clamp(0, loopOut - 0.02), loopOut),
                ),
                _trimHandle(
                  fraction: loopOut,
                  width: width,
                  at: at,
                  onDrag: (next) => onTrim(loopIn, next.clamp(loopIn + 0.02, 1)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _trimHandle({
    required double fraction,
    required double width,
    required double Function(double local) at,
    required ValueChanged<double> onDrag,
  }) {
    final left = (width * fraction - 6).clamp(0.0, width <= 12 ? 0.0 : width - 12);
    return Positioned(
      left: left,
      top: 4,
      bottom: 4,
      width: 12,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) => onDrag(at(left + details.localPosition.dx)),
        onHorizontalDragEnd: (_) => onTrimEnd(),
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFF2F2F2),
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ),
    );
  }
}

class _ClipPainter extends CustomPainter {
  const _ClipPainter({required this.playhead, required this.loopIn, required this.loopOut});

  final double playhead;
  final double loopIn;
  final double loopOut;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height / 2 - 7, size.width, 14),
      const Radius.circular(3),
    );
    canvas.drawRRect(track, Paint()..color = const Color(0xFF2A2E34));
    final left = size.width * loopIn;
    final right = size.width * loopOut;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left, size.height / 2 - 7, right, size.height / 2 + 7),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF3D6EA8),
    );
    const ticks = 12;
    final tick = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1;
    for (var i = 1; i < ticks; i++) {
      final x = size.width * i / ticks;
      canvas.drawLine(Offset(x, size.height / 2 - 3), Offset(x, size.height / 2 + 3), tick);
    }
    final head = size.width * playhead.clamp(0, 1);
    canvas.drawLine(
      Offset(head, 2),
      Offset(head, size.height - 2),
      Paint()
        ..color = const Color(0xFFE6C15A)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ClipPainter oldDelegate) =>
      oldDelegate.playhead != playhead || oldDelegate.loopIn != loopIn || oldDelegate.loopOut != loopOut;
}

/// Camera count, names, footage, and the clock the wall starts from.
class CctvSettingsBody extends StatelessWidget {
  const CctvSettingsBody({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  OsSettings get os => device.os;

  @override
  Widget build(BuildContext context) {
    final count = cctvSlots(os);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSection(
          title: 'Cameras',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('$count', style: const TextStyle(fontWeight: FontWeight.w600)),
              Slider(
                key: const Key('cctv-count'),
                value: count.toDouble(),
                min: 1,
                max: kCctvMax.toDouble(),
                divisions: kCctvMax - 1,
                label: '$count',
                onChanged: (value) => store.updateOs(
                  device.id,
                  (current) => cctvWrite(current, count: value.round()),
                ),
              ),
            ],
          ),
        ),
        SettingsSection(
          title: 'Start from',
          child: _StartClock(store: store, device: device),
        ),
        SettingsSection(
          title: 'Names and footage',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < count; i++) ...[
                SettingsField(
                  fieldKey: Key('cctv-rename-$i'),
                  label: 'Camera ${i + 1}',
                  value: cctvName(os, i),
                  onChanged: (value) {
                    final names = _pad(os.cctvNames, count);
                    names[i] = value.trim();
                    store.updateOs(device.id, (current) => cctvWrite(current, names: names));
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: Key('cctv-settings-upload-$i'),
                    onPressed: () => _pick(i),
                    child: Text(
                      cctvMediaAt(os, i).isEmpty ? 'Upload picture or footage' : 'Replace picture or footage',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pick(int index) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'gif', 'webp', 'mp4', 'mov', 'webm'],
    );
    if (file == null) return;
    final ext = (file.extension ?? '').toLowerCase();
    final video = ext == 'mp4' || ext == 'mov' || ext == 'webm';
    final path = video ? await persistPickedVideo(file) : await persistPickedImage(file);
    if (path == null) return;
    final count = cctvSlots(os);
    final media = _pad(os.cctvMedia, count);
    final kinds = _pad(os.cctvKinds, count);
    media[index] = path;
    kinds[index] = video ? 'video' : 'image';
    store.updateOs(device.id, (current) => cctvWrite(current, media: media, kinds: kinds));
  }
}

/// One bar of hour, minute, and second, with the colons already drawn.
class _StartClock extends StatefulWidget {
  const _StartClock({required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<_StartClock> createState() => _StartClockState();
}

class _StartClockState extends State<_StartClock> {
  late final TextEditingController _hour;
  late final TextEditingController _minute;
  late final TextEditingController _second;
  final _hourFocus = FocusNode();
  final _minuteFocus = FocusNode();
  final _secondFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final os = widget.device.os;
    _hour = TextEditingController(text: _two(os.cctvHour));
    _minute = TextEditingController(text: _two(os.cctvMinute));
    _second = TextEditingController(text: _two(os.cctvSecond));
  }

  @override
  void didUpdateWidget(_StartClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final os = widget.device.os;
    _sync(_hour, _hourFocus, os.cctvHour);
    _sync(_minute, _minuteFocus, os.cctvMinute);
    _sync(_second, _secondFocus, os.cctvSecond);
  }

  @override
  void dispose() {
    _hour.dispose();
    _minute.dispose();
    _second.dispose();
    _hourFocus.dispose();
    _minuteFocus.dispose();
    _secondFocus.dispose();
    super.dispose();
  }

  void _sync(TextEditingController controller, FocusNode focus, int value) {
    if (focus.hasFocus) return;
    final text = _two(value);
    if (controller.text != text) controller.text = text;
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  void _write() {
    widget.store.updateOs(
      widget.device.id,
      (current) => current.copyWith(
        cctvHour: int.tryParse(_hour.text)?.clamp(0, 23) ?? 0,
        cctvMinute: int.tryParse(_minute.text)?.clamp(0, 59) ?? 0,
        cctvSecond: int.tryParse(_second.text)?.clamp(0, 59) ?? 0,
      ),
    );
  }

  void _finish(TextEditingController controller, int max) {
    final parsed = int.tryParse(controller.text) ?? 0;
    final text = _two(parsed.clamp(0, max));
    if (controller.text != text) {
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    _write();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66000000),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            _cell(_hour, _hourFocus, 'cctv-hour', 23),
            const Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            _cell(_minute, _minuteFocus, 'cctv-minute', 59),
            const Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            _cell(_second, _secondFocus, 'cctv-second', 59),
          ],
        ),
      ),
    );
  }

  Widget _cell(TextEditingController controller, FocusNode focus, String keyName, int max) {
    return Expanded(
      child: TextField(
        key: Key(keyName),
        controller: controller,
        focusNode: focus,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 2,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.length >= 2) {
            _finish(controller, max);
          } else {
            _write();
          }
        },
        onEditingComplete: () => _finish(controller, max),
      ),
    );
  }
}
