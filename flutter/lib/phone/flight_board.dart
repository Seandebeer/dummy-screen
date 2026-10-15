import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';

const _board = Color(0xFF0A3C8C);
const _band = Color(0xFF0E4EAE);
const _line = Color(0xFF1A5EC4);
const _yellow = Color(0xFFFFD400);
const _ink = Colors.white;

/// Airport departures board. Every word on the glass can be typed in OS edit.
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

  List<String> get _rows => _which == 0 ? os.flightA : os.flightB;

  void _writeCell(int row, int column, String value) {
    final source = [..._rows];
    while (source.length <= row) {
      source.add(flightRow(const ['', '', '', '', '', '', '']));
    }
    final cells = flightCells(source[row]);
    cells[column] = value;
    source[row] = flightRow(cells);
    final placed = column == 0 ? orderedFlightBoard(source, row) : source;
    _save((current) => _which == 0 ? current.copyWith(flightA: placed) : current.copyWith(flightB: placed));
  }

  void _writeColumn(int column, String value) {
    final columns = [
      for (var i = 0; i < 7; i++)
        i < os.flightColumns.length ? os.flightColumns[i] : kFlightColumns[i],
    ];
    columns[column] = value;
    _save((current) => current.copyWith(flightColumns: columns));
  }

  @override
  Widget build(BuildContext context) {
    final editing = !widget.store.filming;
    final heading = os.flightHeading == 'none' ? '' : _title;
    final rows = _rows;
    return ColoredBox(
      color: _board,
      child: Column(
        children: [
          if (heading.isNotEmpty) _mast(editing, heading),
          _columns(editing),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final count = rows.isEmpty ? 1 : rows.length;
                final room = constraints.maxHeight / count;
                final height = room > 32 ? 32.0 : room;
                return Column(
                  children: [
                    for (var i = 0; i < rows.length; i++)
                      SizedBox(
                        height: height,
                        child: _dataRow(i, flightCells(rows[i]), editing),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String get _title {
    final typed = os.flightTitle.trim();
    if (typed.isNotEmpty) return typed;
    return os.flightHeading == 'arrivals' ? 'Arrivals' : 'Departures';
  }

  Widget _mast(bool editing, String heading) {
    final now = osNow(os);
    final clock = formatOsClock(now, hour24: true);
    return Container(
      height: 118,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _yellow, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 188,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: _yellow, width: 2),
                ),
                child: const Icon(Icons.flight_takeoff, color: _yellow, size: 32),
              ),
            ),
          ),
          Expanded(
            child: _TypeText(
              fieldKey: const Key('flight-heading'),
              text: heading,
              editing: editing,
              align: TextAlign.center,
              style: const TextStyle(
                color: _yellow,
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
                  style: const TextStyle(
                    color: _yellow,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    fontFeatures: [FontFeature.tabularFigures()],
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
                  style: const TextStyle(color: _yellow, fontSize: 14, fontWeight: FontWeight.w600),
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

  Widget _columns(bool editing) {
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
                text: i < os.flightColumns.length ? os.flightColumns[i] : kFlightColumns[i],
                editing: editing,
                align: TextAlign.left,
                style: const TextStyle(
                  color: _ink,
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

  Widget _dataRow(int index, List<String> cells, bool editing) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: index.isEven ? _board : const Color(0xFF08357C),
        border: const Border(bottom: BorderSide(color: _line, width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = (constraints.maxHeight * 0.46).clamp(8.0, 13.0);
          return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            for (var column = 0; column < 7; column++)
              Expanded(
                flex: _flex(column),
                child: _TypeText(
                  fieldKey: Key('flight-cell-$_which-$index-$column'),
                  text: cells[column],
                  editing: editing,
                  style: TextStyle(
                    color: _statusInk(column, cells[column]),
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

  Color _statusInk(int column, String text) {
    if (column == 5 && text.toUpperCase().contains('CANCEL')) return _yellow;
    return _ink;
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
  });

  final Key fieldKey;
  final String text;
  final bool editing;
  final TextStyle style;
  final TextAlign align;
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
      return GestureDetector(
        key: widget.fieldKey,
        behavior: HitTestBehavior.opaque,
        onTap: widget.editing ? _openField : null,
        child: Align(
          alignment: switch (widget.align) {
            TextAlign.right => Alignment.centerRight,
            TextAlign.center => Alignment.center,
            _ => Alignment.centerLeft,
          },
          child: Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: widget.align,
            style: widget.style,
          ),
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
