import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme textTheme(Color color) =>
      GoogleFonts.spaceGroteskTextTheme().apply(
        bodyColor: color,
        displayColor: color,
      );

  static TextStyle mono({TextStyle? base}) =>
      GoogleFonts.firaCode(textStyle: base);
}
