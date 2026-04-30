# Design System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the full Unishare design system in Flutter — 12 themes with color tokens, Space Grotesk + Fira Code typography, a Riverpod theme notifier, and Hive persistence — so every screen shares a consistent, switchable visual identity.

**Architecture:** `AppThemeData` holds raw color tokens per theme; `AppTheme.build()` converts them to `ThemeData` with a `ColorScheme` and `AppColors` extension; `ThemeNotifier` (Riverpod + Hive) persists and exposes the selected theme ID; `MaterialApp` watches `activeThemeProvider`.

**Tech Stack:** `flutter_riverpod` + `riverpod_generator`, `hive_flutter`, `google_fonts`, Flutter Material 3 `ColorScheme`, `ThemeExtension`

All Flutter commands run from `apps/mobile/`.

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| Add dep | `apps/mobile/pubspec.yaml` | Add `google_fonts` |
| Create | `lib/shared/theme/app_theme_data.dart` | Immutable color token struct |
| Create | `lib/shared/theme/app_colors.dart` | `ThemeExtension<AppColors>` |
| Create | `lib/shared/theme/app_typography.dart` | Space Grotesk + Fira Code helpers |
| Create | `lib/shared/theme/themes.dart` | All 12 `AppThemeData` instances + registry map |
| Modify | `lib/shared/theme/app_theme.dart` | Replace seed-color builder with token-based builder |
| Modify | `lib/main.dart` | Init Hive, watch `activeThemeProvider` |
| Create | `lib/shared/theme/providers/theme_provider.dart` | `ThemeNotifier` + `activeThemeProvider` |
| Create | `lib/shared/theme/providers/theme_provider.g.dart` | Generated — do not edit |
| Create | `test/unit/shared/theme/app_colors_test.dart` | AppColors copyWith / lerp |
| Create | `test/unit/shared/theme/app_theme_test.dart` | AppTheme.fromId brightness + extension |
| Create | `test/unit/shared/theme/theme_provider_test.dart` | ThemeNotifier state + Hive persistence |

---

## Task 1: Add google_fonts dependency

**Files:**
- Modify: `apps/mobile/pubspec.yaml`

- [ ] **Step 1: Add dependency**

In `pubspec.yaml`, under `dependencies:`, add after `json_annotation`:

```yaml
  google_fonts: ^6.2.1
```

- [ ] **Step 2: Install**

```bash
flutter pub get
```

Expected: resolves without errors, `google_fonts` appears in `pubspec.lock`.

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/pubspec.yaml apps/mobile/pubspec.lock
git commit -m "chore: add google_fonts dependency"
```

---

## Task 2: AppThemeData — color token struct

**Files:**
- Create: `apps/mobile/lib/shared/theme/app_theme_data.dart`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';

@immutable
class AppThemeData {
  const AppThemeData({
    required this.id,
    required this.name,
    required this.brightness,
    required this.background,
    required this.foreground,
    required this.card,
    required this.primary,
    required this.primaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.textSecondary,
    required this.textMuted,
    required this.amber,
    required this.amberHover,
    required this.amberSubtle,
    required this.success,
    required this.info,
    required this.surfaceDark,
    required this.cardDark,
  });

  final String id;
  final String name;
  final Brightness brightness;
  final Color background;
  final Color foreground;
  final Color card;
  final Color primary;
  final Color primaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color textSecondary;
  final Color textMuted;
  final Color amber;
  final Color amberHover;
  final Color amberSubtle;
  final Color success;
  final Color info;
  final Color surfaceDark;
  final Color cardDark;
}
```

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/shared/theme/app_theme_data.dart
git commit -m "feat: add AppThemeData color token struct"
```

---

## Task 3: AppColors ThemeExtension (TDD)

**Files:**
- Create: `apps/mobile/lib/shared/theme/app_colors.dart`
- Create: `apps/mobile/test/unit/shared/theme/app_colors_test.dart`

- [ ] **Step 1: Write the failing test**

`test/unit/shared/theme/app_colors_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

const _sample = AppColors(
  border: Color(0xFFE2DAD0),
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
      expect(copy.border, _sample.border);
      expect(copy.success, _sample.success);
    });

    test('copyWith with no args returns equal instance', () {
      final copy = _sample.copyWith();
      expect(copy.amber, _sample.amber);
      expect(copy.border, _sample.border);
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
```

- [ ] **Step 2: Run to confirm it fails**

```bash
flutter test test/unit/shared/theme/app_colors_test.dart
```

Expected: compilation error — `app_colors.dart` does not exist yet.

- [ ] **Step 3: Implement AppColors**

`lib/shared/theme/app_colors.dart`:

```dart
import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.border,
    required this.muted,
    required this.mutedForeground,
    required this.textSecondary,
    required this.textMuted,
    required this.amber,
    required this.amberHover,
    required this.amberSubtle,
    required this.success,
    required this.info,
    required this.surfaceDark,
    required this.cardDark,
  });

  final Color border;
  final Color muted;
  final Color mutedForeground;
  final Color textSecondary;
  final Color textMuted;
  final Color amber;
  final Color amberHover;
  final Color amberSubtle;
  final Color success;
  final Color info;
  final Color surfaceDark;
  final Color cardDark;

  @override
  AppColors copyWith({
    Color? border,
    Color? muted,
    Color? mutedForeground,
    Color? textSecondary,
    Color? textMuted,
    Color? amber,
    Color? amberHover,
    Color? amberSubtle,
    Color? success,
    Color? info,
    Color? surfaceDark,
    Color? cardDark,
  }) {
    return AppColors(
      border: border ?? this.border,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      amber: amber ?? this.amber,
      amberHover: amberHover ?? this.amberHover,
      amberSubtle: amberSubtle ?? this.amberSubtle,
      success: success ?? this.success,
      info: info ?? this.info,
      surfaceDark: surfaceDark ?? this.surfaceDark,
      cardDark: cardDark ?? this.cardDark,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberHover: Color.lerp(amberHover, other.amberHover, t)!,
      amberSubtle: Color.lerp(amberSubtle, other.amberSubtle, t)!,
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
      surfaceDark: Color.lerp(surfaceDark, other.surfaceDark, t)!,
      cardDark: Color.lerp(cardDark, other.cardDark, t)!,
    );
  }
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
flutter test test/unit/shared/theme/app_colors_test.dart
```

Expected: All 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/shared/theme/app_colors.dart apps/mobile/test/unit/shared/theme/app_colors_test.dart
git commit -m "feat: add AppColors ThemeExtension"
```

---

## Task 4: AppTypography

**Files:**
- Create: `apps/mobile/lib/shared/theme/app_typography.dart`

- [ ] **Step 1: Create the file**

```dart
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
```

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/shared/theme/app_typography.dart
git commit -m "feat: add AppTypography with Space Grotesk and Fira Code"
```

---

## Task 5: All 12 theme definitions

**Files:**
- Create: `apps/mobile/lib/shared/theme/themes.dart`

- [ ] **Step 1: Create themes.dart with all 12 AppThemeData instances**

```dart
import 'package:flutter/material.dart';
import 'app_theme_data.dart';

class AppThemes {
  static const unishare = AppThemeData(
    id: 'unishare',
    name: 'UniShare',
    brightness: Brightness.light,
    background: Color(0xFFF7F3EE),
    foreground: Color(0xFF1C1917),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFFD97706),
    primaryForeground: Color(0xFFFFFFFF),
    muted: Color(0xFFF7F3EE),
    mutedForeground: Color(0xFF6B6560),
    accent: Color(0xFFFEF3C7),
    accentForeground: Color(0xFFD97706),
    destructive: Color(0xFFDC2626),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFFE2DAD0),
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

  static const catppuccinMocha = AppThemeData(
    id: 'catppuccin-mocha',
    name: 'Catppuccin Mocha',
    brightness: Brightness.dark,
    background: Color(0xFF1E1E2E),
    foreground: Color(0xFFCDD6F4),
    card: Color(0xFF181825),
    primary: Color(0xFFFAB387),
    primaryForeground: Color(0xFF1E1E2E),
    muted: Color(0xFF313244),
    mutedForeground: Color(0xFF9399B2),
    accent: Color(0xFF45475A),
    accentForeground: Color(0xFFFAB387),
    destructive: Color(0xFFF38BA8),
    destructiveForeground: Color(0xFF1E1E2E),
    border: Color(0xFF45475A),
    textSecondary: Color(0xFFA6ADC8),
    textMuted: Color(0xFF9399B2),
    amber: Color(0xFFFAB387),
    amberHover: Color(0xFFE8956D),
    amberSubtle: Color(0xFF3D2520),
    success: Color(0xFFA6E3A1),
    info: Color(0xFF89B4FA),
    surfaceDark: Color(0xFF11111B),
    cardDark: Color(0xFF11111B),
  );

  static const catppuccinLatte = AppThemeData(
    id: 'catppuccin-latte',
    name: 'Catppuccin Latte',
    brightness: Brightness.light,
    background: Color(0xFFEFF1F5),
    foreground: Color(0xFF4C4F69),
    card: Color(0xFFE6E9EF),
    primary: Color(0xFFFE640B),
    primaryForeground: Color(0xFFFFFFFF),
    muted: Color(0xFFDCE0E8),
    mutedForeground: Color(0xFF737591),
    accent: Color(0xFFCCD0DA),
    accentForeground: Color(0xFFFE640B),
    destructive: Color(0xFFD20F39),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFFCCD0DA),
    textSecondary: Color(0xFF6C6F85),
    textMuted: Color(0xFF737591),
    amber: Color(0xFFFE640B),
    amberHover: Color(0xFFE05A0A),
    amberSubtle: Color(0xFFFDE8D8),
    success: Color(0xFF40A02B),
    info: Color(0xFF1E66F5),
    surfaceDark: Color(0xFFBCC0CC),
    cardDark: Color(0xFFDCE0E8),
  );

  static const nord = AppThemeData(
    id: 'nord',
    name: 'Nord',
    brightness: Brightness.dark,
    background: Color(0xFF2E3440),
    foreground: Color(0xFFF8FAFC),
    card: Color(0xFF3B4252),
    primary: Color(0xFF88C0D0),
    primaryForeground: Color(0xFF2E3440),
    muted: Color(0xFF434C5E),
    mutedForeground: Color(0xFFA0AFC8),
    accent: Color(0xFF4C566A),
    accentForeground: Color(0xFF88C0D0),
    destructive: Color(0xFFBF616A),
    destructiveForeground: Color(0xFFECEFF4),
    border: Color(0xFF4C566A),
    textSecondary: Color(0xFFE8EDF5),
    textMuted: Color(0xFFA0AFC8),
    amber: Color(0xFF88C0D0),
    amberHover: Color(0xFF6AACBF),
    amberSubtle: Color(0xFF3B4A5A),
    success: Color(0xFFA3BE8C),
    info: Color(0xFF81A1C1),
    surfaceDark: Color(0xFF242932),
    cardDark: Color(0xFF242932),
  );

  static const arctic = AppThemeData(
    id: 'arctic',
    name: 'Arctic',
    brightness: Brightness.light,
    background: Color(0xFFECEFF4),
    foreground: Color(0xFF2E3440),
    card: Color(0xFFE5E9F0),
    primary: Color(0xFF5E81AC),
    primaryForeground: Color(0xFFECEFF4),
    muted: Color(0xFFD8DEE9),
    mutedForeground: Color(0xFF4C566A),
    accent: Color(0xFFCDD3DE),
    accentForeground: Color(0xFF5E81AC),
    destructive: Color(0xFFBF616A),
    destructiveForeground: Color(0xFFECEFF4),
    border: Color(0xFFCDD3DE),
    textSecondary: Color(0xFF434C5E),
    textMuted: Color(0xFF4C566A),
    amber: Color(0xFF5E81AC),
    amberHover: Color(0xFF4A6D96),
    amberSubtle: Color(0xFFDBE4F0),
    success: Color(0xFFA3BE8C),
    info: Color(0xFF81A1C1),
    surfaceDark: Color(0xFF2E3440),
    cardDark: Color(0xFFD8DEE9),
  );

  static const tokyoNight = AppThemeData(
    id: 'tokyo-night',
    name: 'Tokyo Night',
    brightness: Brightness.dark,
    background: Color(0xFF1A1B26),
    foreground: Color(0xFFE4E8FF),
    card: Color(0xFF16161E),
    primary: Color(0xFF7AA2F7),
    primaryForeground: Color(0xFF1A1B26),
    muted: Color(0xFF24283B),
    mutedForeground: Color(0xFF7480B0),
    accent: Color(0xFF292E42),
    accentForeground: Color(0xFF7AA2F7),
    destructive: Color(0xFFF7768E),
    destructiveForeground: Color(0xFF1A1B26),
    border: Color(0xFF292E42),
    textSecondary: Color(0xFFAAB3D8),
    textMuted: Color(0xFF7480B0),
    amber: Color(0xFF7AA2F7),
    amberHover: Color(0xFF5D8DE0),
    amberSubtle: Color(0xFF1E2030),
    success: Color(0xFF9ECE6A),
    info: Color(0xFF7DCFFF),
    surfaceDark: Color(0xFF13131A),
    cardDark: Color(0xFF13131A),
  );

  static const dracula = AppThemeData(
    id: 'dracula',
    name: 'Dracula',
    brightness: Brightness.dark,
    background: Color(0xFF282A36),
    foreground: Color(0xFFF8F8F2),
    card: Color(0xFF1E1F29),
    primary: Color(0xFFFF79C6),
    primaryForeground: Color(0xFF282A36),
    muted: Color(0xFF44475A),
    mutedForeground: Color(0xFF8090C0),
    accent: Color(0xFF44475A),
    accentForeground: Color(0xFFFF79C6),
    destructive: Color(0xFFFF5555),
    destructiveForeground: Color(0xFFF8F8F2),
    border: Color(0xFF44475A),
    textSecondary: Color(0xFFBD93F9),
    textMuted: Color(0xFF8090C0),
    amber: Color(0xFFFF79C6),
    amberHover: Color(0xFFE060AE),
    amberSubtle: Color(0xFF3A2840),
    success: Color(0xFF50FA7B),
    info: Color(0xFF8BE9FD),
    surfaceDark: Color(0xFF191A21),
    cardDark: Color(0xFF191A21),
  );

  static const gruvboxDark = AppThemeData(
    id: 'gruvbox-dark',
    name: 'Gruvbox Dark',
    brightness: Brightness.dark,
    background: Color(0xFF282828),
    foreground: Color(0xFFEBDBB2),
    card: Color(0xFF1D2021),
    primary: Color(0xFFD79921),
    primaryForeground: Color(0xFF282828),
    muted: Color(0xFF3C3836),
    mutedForeground: Color(0xFF9E9084),
    accent: Color(0xFF504945),
    accentForeground: Color(0xFFD79921),
    destructive: Color(0xFFCC241D),
    destructiveForeground: Color(0xFFEBDBB2),
    border: Color(0xFF504945),
    textSecondary: Color(0xFFA89984),
    textMuted: Color(0xFF9E9084),
    amber: Color(0xFFD79921),
    amberHover: Color(0xFFB8811C),
    amberSubtle: Color(0xFF3C2F00),
    success: Color(0xFF98971A),
    info: Color(0xFF458588),
    surfaceDark: Color(0xFF181818),
    cardDark: Color(0xFF181818),
  );

  static const midnightLibrary = AppThemeData(
    id: 'midnight-library',
    name: 'Midnight Library',
    brightness: Brightness.dark,
    background: Color(0xFF0F1117),
    foreground: Color(0xFFEAEDF5),
    card: Color(0xFF161B26),
    primary: Color(0xFFE6A817),
    primaryForeground: Color(0xFF0F1117),
    muted: Color(0xFF1E2535),
    mutedForeground: Color(0xFF8893B0),
    accent: Color(0xFF252D40),
    accentForeground: Color(0xFFE6A817),
    destructive: Color(0xFFE05252),
    destructiveForeground: Color(0xFFEAEDF5),
    border: Color(0xFF2A3450),
    textSecondary: Color(0xFFA0AAC5),
    textMuted: Color(0xFF8893B0),
    amber: Color(0xFFE6A817),
    amberHover: Color(0xFFC99010),
    amberSubtle: Color(0xFF2A2010),
    success: Color(0xFF49C98F),
    info: Color(0xFF4D9DE0),
    surfaceDark: Color(0xFF070A10),
    cardDark: Color(0xFF0D1320),
  );

  static const parchment = AppThemeData(
    id: 'parchment',
    name: 'Parchment',
    brightness: Brightness.light,
    background: Color(0xFFF8F3E8),
    foreground: Color(0xFF2C1F0F),
    card: Color(0xFFFDFAF3),
    primary: Color(0xFF8B4513),
    primaryForeground: Color(0xFFFDFAF3),
    muted: Color(0xFFEDE8DA),
    mutedForeground: Color(0xFF6B5A45),
    accent: Color(0xFFE8DFC8),
    accentForeground: Color(0xFF8B4513),
    destructive: Color(0xFFB91C1C),
    destructiveForeground: Color(0xFFFDFAF3),
    border: Color(0xFFD9CFBA),
    textSecondary: Color(0xFF5A4835),
    textMuted: Color(0xFF8C7660),
    amber: Color(0xFF8B4513),
    amberHover: Color(0xFF6D3510),
    amberSubtle: Color(0xFFF5E8D5),
    success: Color(0xFF1A6B4A),
    info: Color(0xFF1E4D8C),
    surfaceDark: Color(0xFF2C1F0F),
    cardDark: Color(0xFFE8DFC8),
  );

  static const oceanDepth = AppThemeData(
    id: 'ocean-depth',
    name: 'Ocean Depth',
    brightness: Brightness.dark,
    background: Color(0xFF071526),
    foreground: Color(0xFFDCEEFF),
    card: Color(0xFF0A1E38),
    primary: Color(0xFF38BDF8),
    primaryForeground: Color(0xFF071526),
    muted: Color(0xFF0F2744),
    mutedForeground: Color(0xFF7BACC8),
    accent: Color(0xFF142E50),
    accentForeground: Color(0xFF38BDF8),
    destructive: Color(0xFFF87171),
    destructiveForeground: Color(0xFF071526),
    border: Color(0xFF1A3A5C),
    textSecondary: Color(0xFF9EC3DE),
    textMuted: Color(0xFF7BACC8),
    amber: Color(0xFF38BDF8),
    amberHover: Color(0xFF22A8E0),
    amberSubtle: Color(0xFF0D2540),
    success: Color(0xFF34D399),
    info: Color(0xFF818CF8),
    surfaceDark: Color(0xFF020B15),
    cardDark: Color(0xFF081830),
  );

  static const sakura = AppThemeData(
    id: 'sakura',
    name: 'Sakura',
    brightness: Brightness.light,
    background: Color(0xFFFFF5F8),
    foreground: Color(0xFF2D0F1A),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFFE11D75),
    primaryForeground: Color(0xFFFFFFFF),
    muted: Color(0xFFFCE7F0),
    mutedForeground: Color(0xFF7A4060),
    accent: Color(0xFFFAD4E5),
    accentForeground: Color(0xFFE11D75),
    destructive: Color(0xFFDC2626),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFFF5C5DA),
    textSecondary: Color(0xFF5C2A40),
    textMuted: Color(0xFF9C6070),
    amber: Color(0xFFE11D75),
    amberHover: Color(0xFFC0185F),
    amberSubtle: Color(0xFFFDE8F2),
    success: Color(0xFF059669),
    info: Color(0xFF7C3AED),
    surfaceDark: Color(0xFF2D0F1A),
    cardDark: Color(0xFFFCE7F0),
  );

  static const Map<String, AppThemeData> all = {
    'unishare': unishare,
    'catppuccin-mocha': catppuccinMocha,
    'catppuccin-latte': catppuccinLatte,
    'nord': nord,
    'arctic': arctic,
    'tokyo-night': tokyoNight,
    'dracula': dracula,
    'gruvbox-dark': gruvboxDark,
    'midnight-library': midnightLibrary,
    'parchment': parchment,
    'ocean-depth': oceanDepth,
    'sakura': sakura,
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/shared/theme/themes.dart
git commit -m "feat: add all 12 theme token definitions"
```

---

## Task 6: Rewrite AppTheme builder (TDD)

**Files:**
- Modify: `apps/mobile/lib/shared/theme/app_theme.dart`
- Create: `apps/mobile/test/unit/shared/theme/app_theme_test.dart`

- [ ] **Step 1: Write the failing tests**

`test/unit/shared/theme/app_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';

void main() {
  group('AppTheme.fromId', () {
    test('unishare is light', () {
      final theme = AppTheme.fromId('unishare');
      expect(theme.brightness, Brightness.light);
    });

    test('catppuccin-mocha is dark', () {
      final theme = AppTheme.fromId('catppuccin-mocha');
      expect(theme.brightness, Brightness.dark);
    });

    test('all themes include AppColors extension', () {
      for (final id in [
        'unishare', 'catppuccin-mocha', 'catppuccin-latte', 'nord',
        'arctic', 'tokyo-night', 'dracula', 'gruvbox-dark',
        'midnight-library', 'parchment', 'ocean-depth', 'sakura',
      ]) {
        final theme = AppTheme.fromId(id);
        expect(
          theme.extension<AppColors>(),
          isNotNull,
          reason: '$id is missing AppColors extension',
        );
      }
    });

    test('unknown id falls back to unishare', () {
      final theme = AppTheme.fromId('does-not-exist');
      expect(theme.brightness, Brightness.light);
      expect(theme.extension<AppColors>()?.amber, const Color(0xFFD97706));
    });

    test('unishare amber token is amber color', () {
      final theme = AppTheme.fromId('unishare');
      final colors = theme.extension<AppColors>()!;
      expect(colors.amber, const Color(0xFFD97706));
    });

    test('scaffold background matches theme background', () {
      final theme = AppTheme.fromId('unishare');
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF7F3EE));
    });
  });
}
```

- [ ] **Step 2: Run to confirm tests fail**

```bash
flutter test test/unit/shared/theme/app_theme_test.dart
```

Expected: compilation error or test failures — `AppTheme.fromId` does not exist yet.

- [ ] **Step 3: Replace app_theme.dart**

`lib/shared/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme_data.dart';
import 'app_typography.dart';
import 'themes.dart';

class AppTheme {
  static ThemeData fromId(String id) =>
      build(AppThemes.all[id] ?? AppThemes.unishare);

  static ThemeData build(AppThemeData d) {
    final scheme = ColorScheme.fromSeed(
      seedColor: d.primary,
      brightness: d.brightness,
    ).copyWith(
      primary: d.primary,
      onPrimary: d.primaryForeground,
      secondary: d.accent,
      onSecondary: d.accentForeground,
      error: d.destructive,
      onError: d.destructiveForeground,
      surface: d.background,
      onSurface: d.foreground,
      outline: d.border,
      surfaceContainerHighest: d.card,
    );

    final appColors = AppColors(
      border: d.border,
      muted: d.muted,
      mutedForeground: d.mutedForeground,
      textSecondary: d.textSecondary,
      textMuted: d.textMuted,
      amber: d.amber,
      amberHover: d.amberHover,
      amberSubtle: d.amberSubtle,
      success: d.success,
      info: d.info,
      surfaceDark: d.surfaceDark,
      cardDark: d.cardDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: d.brightness,
      colorScheme: scheme,
      extensions: [appColors],
      textTheme: AppTypography.textTheme(d.foreground),
      scaffoldBackgroundColor: d.background,
      cardColor: d.card,
      dividerColor: d.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: d.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: d.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: d.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: d.amber, width: 1.5),
        ),
      ),
      cardTheme: CardTheme(
        color: d.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: d.border),
        ),
        elevation: 0,
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
flutter test test/unit/shared/theme/app_theme_test.dart
```

Expected: All 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/shared/theme/app_theme.dart apps/mobile/test/unit/shared/theme/app_theme_test.dart
git commit -m "feat: rewrite AppTheme with token-based builder and 12-theme registry"
```

---

## Task 7: Hive initialization in main.dart

**Files:**
- Modify: `apps/mobile/lib/main.dart`

- [ ] **Step 1: Update main.dart to init Hive**

Replace the current `main()` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/router.dart';
import 'shared/theme/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(activeThemeProvider);
    return MaterialApp.router(
      title: 'Unishare',
      theme: theme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
```

Note: `themeMode: ThemeMode.light` forces Flutter to always use `theme` (not a system dark theme). The selected ThemeData already has the correct colors regardless of whether it is visually dark or light.

- [ ] **Step 2: Commit (after provider exists — do not commit yet, continue to Task 8)**

---

## Task 8: ThemeNotifier provider (TDD)

**Files:**
- Create: `apps/mobile/lib/shared/theme/providers/theme_provider.dart`
- Create: `apps/mobile/test/unit/shared/theme/theme_provider_test.dart`

- [ ] **Step 1: Write the failing tests**

`test/unit/shared/theme/theme_provider_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:unishare_mobile/shared/theme/providers/theme_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('ThemeNotifier', () {
    test('initial state defaults to unishare when box is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(themeNotifierProvider), 'unishare');
    });

    test('initial state reads persisted value from Hive', () async {
      await Hive.box('settings').put('selected_theme', 'nord');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(themeNotifierProvider), 'nord');
    });

    test('setTheme updates provider state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(themeNotifierProvider.notifier).setTheme('dracula');
      expect(container.read(themeNotifierProvider), 'dracula');
    });

    test('setTheme persists to Hive', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(themeNotifierProvider.notifier).setTheme('tokyo-night');
      expect(Hive.box('settings').get('selected_theme'), 'tokyo-night');
    });
  });

  group('activeThemeProvider', () {
    test('returns ThemeData for selected theme', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final theme = container.read(activeThemeProvider);
      expect(theme.brightness, Brightness.light); // unishare default
    });
  });
}
```

- [ ] **Step 2: Run to confirm tests fail**

```bash
flutter test test/unit/shared/theme/theme_provider_test.dart
```

Expected: compilation error — `theme_provider.dart` does not exist yet.

- [ ] **Step 3: Create the providers directory and theme_provider.dart**

```bash
mkdir -p apps/mobile/lib/shared/theme/providers
```

`lib/shared/theme/providers/theme_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../app_theme.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  static const _boxName = 'settings';
  static const _key = 'selected_theme';

  @override
  String build() {
    final box = Hive.box(_boxName);
    return box.get(_key, defaultValue: 'unishare') as String;
  }

  Future<void> setTheme(String id) async {
    await Hive.box(_boxName).put(_key, id);
    state = id;
  }
}

@riverpod
ThemeData activeTheme(Ref ref) {
  final id = ref.watch(themeNotifierProvider);
  return AppTheme.fromId(id);
}
```

- [ ] **Step 4: Run code generation**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `lib/shared/theme/providers/theme_provider.g.dart` without errors.

- [ ] **Step 5: Run tests to confirm they pass**

```bash
flutter test test/unit/shared/theme/theme_provider_test.dart
```

Expected: All 5 tests pass.

- [ ] **Step 6: Commit everything**

```bash
git add apps/mobile/lib/main.dart \
        apps/mobile/lib/shared/theme/providers/ \
        apps/mobile/test/unit/shared/theme/theme_provider_test.dart
git commit -m "feat: add ThemeNotifier with Hive persistence and wire into MaterialApp"
```

---

## Task 9: Smoke test — run the app

- [ ] **Step 1: Run on Chrome to confirm the app boots with the default theme**

```bash
flutter run -d chrome
```

Expected: app opens showing "Unishare" text on a warm off-white (`#F7F3EE`) background with amber accent. No errors in console.

- [ ] **Step 2: Run all unit tests**

```bash
flutter test test/unit/
```

Expected: All tests pass.

- [ ] **Step 3: Run static analysis**

```bash
flutter analyze
dart format . --set-exit-if-changed
```

Expected: no issues, no formatting changes needed.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: design system smoke test passed"
```
