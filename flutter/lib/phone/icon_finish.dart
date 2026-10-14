import 'package:flutter/material.dart';

/// Light along the top and left edges of a flat app icon, with a darker
/// lower edge. The centre stays clear so the glyph is unchanged.
Decoration edgeLightRim({double radius = 12, bool circular = false}) {
  return BoxDecoration(
    shape: circular ? BoxShape.circle : BoxShape.rectangle,
    borderRadius: circular ? null : BorderRadius.circular(radius),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xB3FFFFFF),
        Color(0x00FFFFFF),
        Color(0x00000000),
        Color(0x47000000),
      ],
      stops: [0.0, 0.2, 0.58, 1.0],
    ),
    border: Border.all(color: const Color(0x8CFFFFFF), width: 1.05),
  );
}
