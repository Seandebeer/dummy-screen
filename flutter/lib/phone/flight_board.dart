import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import 'transport.dart';

const _board = Color(0xFF0A3C8C);
const _band = Color(0xFF0E4EAE);
const _yellow = Color(0xFFFFD400);
const _ink = Colors.white;
const _alert = Color(0xFFFF3B30);

const kFlightStatusCycle = ['ON TIME', 'DELAYED', 'CANCELLED'];

/// The three statuses a tap walks through. Anything else starts at On time.
String nextFlightStatus(String current) {
  final label = flightStatusLabel(current);
  final index = kFlightStatusCycle.indexOf(label);
  return kFlightStatusCycle[(index + 1) % kFlightStatusCycle.length];
}

String flightStatusLabel(String raw) {
  final text = raw.trim().toUpperCase();
  if (text.startsWith('DELAY')) return 'DELAYED';
  if (text.contains('CANCEL')) return 'CANCELLED';
  return raw.trim().isEmpty ? 'ON TIME' : raw.trim();
}

String flightCodeLabel(String raw) {
  final text = raw.trim();
  if (RegExp(r'^[A-Za-z]{2}\b').hasMatch(text)) return text;
  const known = {
    '593420': 'SQ 593420',
    '563240': 'BV 563240',
    '762': 'SN 0762',
  };
  if (known.containsKey(text)) return known[text]!;
  if (RegExp(r'^\d').hasMatch(text)) return 'XX $text';
  return text;
}

String flightGateLabel(String raw, int index) {
  final text = raw.trim().toUpperCase();
  if (RegExp(r'^[A-G]\d').hasMatch(text)) return text;
  final digits = RegExp(r'\d+').firstMatch(text)?.group(0) ?? '${index + 1}';
  const letters = 'ABCDEFG';
  return '${letters[index % letters.length]}$digits';
}

List<String> presentFlight(List<String> cells, int index) {
  final next = [for (var i = 0; i < 7; i++) i < cells.length ? cells[i] : ''];
  next[3] = flightCodeLabel(next[3]);
  next[5] = flightStatusLabel(next[5]);
  next[6] = flightGateLabel(next[6], index);
  return next;
}

/// Glass text. Unbranded swaps a known operator for a fictional name and
/// rewrites the letter code so the prefix still belongs to that name.
List<String> displayTransport(
  List<String> cells,
  int index, {
  required String mode,
  required bool branded,
}) {
  final next = [for (var i = 0; i < 7; i++) i < cells.length ? cells[i] : ''];
  next[5] = flightStatusLabel(next[5]);
  if (transportMode(mode) == 'flight') next[6] = flightGateLabel(next[6], index);
  final generic = branded ? null : genericCarrier(next[2], mode);
  if (generic == null) {
    next[3] = flightCodeLabel(next[3]);
  } else {
    next[2] = generic.$1;
    next[3] = _withPrefix(flightCodeLabel(next[3]), generic.$2);
  }
  return next;
}

String _withPrefix(String code, String prefix) {
  final rest = RegExp(r'^[A-Za-z]{1,3}\s+(.*)$').firstMatch(code.trim());
  if (rest != null) return '$prefix ${rest.group(1)}';
  final bare = code.trim();
  return bare.isEmpty ? prefix : '$prefix $bare';
}

IconData transportMark(String mode) {
  return switch (transportMode(mode)) {
    'train' => Icons.train,
    'bus' => Icons.directions_bus,
    'ferry' => Icons.directions_boat,
    _ => Icons.flight_takeoff,
  };
}

List<String> paddedFlightRows(List<String> stored, List<String> defaults) {
  if (stored.length >= defaults.length) return stored;
  return [...stored, ...defaults.skip(stored.length)];
}

/// Departures board for an airport, station, bus stop, or dock.
class FlightBoard extends StatelessWidget {
  const FlightBoard({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final live = store.deviceById(device.id) ?? device;
        return _FlightBody(store: store, device: live);
      },
    );
  }
}

class _FlightBody extends StatefulWidget {
  const _FlightBody({required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<_FlightBody> createState() => _FlightBodyState();
}

class _FlightBodyState extends State<_FlightBody> {
  Timer? _flip;
  int _which = 0;
  int _waited = 0;
  bool _typing = false;

  OsSettings get os => widget.device.os;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(covariant _FlightBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device.os.flightFlip != os.flightFlip ||
        oldWidget.device.os.flightFlipSeconds != os.flightFlipSeconds) {
      _waited = 0;
      _arm();
    }
    if (!os.flightFlip) _which = 0;
  }

  @override
  void dispose() {
    _flip?.cancel();
    super.dispose();
  }

  void _arm() {
    _flip?.cancel();
    if (!os.flightFlip) return;
    _flip = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _typing) return;
      final seconds = os.flightFlipSeconds < 2 ? 2 : os.flightFlipSeconds;
      _waited++;
      if (_waited < seconds) return;
      _waited = 0;
      setState(() => _which = _which == 0 ? 1 : 0);
    });
  }

  void _save(OsSettings Function(OsSettings current) change) {
    widget.store.updateOs(widget.device.id, change);
  }

  String get _mode => transportMode(os.face);

  List<String> get _rows => paddedFlightRows(
    _which == 0 ? os.flightA : os.flightB,
    transportBoard(_mode, second: _which == 1),
  );

  void _writeCell(int row, int column, String value) {
    final source = [..._rows];
    while (source.length <= row) {
      source.add(flightRow(const ['', '', '', '', '', '', '']));
    }
    final cells = flightCells(source[row]);
    cells[column] = value.trim();
    if (column == 5) cells[column] = flightStatusLabel(cells[column]);
    if (column == 3) cells[column] = flightCodeLabel(cells[column]);
    if (column == 6 && _mode == 'flight') cells[column] = flightGateLabel(cells[column], row);
    source[row] = flightRow(cells);
    final placed = column == 0 ? orderedFlightBoard(source, row) : source;
    _save((current) => _which == 0 ? current.copyWith(flightA: placed) : current.copyWith(flightB: placed));
  }

  void _writeColumn(int column, String value) {
    final fallback = transportColumns(_mode, os.flightHeading);
    final columns = [
      for (var i = 0; i < 7; i++)
        i < os.flightColumns.length ? os.flightColumns[i] : fallback[i],
    ];
    columns[column] = value;
    _save((current) => current.copyWith(flightColumns: columns));
  }

  @override
  Widget build(BuildContext context) {
    final editing = !widget.store.filming;
    final heading = os.flightHeading == 'none' ? '' : _title;
    final rows = _rows;
    final board = _color(os.flightBoardColor, _board);
    final header = _color(os.flightHeaderColor, _yellow);
    final body = _color(os.flightBodyColor, _ink);
    return ColoredBox(
      key: const Key('flight-board'),
      color: board,
      child: Column(
        children: [
          if (heading.isNotEmpty) _mast(editing, heading, header),
          _columns(editing, body),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  Expanded(
                    child: _dataRow(
                      i,
                      displayTransport(
                        flightCells(rows[i]),
                        i,
                        mode: _mode,
                        branded: os.branded,
                      ),
                      editing,
                      board,
                      body,
                      header,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _title {
    final typed = os.flightTitle.trim();
    if (typed.isNotEmpty) return typed;
    return transportHeading(_mode, os.flightHeading);
  }

  Color _color(String hex, Color fallback) {
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return fallback;
    return Color(0xFF000000 | value);
  }

  Widget _mast(bool editing, String heading, Color header) {
    final now = osNow(os);
    final clock = formatOsClock(now, hour24: true);
    return Container(
      height: 118,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: header, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 188),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final room = (constraints.maxWidth - 68).clamp(80.0, constraints.maxWidth);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: header, width: 2),
                      ),
                      child: Icon(transportMark(_mode), color: header, size: 32),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: room),
                      child: _TypeText(
                        fieldKey: const Key('flight-heading'),
                        text: heading,
                        editing: editing,
                        hug: true,
                        align: TextAlign.left,
                        style: TextStyle(
                          color: header,
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                        onTyping: (value) => setState(() => _typing = value),
                        onSubmit: (value) {
                          final next = value.trim();
                          _save((current) => current.copyWith(flightTitle: next.isEmpty ? _title : next));
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(
            width: 188,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _TypeText(
                  fieldKey: const Key('flight-clock'),
                  text: clock,
                  editing: editing,
                  align: TextAlign.right,
                  style: TextStyle(
                    color: header,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  onTyping: (value) => setState(() => _typing = value),
                  onSubmit: (value) {
                    final parsed = parseClockText(value);
                    if (parsed == null) return;
                    _save((current) => pinClock(current, parsed.$1, parsed.$2));
                  },
                ),
                const SizedBox(height: 6),
                _TypeText(
                  fieldKey: const Key('flight-date'),
                  text: os.flightDate,
                  editing: editing,
                  align: TextAlign.right,
                  style: TextStyle(color: header, fontSize: 14, fontWeight: FontWeight.w600),
                  onTyping: (value) => setState(() => _typing = value),
                  onSubmit: (value) => _save((current) => current.copyWith(flightDate: value.trim())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _columns(bool editing, Color body) {
    return Container(
      color: _band,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              flex: _flex(i),
              child: _TypeText(
                fieldKey: Key('flight-col-$i'),
                text: i < os.flightColumns.length
                    ? os.flightColumns[i]
                    : transportColumns(_mode, os.flightHeading)[i],
                editing: editing,
                align: TextAlign.left,
                style: TextStyle(
                  color: body,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
                onTyping: (value) => setState(() => _typing = value),
                onSubmit: (value) => _writeColumn(i, value.trim()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dataRow(int index, List<String> cells, bool editing, Color board, Color body, Color header) {
    final alt = Color.alphaBlend(Colors.black.withValues(alpha: 0.16), board);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: index.isEven ? board : alt,
        border: Border(bottom: BorderSide(color: header.withValues(alpha: 0.28), width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = (constraints.maxHeight * 0.42).clamp(11.0, 20.0);
          return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            for (var column = 0; column < 7; column++)
              Expanded(
                flex: _flex(column),
                child: column == 5
                    ? _StatusTap(
                        fieldKey: Key('flight-cell-$_which-$index-$column'),
                        text: cells[column],
                        editing: editing,
                        color: _statusInk(column, cells[column], body),
                        size: size,
                        onCycle: () => _writeCell(index, column, nextFlightStatus(cells[column])),
                      )
                    : _TypeText(
                  fieldKey: Key('flight-cell-$_which-$index-$column'),
                  text: cells[column],
                  editing: editing,
                  style: TextStyle(
                    color: _statusInk(column, cells[column], body),
                    fontSize: size,
                    fontWeight: FontWeight.w700,
                    letterSpacing: column == 1 ? 0.3 : 0,
                  ),
                  onTyping: (value) => setState(() => _typing = value),
                  onSubmit: (value) => _writeCell(index, column, value.trim()),
                ),
              ),
          ],
        ),
          );
        },
      ),
    );
  }

  int _flex(int column) {
    return const [9, 24, 16, 12, 10, 14, 7][column];
  }

  Color _statusInk(int column, String text, Color body) {
    if (column != 5) return body;
    final upper = text.toUpperCase();
    if (upper.contains('CANCEL')) return _alert;
    if (upper.startsWith('DELAY')) return _yellow;
    return body;
  }
}

class _StatusTap extends StatelessWidget {
  const _StatusTap({
    required this.fieldKey,
    required this.text,
    required this.editing,
    required this.color,
    required this.size,
    required this.onCycle,
  });

  final Key fieldKey;
  final String text;
  final bool editing;
  final Color color;
  final double size;
  final VoidCallback onCycle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: fieldKey,
      behavior: HitTestBehavior.opaque,
      onTap: editing ? onCycle : null,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Moves the edited row so the board stays in time order. Other rows keep
/// their order. A time that cannot be read stays where it is.
List<String> orderedFlightBoard(List<String> rows, int edited) {
  if (edited < 0 || edited >= rows.length) return rows;
  final moving = rows[edited];
  final minutes = _flightMinutes(flightCells(moving).first);
  if (minutes == null) return rows;
  final rest = [...rows]..removeAt(edited);
  var at = rest.length;
  for (var i = 0; i < rest.length; i++) {
    final other = _flightMinutes(flightCells(rest[i]).first);
    if (other == null || other > minutes) {
      at = i;
      break;
    }
  }
  rest.insert(at, moving);
  return rest;
}

int? _flightMinutes(String text) {
  final parsed = parseClockText(text);
  if (parsed == null) return null;
  return parsed.$1 * 60 + parsed.$2;
}

class _TypeText extends StatefulWidget {
  const _TypeText({
    required this.fieldKey,
    required this.text,
    required this.editing,
    required this.style,
    required this.onSubmit,
    required this.onTyping,
    this.align = TextAlign.left,
    this.hug = false,
  });

  final Key fieldKey;
  final String text;
  final bool editing;
  final TextStyle style;
  final TextAlign align;
  final bool hug;
  final ValueChanged<String> onSubmit;
  final ValueChanged<bool> onTyping;

  @override
  State<_TypeText> createState() => _TypeTextState();
}

class _TypeTextState extends State<_TypeText> {
  bool _open = false;
  late final TextEditingController _field;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _field = TextEditingController(text: widget.text);
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus && _open) _close();
    });
  }

  @override
  void didUpdateWidget(covariant _TypeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_open && _field.text != widget.text) _field.text = widget.text;
  }

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _openField() {
    if (!widget.editing) return;
    setState(() => _open = true);
    widget.onTyping(true);
    _field.text = widget.text;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _close() {
    final value = _field.text;
    setState(() => _open = false);
    widget.onTyping(false);
    if (value != widget.text) widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_open) {
      final label = Text(
        widget.text,
        maxLines: 1,
        overflow: widget.hug ? TextOverflow.clip : TextOverflow.ellipsis,
        textAlign: widget.align,
        style: widget.style,
      );
      return GestureDetector(
        key: widget.fieldKey,
        behavior: HitTestBehavior.opaque,
        onTap: widget.editing ? _openField : null,
        child: widget.hug
            ? label
            : Align(
                alignment: switch (widget.align) {
                  TextAlign.right => Alignment.centerRight,
                  TextAlign.center => Alignment.center,
                  _ => Alignment.centerLeft,
                },
                child: label,
              ),
      );
    }
    return TextField(
      key: widget.fieldKey,
      controller: _field,
      focusNode: _focus,
      style: widget.style,
      textAlign: widget.align,
      cursorColor: _yellow,
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      onSubmitted: (_) => _focus.unfocus(),
      inputFormatters: [LengthLimitingTextInputFormatter(48)],
    );
  }
}
