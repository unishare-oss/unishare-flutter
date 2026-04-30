import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/auth_exception.dart';
import '../providers/auth_repository_provider.dart';
import '../providers/guest_mode_provider.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/unishare_logo.dart';

// Web-matched auth palette — hardcoded so these screens always look correct
// regardless of the active app theme.
const _kBg = Color(0xFFF7F3EE);
const _kSurfaceDark = Color(0xFF1C1917);
const _kForeground = Color(0xFF1C1917);
const _kPrimary = Color(0xFFD97706);
const _kPrimaryFg = Color(0xFFFFFFFF);
const _kBorder = Color(0xFFE2DAD0);
const _kTextMuted = Color(0xFF8A837E);

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _googleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // Router redirect will navigate away on auth state change.
    } on StateError {
      // User cancelled Google sign-in — silent.
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.userMessage)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _DesktopLayout(
              googleLoading: _googleLoading,
              onGoogleSignIn: _handleGoogleSignIn,
              onSignInWithEmail: () => context.push('/sign-in'),
              onCreateAccount: () => context.push('/sign-up'),
              onGuest: () => ref.read(guestModeProvider.notifier).enter(),
            );
          }
          return _MobileLayout(
            googleLoading: _googleLoading,
            onGoogleSignIn: _handleGoogleSignIn,
            onSignInWithEmail: () => context.push('/sign-in'),
            onCreateAccount: () => context.push('/sign-up'),
            onGuest: () => ref.read(guestModeProvider.notifier).enter(),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile layout
// ---------------------------------------------------------------------------

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.googleLoading,
    required this.onGoogleSignIn,
    required this.onSignInWithEmail,
    required this.onCreateAccount,
    required this.onGuest,
  });

  final bool googleLoading;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onSignInWithEmail;
  final VoidCallback onCreateAccount;
  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 2),
            const UnishareLogo(iconSize: 48, fontSize: 22),
            const SizedBox(height: 8),
            Text(
              'Every lecture note and study guide — shared by students who’ve been there.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: _kForeground,
              ),
            ),
            const Spacer(flex: 2),
            GoogleSignInButton(
              onPressed: onGoogleSignIn,
              isLoading: googleLoading,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: OutlinedButton(
                onPressed: onSignInWithEmail,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  foregroundColor: _kForeground,
                ),
                child: Text(
                  'Sign in with email',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: _kForeground,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: FilledButton(
                onPressed: onCreateAccount,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: _kPrimaryFg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'Create account',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _kPrimaryFg,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onGuest,
              child: Text(
                'Continue as guest',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: _kTextMuted,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop layout
// ---------------------------------------------------------------------------

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.googleLoading,
    required this.onGoogleSignIn,
    required this.onSignInWithEmail,
    required this.onCreateAccount,
    required this.onGuest,
  });

  final bool googleLoading;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onSignInWithEmail;
  final VoidCallback onCreateAccount;
  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left panel — 55% width, always dark
        Flexible(
          flex: 55,
          child: Container(
            color: _kSurfaceDark,
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const UnishareLogo(iconSize: 28, fontSize: 18, darkText: false),
                // Tagline
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Text(
                    'Every lecture note and study guide — shared by students who’ve been there.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 30,
                      fontWeight: FontWeight.w300,
                      color: const Color(0xFFF7F3EE),
                      letterSpacing: -0.5,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 0),
              ],
            ),
          ),
        ),
        // Right panel — flex-1, light bg
        Flexible(
          flex: 45,
          child: Container(
            color: _kBg,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 384),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GoogleSignInButton(
                        onPressed: onGoogleSignIn,
                        isLoading: googleLoading,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: onSignInWithEmail,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _kBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            foregroundColor: _kForeground,
                          ),
                          child: Text(
                            'Sign in with email',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              color: _kForeground,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 42,
                        child: FilledButton(
                          onPressed: onCreateAccount,
                          style: FilledButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: _kPrimaryFg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'Create account',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _kPrimaryFg,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onGuest,
                        child: Text(
                          'Continue as guest',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            color: _kTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
