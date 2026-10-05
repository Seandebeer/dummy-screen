import 'package:flutter/material.dart';

class VfxColor {
  const VfxColor(this.id, this.name, this.hex, this.label);

  final String id;
  final String name;
  final Color hex;
  final String label;
}

const kVfxPalette = <VfxColor>[
  VfxColor('green', 'Green', Color(0xFF00B140), 'Chroma Green'),
  VfxColor('blue', 'Blue', Color(0xFF0047BB), 'Chroma Blue'),
  VfxColor('grey', 'Grey 18%', Color(0xFF7F7F7F), '18% Grey'),
  VfxColor('white', 'White', Color(0xFFFFFFFF), 'Pure White'),
  VfxColor('black', 'OLED Black', Color(0xFF000000), 'OLED Black'),
];

class TrackStyle {
  const TrackStyle(this.id, this.name, {this.point = true, this.bwOnly = false});

  final String id;
  final String name;
  final bool point;
  final bool bwOnly;
}

const kCompositeIds = [
  'circtriplus',
  'solidtri',
  'squaretri',
  'invtri',
  'plusgrid',
  'dotcircle',
  'quads',
  'squads',
  'crosshair',
];

const kTrackingStyles = <TrackStyle>[
  TrackStyle('none', 'None', point: false),
  TrackStyle('cross', 'Cross'),
  TrackStyle('circles', 'Target'),
  TrackStyle('checkerboard', 'Checker', point: false, bwOnly: true),
  TrackStyle('squares', 'Square'),
  TrackStyle('dots', 'Dots', point: false),
  TrackStyle('brackets', 'Brackets'),
  TrackStyle('triangle', 'Triangle'),
  TrackStyle('circtriplus', 'Tri Circle'),
  TrackStyle('solidtri', 'Solid Tri'),
  TrackStyle('squaretri', 'Square Tri'),
  TrackStyle('invtri', 'Inverse Tri'),
  TrackStyle('plusgrid', 'Plus Grid'),
  TrackStyle('dotcircle', 'Dot Circle'),
  TrackStyle('quads', 'Quadrant'),
  TrackStyle('squads', 'Square Quad'),
  TrackStyle('crosshair', 'Crosshair'),
];

const kMarkerKinds = <TrackStyle>[
  TrackStyle('cross', 'Cross'),
  TrackStyle('circles', 'Targets'),
  TrackStyle('squares', 'Squares'),
  TrackStyle('brackets', 'Brackets'),
  TrackStyle('diamond', 'Diamond'),
  TrackStyle('triangle', 'Triangle'),
  TrackStyle('circtriplus', 'Tri Circle'),
  TrackStyle('solidtri', 'Solid Tri'),
  TrackStyle('squaretri', 'Square Tri'),
  TrackStyle('invtri', 'Inverse Tri'),
  TrackStyle('plusgrid', 'Plus Grid'),
  TrackStyle('dotcircle', 'Dot Circle'),
  TrackStyle('quads', 'Quadrant'),
  TrackStyle('squads', 'Square Quad'),
  TrackStyle('crosshair', 'Crosshair'),
];

const kMarkColors = <Color>[
  Color(0xFFFFFFFF),
  Color(0xFF000000),
  Color(0xFFFF3B30),
  Color(0xFF34C759),
  Color(0xFFFF2D92),
  Color(0xFF32ADE6),
  Color(0xFFFFD60A),
];

class StageMark {
  const StageMark({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    this.rot = 0,
  });

  final String id;
  final String kind;
  final double x;
  final double y;
  final int rot;

  StageMark copyWith({double? x, double? y, int? rot, String? kind}) =>
      StageMark(
        id: id,
        kind: kind ?? this.kind,
        x: x ?? this.x,
        y: y ?? this.y,
        rot: rot ?? this.rot,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'x': x,
    'y': y,
    'rot': rot,
  };

  factory StageMark.fromJson(Map<String, dynamic> json) => StageMark(
    id: json['id'] as String? ?? '',
    kind: json['kind'] as String? ?? 'cross',
    x: (json['x'] as num?)?.toDouble() ?? 50,
    y: (json['y'] as num?)?.toDouble() ?? 50,
    rot: (json['rot'] as num?)?.toInt() ?? 0,
  );
}

bool isPointStyle(String id) =>
    kTrackingStyles.any((style) => style.id == id && style.point);

VfxColor vfxColorById(String id) {
  for (final color in kVfxPalette) {
    if (color.id == id) return color;
  }
  return kVfxPalette.first;
}

List<StageMark> defaultLayoutFor(String style) {
  final corners = [
    StageMark(id: '$style-tl', kind: style, x: 20, y: 12.5),
    StageMark(id: '$style-tr', kind: style, x: 80, y: 12.5),
    StageMark(id: '$style-bl', kind: style, x: 20, y: 87.5),
    StageMark(id: '$style-br', kind: style, x: 80, y: 87.5),
  ];
  if (style == 'squares') return corners;
  return [
    ...corners,
    StageMark(
      id: '$style-c',
      kind: style == 'brackets' ? 'diamond' : style,
      x: 50,
      y: 50,
    ),
  ];
}

double snapCells(double value, int cells) {
  final snapped = ((value / 100) * cells).round() / cells * 100;
  return snapped.clamp(0, 100).toDouble();
}

double snapX(double value) {
  final grid = snapCells(value, 5);
  return (50 - value).abs() < (grid - value).abs() ? 50 : grid;
}

/// Button-gap lines for the 5×8 marker grid, matching `snapLines` in UIMarkersApp.
/// [width] and [height] are the full stage, including the 4px page padding.
({List<double> xs, List<double> ys}) markerSnapLines(double width, double height) {
  const pad = 4.0;
  const gap = 4.0;
  const cols = 6;
  const rows = 9;
  final tileW = (width - 2 * pad - (cols - 1) * gap) / cols;
  final tileH = (height - 2 * pad - (rows - 1) * gap) / rows;
  return (
    xs: [
      for (var i = 0; i < cols - 1; i++) pad + i * (tileW + gap) + tileW + gap / 2,
      width / 2,
    ],
    ys: [
      for (var i = 0; i < rows - 1; i++) pad + i * (tileH + gap) + tileH + gap / 2,
    ],
  );
}

double nearestLine(double value, List<double> lines) {
  var best = lines.first;
  for (final line in lines) {
    if ((line - value).abs() < (best - value).abs()) best = line;
  }
  return best;
}

/// Snap a stage coordinate onto the nearest gap line, as a 2–98 percent.
double snapMarkerPercent(double local, double extent, List<double> lines) {
  if (extent <= 0 || lines.isEmpty) return 50;
  final snapped = nearestLine(local, lines);
  final percent = snapped / extent * 100;
  if (percent < 2) return 2;
  if (percent > 98) return 98;
  return percent;
}

bool lightHex(Color color) {
  final luma = color.r * 0.299 + color.g * 0.587 + color.b * 0.114;
  return luma > 150 / 255;
}

Color parseHex(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  var raw = hex.replaceFirst('#', '');
  if (raw.length == 6) raw = 'FF$raw';
  final value = int.tryParse(raw, radix: 16);
  if (value == null) return fallback;
  return Color(value);
}

String hexOf(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
