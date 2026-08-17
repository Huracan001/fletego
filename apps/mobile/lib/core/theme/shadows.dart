import 'package:flutter/material.dart';

import 'colors.dart';

abstract final class FletegoShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0F0B1220), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x140B1220), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static List<BoxShadow> get card => [
    BoxShadow(
      color: FletegoColors.navy.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
