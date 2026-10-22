import 'package:flutter/material.dart';

/// 业务状态扩展色板
@immutable
class AnimeThemeColors extends ThemeExtension<AnimeThemeColors> {
  final Color wantToWatch;
  final Color watching;
  final Color watched;
  final Color onHold;
  final Color dropped;

  const AnimeThemeColors({
    required this.wantToWatch,
    required this.watching,
    required this.watched,
    required this.onHold,
    required this.dropped,
  });

  static const light = AnimeThemeColors(
    wantToWatch: Color(0xFF3B82F6), // 想看: 蓝
    watching: Color(0xFF10B981),    // 在看: 绿
    watched: Color(0xFFF59E0B),     // 看过: 琥珀橙
    onHold: Color(0xFF8A94A6),      // 搁置: 蓝灰
    dropped: Color(0xFFEF4444),     // 抛弃: 红
  );

  static const dark = AnimeThemeColors(
    wantToWatch: Color(0xFF60A5FA),
    watching: Color(0xFF34D399),
    watched: Color(0xFFFBBF24),
    onHold: Color(0xFF9AA4B8),
    dropped: Color(0xFFF87171),
  );

  @override
  AnimeThemeColors copyWith({
    Color? wantToWatch,
    Color? watching,
    Color? watched,
    Color? onHold,
    Color? dropped,
  }) {
    return AnimeThemeColors(
      wantToWatch: wantToWatch ?? this.wantToWatch,
      watching: watching ?? this.watching,
      watched: watched ?? this.watched,
      onHold: onHold ?? this.onHold,
      dropped: dropped ?? this.dropped,
    );
  }

  @override
  AnimeThemeColors lerp(ThemeExtension<AnimeThemeColors>? other, double t) {
    if (other is! AnimeThemeColors) return this;
    return AnimeThemeColors(
      wantToWatch: Color.lerp(wantToWatch, other.wantToWatch, t)!,
      watching: Color.lerp(watching, other.watching, t)!,
      watched: Color.lerp(watched, other.watched, t)!,
      onHold: Color.lerp(onHold, other.onHold, t)!,
      dropped: Color.lerp(dropped, other.dropped, t)!,
    );
  }
}

/// 日系美学应用主题设计（严格对齐 AGENTS.md：日系蔷薇粉 #EC5F7A，亮色 #FAFAF9，暗色 #18181B / #27272A）
class AppTheme {
  // 浅色主要色板
  static const Color primaryLight = Color(0xFFEC5F7A);
  static const Color primaryDeepLight = Color(0xFFD8455F);
  static const Color primarySoftLight = Color(0xFFFFD9DF);
  static const Color bgLight = Color(0xFFFAFAF9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surface2Light = Color(0xFFF4F4F5);
  static const Color borderLight = Color(0xFFE4E4E7);
  static const Color textMainLight = Color(0xFF18181B);
  static const Color textSubLight = Color(0xFF52525B);
  static const Color textMutedLight = Color(0xFF71717A);

  // 深色主要色板
  static const Color primaryDark = Color(0xFFF2738B);
  static const Color primaryDeepDark = Color(0xFFF597AA);
  static const Color primarySoftDark = Color(0xFF3F1F27);
  static const Color bgDark = Color(0xFF18181B);
  static const Color surfaceDark = Color(0xFF27272A);
  static const Color surface2Dark = Color(0xFF323238);
  static const Color borderDark = Color(0xFF3F3F46);
  static const Color textMainDark = Color(0xFFF4F4F5);
  static const Color textSubDark = Color(0xFFA1A1AA);
  static const Color textMutedDark = Color(0xFF71717A);

  // 通用功能与状态色彩
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color infoBlue = Color(0xFF3B82F6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: bgLight,
      extensions: const [AnimeThemeColors.light],
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        onPrimary: Colors.white,
        primaryContainer: primarySoftLight,
        onPrimaryContainer: primaryDeepLight,
        surface: surfaceLight,
        onSurface: textMainLight,
        outline: borderLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        foregroundColor: textMainLight,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLight,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2Light,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryLight, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMainLight,
          side: const BorderSide(color: borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: bgDark,
      extensions: const [AnimeThemeColors.dark],
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        onPrimary: Colors.white,
        primaryContainer: primarySoftDark,
        onPrimaryContainer: primaryDeepDark,
        surface: surfaceDark,
        onSurface: textMainDark,
        outline: borderDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textMainDark,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2Dark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryDark, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMainDark,
          side: const BorderSide(color: borderDark),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
    );
  }
}
