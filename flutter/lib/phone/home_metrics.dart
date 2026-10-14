import 'dart:math' as math;

/// Four columns and six rows, sized so the icons fill the home grid.
class HomeGridMetrics {
  const HomeGridMetrics({
    required this.columns,
    required this.rows,
    required this.cellWidth,
    required this.cellHeight,
    required this.iconSize,
    required this.gap,
  });

  final int columns;
  final int rows;
  final double cellWidth;
  final double cellHeight;
  final double iconSize;
  final double gap;
}

const kHomeIconColumns = 4;
const kHomeIconRows = 6;
const kHomeIconGap = 10.0;

/// Search pill under the icons, plus the gap that keeps it off the dock.
const kHomeSearchFoot = 36.0;
const kHomeSearchLift = 14.0;

/// [width] and [height] are the icon grid itself, not the dock or search.
HomeGridMetrics fillHomeGrid(double width, double height) {
  const columns = kHomeIconColumns;
  const rows = kHomeIconRows;
  const gap = kHomeIconGap;
  final safeW = width.isFinite && width > 40 ? width : 320.0;
  final safeH = height.isFinite && height > 80 ? height : 480.0;
  final cellWidth = safeW / columns;
  final cellHeight = math.max(52.0, safeH / rows - gap);
  final iconSize = math.min(cellWidth - 12, cellHeight - 24).clamp(44.0, 120.0);
  return HomeGridMetrics(
    columns: columns,
    rows: rows,
    cellWidth: cellWidth,
    cellHeight: cellHeight,
    iconSize: iconSize,
    gap: gap,
  );
}

/// Current OS measures the icon grid after the search pill, its lift, and the dock.
HomeGridMetrics homeMetricsForFrame(
  double width,
  double height, {
  double dockChrome = 52,
}) {
  const top = 22.0;
  const pagePad = 4.0;
  var icon = 68.0;
  var metrics = fillHomeGrid(width - 16, height / 2);
  for (var i = 0; i < 3; i++) {
    final dockH = dockChrome + icon;
    final gridH = height - dockH - kHomeSearchFoot - kHomeSearchLift - top - pagePad;
    metrics = fillHomeGrid(math.max(80, width - 16), math.max(160, gridH));
    icon = metrics.iconSize;
  }
  return metrics;
}
