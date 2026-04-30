import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/auth_exception.dart';
import '../providers/auth_repository_provider.dart';
import '../providers/guest_mode_provider.dart';
import '../providers/universities_provider.dart';
import '../widgets/auth_text_field.dart';
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
const _kTextSecondary = Color(0xFF6B6560);
const _kTextMuted = Color(0xFF8A837E);
const _kDestructive = Color(0xFFDC2626);

enum _AuthMode { signIn, signUp }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

// Keep the old name as an alias so any code that still references WelcomeScreen
// continues to compile without change.
typedef WelcomeScreen = AuthScreen;

class _AuthScreenState extends ConsumerState<AuthScreen> {
  _AuthMode _mode = _AuthMode.signIn;

  final _formKey = GlobalKey<FormState>();

  // Sign-in controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Sign-up-only controllers
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedUniversityId;
  bool _consentChecked = false;
  bool _consentError = false;
  bool _isLoading = false;
  bool _googleLoading = false;
  String? _serverError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _mode = _mode == _AuthMode.signIn ? _AuthMode.signUp : _AuthMode.signIn;
      _serverError = null;
      _consentChecked = false;
      _consentError = false;
      _selectedUniversityId = null;
    });
    _formKey.currentState?.reset();
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _confirmPasswordController.clear();
  }

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

  void _showMicrosoftComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Microsoft sign-in coming soon')),
    );
  }

  Future<void> _handleSignIn() async {
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

  Future<void> _handleSignUp() async {
    setState(() {
      _serverError = null;
      _consentError = !_consentChecked;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_consentChecked) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            universityId: _selectedUniversityId,
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
    final universitiesAsync = ref.watch(universitiesProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildDesktopLayout(universitiesAsync);
          }
          return _buildMobileLayout(universitiesAsync);
        },
      ),
    );
  }

  Widget _buildDesktopLayout(
    AsyncValue<List<({String id, String name})>> universitiesAsync,
  ) {
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 384),
                  child: _buildFormContent(
                    isMobile: false,
                    universitiesAsync: universitiesAsync,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    AsyncValue<List<({String id, String name})>> universitiesAsync,
  ) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: _buildFormContent(
          isMobile: true,
          universitiesAsync: universitiesAsync,
        ),
      ),
    );
  }

  Widget _buildFormContent({
    required bool isMobile,
    required AsyncValue<List<({String id, String name})>> universitiesAsync,
  }) {
    final isSignUp = _mode == _AuthMode.signUp;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mobile-only logo
          if (isMobile) ...[
            const Center(child: UnishareLogo(iconSize: 36, fontSize: 18)),
            const SizedBox(height: 36),
          ],

          // 1. Heading
          Text(
            isSignUp ? 'Create account' : 'Sign in',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: _kForeground,
            ),
          ),

          // 2. Subheading
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

          // 3. Google sign-in button
          GoogleSignInButton(
            onPressed: _handleGoogleSignIn,
            isLoading: _googleLoading,
          ),

          // 4. Microsoft sign-in button
          const SizedBox(height: 12),
          MicrosoftSignInButton(onPressed: _showMicrosoftComingSoon),

          // 5. "or" divider
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

          // 6. Form fields
          if (isSignUp) ...[
            // Full name
            AuthTextField(
              hint: 'Full name',
              controller: _nameController,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // University dropdown
            universitiesAsync.when(
              data: (universities) => DropdownButtonFormField<String>(
                initialValue: _selectedUniversityId,
                hint: Text(
                  'Select your university (optional)',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: _kTextSecondary,
                  ),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFFEF3C7),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
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
                    borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                  ),
                ),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: _kForeground,
                ),
                items: universities
                    .map(
                      (u) => DropdownMenuItem(
                        value: u.id,
                        child: Text(
                          u.name,
                          style: GoogleFonts.spaceGrotesk(fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedUniversityId = val),
              ),
              loading: () => const LinearProgressIndicator(color: _kPrimary),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),

            // Email
            AuthTextField(
              hint: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Password (min 8 chars)
            AuthTextField(
              hint: 'Password',
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Confirm password
            AuthTextField(
              hint: 'Confirm password',
              controller: _confirmPasswordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _handleSignUp(),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Please confirm your password';
                }
                if (v != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Consent checkbox row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: _consentChecked,
                  onChanged: (v) => setState(() {
                    _consentChecked = v ?? false;
                    if (_consentChecked) _consentError = false;
                  }),
                  activeColor: _kForeground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'I have read and agree to the Terms of Service and Privacy Policy.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: _kTextSecondary,
                    ),
                  ),
                ),
              ],
            ),

            // 7. Consent error text
            if (_consentError) ...[
              const SizedBox(height: 4),
              Text(
                'You must accept the Terms and Privacy Policy to create an account',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: _kDestructive,
                ),
              ),
            ],
          ] else ...[
            // Sign-in fields: Email + Password
            AuthTextField(
              hint: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email is required';
                }
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
              onFieldSubmitted: (_) => _handleSignIn(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                return null;
              },
            ),
          ],

          // 8. Server error text
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

          // 9. Submit button
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: FilledButton(
              onPressed: (isSignUp && !_consentChecked) || _isLoading
                  ? null
                  : (isSignUp ? _handleSignUp : _handleSignIn),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: _kPrimaryFg,
                disabledBackgroundColor: _kPrimary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                _isLoading
                    ? 'Please wait…'
                    : (isSignUp ? 'Create account' : 'Sign in'),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _kPrimaryFg,
                ),
              ),
            ),
          ),

          // 10. Mode-switch row
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isSignUp
                    ? 'Already have an account? '
                    : "Don’t have an account? ",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: _kTextMuted,
                ),
              ),
              TextButton(
                onPressed: _switchMode,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: _kForeground,
                ),
                child: Text(
                  isSignUp ? 'Sign in' : 'Sign up',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: _kForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          // 11. Divider
          const SizedBox(height: 16),
          const Divider(color: _kBorder, height: 1),

          // 12. Continue as guest
          const SizedBox(height: 4),
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
          const SizedBox(height: 8),

          // 13. Sign-up OAuth footnote
          if (isSignUp) ...[
            const SizedBox(height: 8),
            Text(
              'By continuing with Google or Microsoft you agree to our Terms and Privacy Policy.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(fontSize: 12, color: _kTextMuted),
            ),
          ],
        ],
      ),
    );
  }
}
