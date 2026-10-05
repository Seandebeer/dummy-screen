/// In and out points for the video editor, matching `onTrim` in VideoPlayer.jsx.
/// Times are milliseconds. The kept section is at least half a second, or half
/// the clip when the clip itself is shorter than that.
({int start, int end}) moveTrim({
  required bool startEdge,
  required int at,
  required int start,
  required int end,
  required int duration,
}) {
  final length = duration < 0 ? 0 : duration;
  if (length == 0) return (start: 0, end: 0);
  final half = length ~/ 2;
  final gap = length < 500 ? (half < 1 ? 1 : half) : 500;
  final safeEnd = end <= 0 || end > length ? length : end;
  final startCap = safeEnd - gap < 0 ? 0 : safeEnd - gap;
  final safeStart = start < 0 ? 0 : (start > startCap ? startCap : start);
  if (startEdge) {
    final next = at < 0 ? 0 : (at > startCap ? startCap : at);
    return (start: next, end: safeEnd);
  }
  final endFloor = safeStart + gap;
  final next = at < endFloor ? endFloor : (at > length ? length : at);
  return (start: safeStart, end: next);
}

/// Scrub position, kept inside the trimmed section.
int clampSeek(int at, int start, int end) {
  final hi = end <= start ? start : end;
  if (at < start) return start;
  if (at > hi) return hi;
  return at;
}
