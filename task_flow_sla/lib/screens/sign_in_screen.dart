import 'package:flutter/material.dart';

import '../app_router.dart';
import '../models/team_member.dart';
import '../services/database_helper.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/dialogs.dart';
import '../widgets/member_avatar.dart';
import '../widgets/member_form_dialog.dart';

/// Sign In / User Selection.
///
/// There is no real authentication: an email is accepted when it belongs to a
/// team member stored in the database, or the user taps a member to sign in.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  List<TeamMember> _members = [];
  bool _loadingMembers = true;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _submitting = false;

  /// Shown under the email field when no member matches the typed email.
  String? _emailError;

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
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMembers = false);
      showMessage(context, 'Could not load team members. Please try again.');
    }
  }

  Future<void> _signInWithEmail() async {
    setState(() => _emailError = null);
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final member =
        _members.where((m) => m.email.toLowerCase() == email).firstOrNull;
    if (member == null) {
      setState(() => _emailError = 'No team member uses this email');
      return;
    }
    await _completeSignIn(member);
  }

  Future<void> _completeSignIn(TeamMember member) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await SessionService.signIn(member.id!, remember: _rememberMe);
      if (!mounted) return;
      // Replace this screen so Back does not return to sign in.
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showMessage(context, 'Sign in failed. Please try again.');
    }
  }

  Future<void> _createAccount() async {
    final draft = await showMemberFormDialog(
      context,
      title: 'Create account',
      takenEmails: _members.map((m) => m.email),
      colorIndex: _members.length,
    );
    if (draft == null) return;
    try {
      final member = await DatabaseHelper.instance.insertMember(draft);
      await _completeSignIn(member);
    } catch (_) {
      if (!mounted) return;
      showMessage(context, 'Could not create the account. Please try again.');
    }
  }

  void _showForgotPassword() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Forgot password?'),
        content: const Text(
          'SprintTrack keeps everything on this device and has no real '
          'accounts. Enter a team email with any password of 6 or more '
          'characters, or tap a team member to sign in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Logo(),
                  const SizedBox(height: 28),
                  _buildForm(),
                  const SizedBox(height: 24),
                  _buildDemoMembers(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'New to the team?',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      TextButton(
                        onPressed: _submitting ? null : _createAccount,
                        child: const Text('Create account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'Email',
              prefixIcon: const Icon(Icons.mail_outline),
              errorText: _emailError,
            ),
            validator: Validators.email,
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: Validators.password,
            onFieldSubmitted: (_) => _signInWithEmail(),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() => _rememberMe = value ?? false);
                },
              ),
              const Expanded(child: Text('Remember me')),
              TextButton(
                onPressed: _showForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _submitting ? null : _signInWithEmail,
            child: _submitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoMembers() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or sign in as a team member',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        if (_loadingMembers)
          const CircularProgressIndicator()
        else
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              for (final member in _members)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _submitting ? null : () => _completeSignIn(member),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MemberAvatar(member: member, radius: 24),
                        const SizedBox(height: 4),
                        Text(
                          member.firstName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.task_alt, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 16),
        const Text(
          'SprintTrack',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Project & SLA Task Tracker',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Assign it. Track it. Deliver on time.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
