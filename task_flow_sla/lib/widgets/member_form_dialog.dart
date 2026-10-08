import 'package:flutter/material.dart';

import '../models/team_member.dart';
import '../utils/validators.dart';

/// Dialog for adding a member or editing an existing one.
///
/// Returns the filled-in member (not yet saved) or null if cancelled.
/// [takenEmails] are the emails of the *other* members, used to stop
/// duplicates before the database rejects them.
Future<TeamMember?> showMemberFormDialog(
  BuildContext context, {
  TeamMember? member,
  required Iterable<String> takenEmails,
  int colorIndex = 0,
  String? title,
}) {
  return showDialog<TeamMember>(
    context: context,
    builder: (_) => _MemberFormDialog(
      member: member,
      takenEmails: takenEmails.map((email) => email.toLowerCase()).toSet(),
      colorIndex: colorIndex,
      title: title ?? (member == null ? 'Add team member' : 'Edit profile'),
    ),
  );
}

class _MemberFormDialog extends StatefulWidget {
  const _MemberFormDialog({
    required this.member,
    required this.takenEmails,
    required this.colorIndex,
    required this.title,
  });

  final TeamMember? member;
  final Set<String> takenEmails;
  final int colorIndex;
  final String title;

  @override
  State<_MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<_MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.member?.name);
  late final _roleController = TextEditingController(text: widget.member?.role);
  late final _emailController =
      TextEditingController(text: widget.member?.email);

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
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
    final result = existing == null
        ? TeamMember(
            name: name,
            role: role,
            email: email,
            colorIndex: widget.colorIndex,
          )
        : existing.copyWith(name: name, role: role, email: email);
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: const InputDecoration(labelText: 'Email'),
                validator: _validateEmail,
                onFieldSubmitted: (_) => _submit(),
              ),
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
