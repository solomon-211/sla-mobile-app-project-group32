import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Show / hide button placed inside a password field (Sign In, Register).
class PasswordToggle extends StatelessWidget {
  const PasswordToggle({
    super.key,
    required this.obscured,
    required this.onPressed,
  });

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: Tooltip(
        message: obscured ? 'Show password' : 'Hide password',
        child: Material(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 44,
              child: Icon(
                obscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
