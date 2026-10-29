import 'package:flutter/material.dart';

/// The 12×12 pixel helmet (assets/brand/icon-small.svg), drawn crisp at any
/// size. Used where the 24×24 app icon would blur: the rail header and the
/// favicon.
class PixelHelmet extends StatelessWidget {
  const PixelHelmet({super.key, this.size = 32});
  final double size;

  static const grid = [
    '.....##.....',
    '....#Yo#....',
    '...#oYYo#...',
    '..#oYooYo#..',
    '.#oooooooo#.',
    '#o9EE99EE9o#',
    '#o99E99E99o#',
    '.#oooooooo#.',
    '.#ooo##ooo#.',
    '..#oooooo#..',
    '...#oooo#...',
    '....####....',
  ];

  static const colors = {
    '#': Color(0xFF2A1A05),
    'Y': Color(0xFFF7E08A),
    'o': Color(0xFFE2B13C),
    '9': Color(0xFF9C6A14),
    'E': Color(0xFFE63946),
  };

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _HelmetPainter()),
  );
}

class _HelmetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Whole pixels only, so the edges stay sharp.
    final cell = (size.width / 12).floorToDouble().clamp(1.0, double.infinity);
    final offset = (size.width - cell * 12) / 2;
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < 12; y++) {
      final row = PixelHelmet.grid[y];
      for (var x = 0; x < 12; x++) {
        final c = PixelHelmet.colors[row[x]];
        if (c == null) continue;
        paint.color = c;
        canvas.drawRect(Rect.fromLTWH(offset + x * cell, offset + y * cell, cell, cell), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
