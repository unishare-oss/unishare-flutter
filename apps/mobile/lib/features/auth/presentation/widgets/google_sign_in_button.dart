import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Web-matched color constants for auth buttons.
const _kBorder = Color(0xFFE2DAD0);
const _kCardBg = Color(0xFFFFFFFF);
const _kForeground = Color(0xFF1C1917);

// ---------------------------------------------------------------------------
// Google logo painter
// ---------------------------------------------------------------------------

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Scale from 24×24 viewBox to the target size.
    final sx = size.width / 24.0;
    final sy = size.height / 24.0;
    canvas.scale(sx, sy);

    final paint = Paint()..style = PaintingStyle.fill;

    // Blue path
    paint.color = const Color(0xFF4285F4);
    final blue = Path()
      ..moveTo(22.56, 12.25)
      ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.26)
      ..lineTo(17.92, 14.26)
      ..cubicTo(17.65, 15.63, 16.89, 16.79, 15.72, 17.58)
      ..lineTo(15.72, 20.35)
      ..lineTo(19.29, 20.35)
      ..cubicTo(21.37, 18.43, 22.56, 15.61, 22.56, 12.25)
      ..close();
    canvas.drawPath(blue, paint);

    // Green path
    paint.color = const Color(0xFF34A853);
    final green = Path()
      ..moveTo(12.0, 23.0)
      ..cubicTo(14.97, 23.0, 17.46, 22.02, 19.28, 20.34)
      ..lineTo(15.71, 17.57)
      ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.0, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.70, 5.84, 14.10)
      ..lineTo(2.18, 14.10)
      ..lineTo(2.18, 16.94)
      ..cubicTo(3.99, 20.53, 7.70, 23.0, 12.0, 23.0)
      ..close();
    canvas.drawPath(green, paint);

    // Yellow path
    paint.color = const Color(0xFFFBBC05);
    final yellow = Path()
      ..moveTo(5.84, 14.09)
      ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.0)
      ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
      ..lineTo(5.84, 7.07)
      ..lineTo(2.18, 7.07)
      ..cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0)
      ..cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.93)
      ..lineTo(5.03, 14.71)
      ..lineTo(5.84, 14.09)
      ..close();
    canvas.drawPath(yellow, paint);

    // Red path
    paint.color = const Color(0xFFEA4335);
    final red = Path()
      ..moveTo(12.0, 5.38)
      ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
      ..lineTo(19.36, 3.87)
      ..cubicTo(17.45, 2.09, 14.97, 1.0, 12.0, 1.0)
      ..cubicTo(7.70, 1.0, 3.99, 3.47, 2.18, 7.07)
      ..lineTo(5.84, 9.91)
      ..cubicTo(6.71, 7.31, 9.14, 5.38, 12.0, 5.38)
      ..close();
    canvas.drawPath(red, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Microsoft logo painter
// ---------------------------------------------------------------------------

class _MicrosoftLogoPainter extends CustomPainter {
  const _MicrosoftLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Scale from 21×21 viewBox to the target size.
    final sx = size.width / 21.0;
    final sy = size.height / 21.0;
    canvas.scale(sx, sy);

    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFF25022);
    canvas.drawRect(const Rect.fromLTWH(1, 1, 9, 9), paint);

    paint.color = const Color(0xFF7FBA00);
    canvas.drawRect(const Rect.fromLTWH(11, 1, 9, 9), paint);

    paint.color = const Color(0xFF00A4EF);
    canvas.drawRect(const Rect.fromLTWH(1, 11, 9, 9), paint);

    paint.color = const Color(0xFFFFB900);
    canvas.drawRect(const Rect.fromLTWH(11, 11, 9, 9), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Shared button style helper
// ---------------------------------------------------------------------------

ButtonStyle _oauthButtonStyle() {
  return OutlinedButton.styleFrom(
    backgroundColor: _kCardBg,
    side: const BorderSide(color: _kBorder, width: 1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    minimumSize: const Size.fromHeight(42),
    padding: EdgeInsets.zero,
  );
}

// ---------------------------------------------------------------------------
// GoogleSignInButton
// ---------------------------------------------------------------------------

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: _oauthButtonStyle(),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kForeground,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomPaint(painter: _GoogleLogoPainter()),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: _kForeground,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MicrosoftSignInButton
// ---------------------------------------------------------------------------

class MicrosoftSignInButton extends StatelessWidget {
  const MicrosoftSignInButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton(
        onPressed: onPressed,
        style: _oauthButtonStyle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(painter: _MicrosoftLogoPainter()),
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Microsoft',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: _kForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
