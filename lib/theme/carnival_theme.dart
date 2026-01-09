import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CarnivalTheme {
  // Carnival Colors - Vibrant Brazilian palette
  static const Color purple = Color(0xFF9C27B0);
  static const Color deepPurple = Color(0xFF6A1B9A);
  static const Color pink = Color(0xFFE91E63);
  static const Color orange = Color(0xFFFF9800);
  static const Color yellow = Color(0xFFFFEB3B);
  static const Color green = Color(0xFF4CAF50);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color gold = Color(0xFFFFD700);

  // Background gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6A1B9A), // Deep purple
      Color(0xFF9C27B0), // Purple
      Color(0xFFE91E63), // Pink
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFFF8E1),
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFF9800), // Orange
      Color(0xFFFFEB3B), // Yellow
    ],
  );

  static List<Color> tagColors = [
    const Color(0xFFE91E63), // Pink
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF4CAF50), // Green
    const Color(0xFFFF9800), // Orange
    const Color(0xFFFFEB3B), // Yellow
  ];

  static Color getTagColor(int index) {
    return tagColors[index % tagColors.length];
  }

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: purple,
        brightness: Brightness.light,
        primary: purple,
        secondary: pink,
        tertiary: orange,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.pacifico(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: deepPurple,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: deepPurple,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: deepPurple,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.grey[700],
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.pacifico(
          fontSize: 24,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: purple.withAlpha(77),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: pink,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final List<Offset> positions;
  final List<Color> colors;
  final List<double> sizes;

  ConfettiPainter({
    required this.positions,
    required this.colors,
    required this.sizes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < positions.length; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(
          positions[i].dx * size.width,
          positions[i].dy * size.height,
        ),
        sizes[i % sizes.length],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
