import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

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
    final colors = Theme.of(context).extension<AppColors>()!;
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
        hintStyle: baseStyle.copyWith(color: colors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        isDense: true,
        errorStyle: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          color: Theme.of(context).colorScheme.error,
        ),
        // Fixed 36×36 slot on every field keeps all heights identical.
        suffixIconConstraints: const BoxConstraints.tightFor(width: 36, height: 36),
        suffixIcon:
            widget.suffixIcon ??
            (widget.obscureText
                ? GestureDetector(
                    onTap: () => setState(() => _obscured = !_obscured),
                    child: Icon(
                      _obscured ? Icons.visibility_off : Icons.visibility,
                      color: colors.textSecondary,
                      size: 18,
                    ),
                  )
                : const SizedBox.shrink()),
      ),
    );
  }
}
