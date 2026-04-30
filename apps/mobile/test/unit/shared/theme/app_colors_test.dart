import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

const _sample = AppColors(
  muted: Color(0xFFF7F3EE),
  mutedForeground: Color(0xFF6B6560),
  textSecondary: Color(0xFF6B6560),
  textMuted: Color(0xFF8A837E),
  amber: Color(0xFFD97706),
  amberHover: Color(0xFFB45309),
  amberSubtle: Color(0xFFFEF3C7),
  success: Color(0xFF16A34A),
  info: Color(0xFF0369A1),
  surfaceDark: Color(0xFF1C1917),
  cardDark: Color(0xFFF0EBE4),
);

void main() {
  group('AppColors', () {
    test('copyWith overrides only specified fields', () {
      final copy = _sample.copyWith(amber: const Color(0xFF000000));
      expect(copy.amber, const Color(0xFF000000));
      expect(copy.success, _sample.success);
    });

    test('copyWith with no args returns equal instance', () {
      final copy = _sample.copyWith();
      expect(copy.amber, _sample.amber);
    });

    test('lerp at t=0 returns this', () {
      final other = _sample.copyWith(amber: const Color(0xFF000000));
      final result = _sample.lerp(other, 0.0);
      expect(result.amber, _sample.amber);
    });

    test('lerp at t=1 returns other', () {
      final other = _sample.copyWith(amber: const Color(0xFF000000));
      final result = _sample.lerp(other, 1.0);
      expect(result.amber, const Color(0xFF000000));
    });

    test('lerp with null other returns this', () {
      final result = _sample.lerp(null, 0.5);
      expect(result.amber, _sample.amber);
    });
  });
}
