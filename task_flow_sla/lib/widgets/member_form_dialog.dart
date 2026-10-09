import 'package:flutter/material.dart';

import '../models/team_member.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

/// What the member dialog returns: the filled-in member (not yet saved) and,
/// when the dialog asked for one, the password they chose.
typedef MemberDraft = ({TeamMember member, String? password});

/// Dialog for adding a member or editing an existing one.
///
/// Returns a [MemberDraft], or null if cancelled.
/// [takenEmails] are the emails of the *other* members, used to stop
/// duplicates before the database rejects them. Set [askPassword] when the
/// person filling in the form is creating their own account.
Future<MemberDraft?> showMemberFormDialog(
  BuildContext context, {
  TeamMember? member,
  required Iterable<String> takenEmails,
  int colorIndex = 0,
  String? title,
  bool askPassword = false,
}) {
  return showDialog<MemberDraft>(
    context: context,
    builder: (_) => _MemberFormDialog(
      member: member,
      takenEmails: takenEmails.map((email) => email.toLowerCase()).toSet(),
      colorIndex: colorIndex,
      title: title ?? (member == null ? 'Add team member' : 'Edit profile'),
      askPassword: askPassword,
    ),
  );
}

class _MemberFormDialog extends StatefulWidget {
  const _MemberFormDialog({
    required this.member,
    required this.takenEmails,
    required this.colorIndex,
    required this.title,
    required this.askPassword,
  });

  final TeamMember? member;
  final Set<String> takenEmails;
  final int colorIndex;
  final String title;
  final bool askPassword;

  @override
  State<_MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<_MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.member?.name);
  late final _roleController = TextEditingController(text: widget.member?.role);
  late final _emailController = TextEditingController(
    text: widget.member?.email,
  );
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final error = Validators.email(value);
    if (error != null) return error;
    if (widget.takenEmails.contains(value!.trim().toLowerCase())) {
      return 'Another member already uses this email';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final role = _roleController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    final existing = widget.member;
    final member = existing == null
        ? TeamMember(
            name: name,
            role: role,
            email: email,
            colorIndex: widget.colorIndex,
          )
        : existing.copyWith(name: name, role: role, email: email);
    final MemberDraft draft = (
      member: member,
      password: widget.askPassword ? _passwordController.text : null,
    );
    Navigator.pop(context, draft);
  }

  @override
  Widget build(BuildContext context) {
    // Grey fields so they stand out on the white dialog.
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          fillColor: AppColors.surfaceMuted,
        ),
      ),
      child: _buildDialog(),
    );
  }

  Widget _buildDialog() {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (value) => Validators.requiredText(value, 'Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _roleController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  hintText: 'e.g. QA Engineer',
                ),
                validator: (value) => Validators.requiredText(value, 'Role'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: widget.askPassword
                    ? TextInputAction.next
                    : TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: _validateEmail,
                onFieldSubmitted: widget.askPassword ? null : (_) => _submit(),
              ),
              if (widget.askPassword) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText:
                        'At least ${Validators.passwordMinLength} characters',
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
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
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
