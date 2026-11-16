import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum NovellyThemeMode { paperCream, midnightInk }

class NovellyThemeData {
  const NovellyThemeData({
    required this.name,
    required this.mode,
    required this.paperColor,
    required this.cardColor,
    required this.inkColor,
    required this.deepInkColor,
    required this.accentGold,
    required this.mutedColor,
    required this.lineColor,
    required this.gradientColors,
    required this.isDark,
  });

  final String name;
  final NovellyThemeMode mode;
  final Color paperColor;
  final Color cardColor;
  final Color inkColor;
  final Color deepInkColor;
  final Color accentGold;
  final Color mutedColor;
  final Color lineColor;
  final List<Color> gradientColors;
  final bool isDark;

  static const NovellyThemeData paperCream = NovellyThemeData(
    name: 'Paper Cream 📜',
    mode: NovellyThemeMode.paperCream,
    paperColor: Color(0xFFFAF7F2),
    cardColor: Color(0xFFFFFFFF),
    inkColor: Color(0xFF173B43),
    deepInkColor: Color(0xFF12343B),
    accentGold: Color(0xFFC89543),
    mutedColor: Color(0xFF6E787A),
    lineColor: Color(0x1F173B43),
    gradientColors: [Color(0xFFFDFCF9), Color(0xFFFAF7F2), Color(0xFFF5EFE6)],
    isDark: false,
  );

  static const NovellyThemeData midnightInk = NovellyThemeData(
    name: 'Midnight Ink 🌙',
    mode: NovellyThemeMode.midnightInk,
    paperColor: Color(0xFF0D1F23),
    cardColor: Color(0xFF132A30),
    inkColor: Color(0xFFE2F1F3),
    deepInkColor: Color(0xFF67B0BD),
    accentGold: Color(0xFFE5AE4D),
    mutedColor: Color(0xFF8BA5AB),
    lineColor: Color(0xFF23444C),
    gradientColors: [Color(0xFF091619), Color(0xFF0D1F23), Color(0xFF132A30)],
    isDark: true,
  );
}

class NovellyThemeController extends ValueNotifier<NovellyThemeData> {
  NovellyThemeController._() : super(NovellyThemeData.paperCream);

  static final NovellyThemeController instance = NovellyThemeController._();

  void setTheme(NovellyThemeMode mode) {
    HapticFeedback.mediumImpact();
    switch (mode) {
      case NovellyThemeMode.paperCream:
        value = NovellyThemeData.paperCream;
        break;
      case NovellyThemeMode.midnightInk:
        value = NovellyThemeData.midnightInk;
        break;
    }
  }

  void cycleTheme() {
    switch (value.mode) {
      case NovellyThemeMode.paperCream:
        setTheme(NovellyThemeMode.midnightInk);
        break;
      case NovellyThemeMode.midnightInk:
        setTheme(NovellyThemeMode.paperCream);
        break;
    }
  }
}
