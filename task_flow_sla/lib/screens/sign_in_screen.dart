import 'package:flutter/material.dart';

import '../app_router.dart';
import '../models/team_member.dart';
import '../services/database_helper.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/dialogs.dart';
import '../widgets/entrance.dart';
import '../widgets/icon_circle_button.dart';
import '../widgets/password_toggle.dart';
import '../widgets/pill_buttons.dart';

/// Sign In.
///
/// There is no real authentication service. Signing in checks the email and
/// password against the members stored in the local database. Switching
/// between members later is done from the Team tab ("Switch user").
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  /// The "Remember me" checkbox was removed from the design, so the session
  /// is always remembered. SessionService still supports both choices.
  static const _rememberMe = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  List<TeamMember> _members = [];
  bool _loadingMembers = true;
  bool _obscurePassword = true;
  bool _submitting = false;

  /// Shown under the email field when no member matches the typed email.
  String? _emailError;

  /// Shown under the password field when the password is wrong.
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await DatabaseHelper.instance.getMembers();
      if (!mounted) return;
      setState(() {
        _members = members;
        _loadingMembers = false;
      });
    } catch (error, stack) {
      logError('Could not load members', error, stack);
      if (!mounted) return;
      setState(() => _loadingMembers = false);
      showMessage(context, 'Could not load team members. Please try again.');
    }
  }

  Future<void> _signInWithEmail() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final member = _members
        .where((m) => m.email.toLowerCase() == email)
        .firstOrNull;
    if (member == null) {
      setState(() => _emailError = 'No team member uses this email');
      return;
    }

    setState(() => _submitting = true);
    final bool correct;
    try {
      correct = await DatabaseHelper.instance.checkPassword(
        member.id!,
        _passwordController.text,
      );
    } catch (error, stack) {
      logError('Could not check password', error, stack);
      if (!mounted) return;
      setState(() => _submitting = false);
      showMessage(context, 'Sign in failed. Please try again.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (!correct) _passwordError = 'Incorrect password';
    });
    if (correct) await _completeSignIn(member);
  }

  Future<void> _completeSignIn(TeamMember member) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await SessionService.signIn(member.id!, remember: _rememberMe);
      if (!mounted) return;
      AppRoutes.goHome(context);
    } catch (error, stack) {
      logError('Could not save session', error, stack);
      if (!mounted) return;
      setState(() => _submitting = false);
      showMessage(context, 'Sign in failed. Please try again.');
    }
  }

  void _openRegister() {
    Navigator.pushReplacementNamed(context, AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          // Fills the screen so the "Create account" line sits at the bottom,
          // but still scrolls when the keyboard is open.
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTop(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: SlideUpIn(
                      delay: const Duration(milliseconds: 1000),
                      child: _buildCreateAccountLine(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTop() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SlideUpIn(
              child: IconCircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: 'Back',
                onPressed: () => AppRoutes.backToLanding(context),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 38, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RiseIn(
                delay: const Duration(milliseconds: 100),
                child: Text('Welcome back', style: AppText.screenTitle()),
              ),
              const SizedBox(height: 8),
              RiseIn(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  "Sign in to track your team's tasks.",
                  style: AppText.bodyMuted(),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 34, 20, 0),
          child: _buildForm(),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SlideUpIn(
            delay: const Duration(milliseconds: 300),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              style: AppText.manrope(15, weight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Email',
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                errorText: _emailError,
              ),
              validator: Validators.email,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
            ),
          ),
          const SizedBox(height: 12),
          SlideUpIn(
            delay: const Duration(milliseconds: 380),
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              style: AppText.manrope(15, weight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                errorText: _passwordError,
                suffixIcon: PasswordToggle(
                  obscured: _obscurePassword,
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: Validators.password,
              onChanged: (_) {
                if (_passwordError != null) {
                  setState(() => _passwordError = null);
                }
              },
              onFieldSubmitted: (_) => _signInWithEmail(),
            ),
          ),
          const SizedBox(height: 20),
          SlideUpIn(
            delay: const Duration(milliseconds: 460),
            child: PrimaryPillButton(
              label: 'Sign In',
              loading: _submitting,
              // Members must be loaded before an email can be matched.
              onPressed: _loadingMembers ? null : _signInWithEmail,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateAccountLine() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'New to the team?',
          style: AppText.manrope(14, color: AppColors.iconMuted),
        ),
        TextButton(
          onPressed: _submitting ? null : _openRegister,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          child: Text(
            'Create account',
            style: AppText.manrope(
              14,
              weight: FontWeight.w800,
            ).copyWith(decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }
}
