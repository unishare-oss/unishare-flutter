import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class UnishareLogo extends StatelessWidget {
  const UnishareLogo({super.key, this.iconSize = 40, this.fontSize = 20, this.darkText = true});

  final double iconSize;
  final double fontSize;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          clipBehavior: Clip.antiAlias,
          child: SvgPicture.asset(
            'assets/icon.svg',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Unishare',
          style: GoogleFonts.spaceGrotesk(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: darkText ? const Color(0xFF1C1917) : const Color(0xFFF7F3EE),
          ),
        ),
      ],
    );
  }
}
