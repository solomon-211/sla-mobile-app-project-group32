import 'package:flutter/material.dart';

import '../app_router.dart';
import '../models/team_member.dart';
import '../services/database_helper.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/dialogs.dart';
import '../widgets/entrance.dart';
import '../widgets/password_toggle.dart';
import '../widgets/pill_buttons.dart';

/// Create account. Saves a new team member with their chosen password using
/// the same database call the old "Create account" dialog used, then signs
/// them in.
///
/// The password strength bar and the "passwords don't match" message are
/// UI-only hints. The saved password only has to pass
/// [Validators.password] (6+ characters).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  static const _roles = [
    'Project Manager',
    'Backend Developer',
    'UI/UX Designer',
    'Mobile Developer',
  ];

  /// Sessions are always remembered (the "Remember me" option was removed).
  static const _rememberMe = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  /// The dark header card shrinks from 340 to 200px when the screen opens.
  late final AnimationController _hero = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _heroHeight = Tween<double>(begin: 340, end: 200)
      .animate(
        CurvedAnimation(parent: _hero, curve: const Cubic(0.77, 0, 0.18, 1)),
      );

  String _role = _roles.first;
  List<TeamMember> _members = [];
  bool _loadingMembers = true;
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _passwordController.addListener(_refresh);
    _confirmController.addListener(_refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hero.isDismissed) {
      if (MediaQuery.of(context).disableAnimations) {
        _hero.value = 1;
      } else {
        _hero.forward();
      }
    }
  }

  @override
  void dispose() {
    _hero.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Rebuilds the strength bar and mismatch message as the user types.
  void _refresh() => setState(() {});

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

  bool get _mismatch =>
      _confirmController.text.isNotEmpty &&
      _confirmController.text != _passwordController.text;

  String? _validateEmail(String? value) {
    final error = Validators.email(value);
    if (error != null) return error;
    final email = value!.trim().toLowerCase();
    if (_members.any((m) => m.email.toLowerCase() == email)) {
      return 'Another member already uses this email';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != _passwordController.text) return "Passwords don't match";
    return null;
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final member = await DatabaseHelper.instance.insertMember(
        TeamMember(
          name: _nameController.text.trim(),
          role: _role,
          email: _emailController.text.trim().toLowerCase(),
          colorIndex: _members.length,
        ),
        password: _passwordController.text,
      );
      await SessionService.signIn(member.id!, remember: _rememberMe);
      if (!mounted) return;
      AppRoutes.goHome(context);
    } catch (error, stack) {
      logError('Could not create account', error, stack);
      if (!mounted) return;
      setState(() => _submitting = false);
      showMessage(context, 'Could not create the account. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHero(),
            Expanded(child: _buildForm()),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return AnimatedBuilder(
      animation: _heroHeight,
      builder: (context, child) => Container(
        height: _heroHeight.value,
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(32),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            left: 16,
            child: Tooltip(
              message: 'Back',
              child: Material(
                color: Colors.white.withValues(alpha: 0.06),
                shape: CircleBorder(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => AppRoutes.backToLanding(context),
                  child: const SizedBox.square(
                    dimension: 44,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.paper,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RiseIn(
                  delay: const Duration(milliseconds: 500),
                  child: Text(
                    'Create your account',
                    style: AppText.sora(
                      28,
                      color: AppColors.paper,
                      height: 34,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                RiseIn(
                  delay: const Duration(milliseconds: 620),
                  child: Text(
                    'Join your team and start tracking tasks.',
                    style: AppText.manrope(
                      14,
                      weight: FontWeight.w600,
                      color: AppColors.textMutedDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final fieldText = AppText.manrope(15, weight: FontWeight.w600);
    Duration at(int ms) => Duration(milliseconds: ms);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          SlideUpIn(
            delay: at(550),
            child: TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              style: fieldText,
              decoration: const InputDecoration(
                hintText: 'Full name',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
              validator: (value) => Validators.requiredText(value, 'Name'),
            ),
          ),
          const SizedBox(height: 10),
          SlideUpIn(
            delay: at(620),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              style: fieldText,
              decoration: const InputDecoration(
                hintText: 'Work email',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
              ),
              validator: _validateEmail,
            ),
          ),
          const SizedBox(height: 10),
          SlideUpIn(
            delay: at(690),
            child: DropdownButtonFormField<String>(
              initialValue: _role,
              isExpanded: true,
              style: fieldText,
              borderRadius: BorderRadius.circular(20),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.work_outline_rounded, size: 20),
              ),
              items: [
                for (final role in _roles)
                  DropdownMenuItem(value: role, child: Text(role)),
              ],
              onChanged: (value) => setState(() => _role = value!),
            ),
          ),
          const SizedBox(height: 10),
          SlideUpIn(
            delay: at(760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  style: fieldText,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                    ),
                    suffixIcon: PasswordToggle(
                      obscured: _obscurePassword,
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 8),
                _StrengthBar(password: _passwordController.text),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SlideUpIn(
            delay: at(830),
            child: TextFormField(
              controller: _confirmController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              style: fieldText,
              decoration: InputDecoration(
                hintText: 'Confirm password',
                prefixIcon: const Icon(Icons.verified_user_outlined, size: 20),
                // Shown live while typing, before the form is submitted.
                errorText: _mismatch ? "Passwords don't match" : null,
              ),
              validator: _validateConfirm,
              onFieldSubmitted: (_) => _createAccount(),
            ),
          ),
          const SizedBox(height: 14),
          SlideUpIn(
            delay: at(970),
            child: PrimaryPillButton(
              label: 'Create account',
              loading: _submitting,
              // Members must be loaded to check for a duplicate email.
              onPressed: _loadingMembers ? null : _createAccount,
            ),
          ),
          const SizedBox(height: 6),
          SlideUpIn(
            delay: at(1040),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: AppText.manrope(14, color: AppColors.iconMuted),
                ),
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.signIn,
                        ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: Text(
                    'Sign in',
                    style: AppText.manrope(
                      14,
                      weight: FontWeight.w800,
                    ).copyWith(decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Four-segment password strength meter. One point each for 8+ characters,
/// a digit, a capital letter and a symbol. A visual hint only.
class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.password});

  final String password;

  static const _levels = [
    ('Use 8+ characters', AppColors.iconMuted, AppColors.barEmpty),
    ('Weak', AppColors.error, AppColors.coral),
    ('Fair', Color(0xFF8A5A00), AppColors.amber),
    ('Good', AppColors.mossText, AppColors.mossLight),
    ('Strong', AppColors.mossText, AppColors.moss),
  ];

  int get _score {
    var score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
    if (password.isNotEmpty && score == 0) score = 1;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    final (label, textColor, barColor) = _levels[score];

    return Semantics(
      label: 'Password strength: $label',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 6,
                        decoration: BoxDecoration(
                          color: i < score ? barColor : AppColors.barEmpty,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 96),
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: AppText.manrope(
                  12,
                  weight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
