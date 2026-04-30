import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/auth_exception.dart';
import '../providers/auth_repository_provider.dart';
import '../providers/guest_mode_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/unishare_logo.dart';

// Web-matched auth palette.
const _kBg = Color(0xFFF7F3EE);
const _kSurfaceDark = Color(0xFF1C1917);
const _kForeground = Color(0xFF1C1917);
const _kPrimary = Color(0xFFD97706);
const _kPrimaryFg = Color(0xFFFFFFFF);
const _kBorder = Color(0xFFE2DAD0);
const _kTextSecondary = Color(0xFF6B6560);
const _kTextMuted = Color(0xFF8A837E);
const _kDestructive = Color(0xFFDC2626);

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _googleLoading = false;
  String? _serverError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on StateError {
      // User cancelled — silent.
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

  void _showMicrosoftComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Microsoft sign-in coming soon')),
    );
  }

  Future<void> _submit() async {
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Router redirect handles navigation.
    } on AuthException catch (e) {
      if (mounted) setState(() => _serverError = e.userMessage);
    } catch (_) {
      if (mounted) setState(() => _serverError = 'Something went wrong');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildDesktopLayout();
          }
          return _buildMobileLayout();
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left panel — always dark
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
        // Right panel
        Flexible(
          flex: 45,
          child: Container(
            color: _kBg,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 384),
                  child: _buildFormContent(isMobile: false),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: _buildFormContent(isMobile: true),
      ),
    );
  }

  Widget _buildFormContent({required bool isMobile}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mobile-only logo row
          if (isMobile) ...[
            const Center(child: UnishareLogo(iconSize: 36, fontSize: 18)),
            const SizedBox(height: 40),
          ],

          // Heading
          Text(
            'Sign in',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: _kForeground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use your university account to continue',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: _kTextSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // OAuth buttons
          GoogleSignInButton(
            onPressed: _handleGoogleSignIn,
            isLoading: _googleLoading,
          ),
          const SizedBox(height: 12),
          MicrosoftSignInButton(onPressed: _showMicrosoftComingSoon),

          // "or" divider
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider(color: _kBorder, height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: _kTextMuted,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: _kBorder, height: 1)),
            ],
          ),
          const SizedBox(height: 24),

          // Form fields
          AuthTextField(
            hint: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          AuthTextField(
            hint: 'Password',
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _submit(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              return null;
            },
          ),

          // Server error
          if (_serverError != null) ...[
            const SizedBox(height: 8),
            Text(
              _serverError!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: _kDestructive,
              ),
            ),
          ],

          const SizedBox(height: 4),
          SizedBox(
            height: 42,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: _kPrimaryFg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                _isLoading ? 'Please wait…' : 'Sign in',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _kPrimaryFg,
                ),
              ),
            ),
          ),

          // Mode switch
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: _kTextMuted,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/sign-up'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Sign up',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: _kForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: _kBorder, height: 1),

          // Guest
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => ref.read(guestModeProvider.notifier).enter(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Continue as guest',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: _kTextMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
