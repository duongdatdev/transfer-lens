import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/transaction.dart';

class AppTheme {
  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF176B58),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF5F7F4)
          : const Color(0xFF101A17),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -.5,
        ),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(fontSize: 14, height: 1.4),
      ),
    );
  }

  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);
}

Color categoryColor(ExpenseCategory category) => switch (category) {
  ExpenseCategory.food => const Color(0xFF1F8A70),
  ExpenseCategory.study => const Color(0xFF5278C5),
  ExpenseCategory.travel => const Color(0xFFB97825),
  ExpenseCategory.gear => const Color(0xFF9971B7),
  ExpenseCategory.entertainment => const Color(0xFFD16B71),
  ExpenseCategory.other => const Color(0xFF7D8A87),
};

IconData categoryIcon(ExpenseCategory category) => switch (category) {
  ExpenseCategory.food => Icons.restaurant_outlined,
  ExpenseCategory.study => Icons.menu_book_outlined,
  ExpenseCategory.travel => Icons.directions_bus_outlined,
  ExpenseCategory.gear => Icons.shopping_bag_outlined,
  ExpenseCategory.entertainment => Icons.movie_outlined,
  ExpenseCategory.other => Icons.category_outlined,
};

class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 920),
      child: child,
    ),
  );
}
