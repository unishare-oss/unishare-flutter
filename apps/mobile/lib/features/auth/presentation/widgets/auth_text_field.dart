import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Web-matched color constants for auth text field.
const _kBorder = Color(0xFFE2DAD0);
const _kFocusBorder = Color(0xFFD97706);
const _kErrorBorder = Color(0xFFDC2626);
const _kFillColor = Color(0xFFFEF3C7);
const _kTextSecondary = Color(0xFF6B6560);
const _kErrorColor = Color(0xFFDC2626);

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.enabled = true,
    this.autofillHints,
    this.suffixIcon,
  });

  final String hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final Widget? suffixIcon;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.spaceGrotesk(
      fontSize: 14,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      enabled: widget.enabled,
      autofillHints: widget.autofillHints,
      style: baseStyle,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: baseStyle.copyWith(color: _kTextSecondary),
        filled: true,
        fillColor: _kFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kFocusBorder, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kErrorBorder, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kErrorBorder, width: 1),
        ),
        errorStyle: GoogleFonts.spaceGrotesk(fontSize: 12, color: _kErrorColor),
        // Fixed 36×36 slot on every field keeps all heights identical.
        suffixIconConstraints: const BoxConstraints.tightFor(width: 36, height: 36),
        suffixIcon:
            widget.suffixIcon ??
            (widget.obscureText
                ? GestureDetector(
                    onTap: () => setState(() => _obscured = !_obscured),
                    child: Icon(
                      _obscured ? Icons.visibility_off : Icons.visibility,
                      color: _kTextSecondary,
                      size: 18,
                    ),
                  )
                : const SizedBox.shrink()),
      ),
    );
  }
}
