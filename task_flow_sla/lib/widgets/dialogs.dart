import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pill_buttons.dart';

/// Asks the user to confirm an action. Returns true only when confirmed.
///
/// Shown as a card at the bottom of the screen (the delete-dialog design),
/// so the buttons sit where the thumb already is.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
  IconData? icon,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x8C0F120F),
    builder: (dialogContext) => Dialog(
      alignment: Alignment.bottomCenter,
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: destructive ? AppColors.coralBg : AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ??
                    (destructive
                        ? Icons.delete_outline_rounded
                        : Icons.help_outline_rounded),
                size: 22,
                color: destructive ? AppColors.coralDeep : AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppText.sora(22)),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppText.manrope(
                14,
                color: AppColors.textMuted,
                height: 21,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinePillButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(dialogContext, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: destructive
                            ? AppColors.error
                            : AppColors.ink,
                        foregroundColor: destructive
                            ? AppColors.surface
                            : AppColors.paper,
                      ),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(confirmLabel),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return confirmed ?? false;
}

/// Asks for one line of text, e.g. a new project name. Returns the trimmed
/// text, or null if cancelled.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String initialValue,
  required FormFieldValidator<String> validator,
  int? maxLength,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextInputDialog(
      title: title,
      label: label,
      initialValue: initialValue,
      validator: validator,
      maxLength: maxLength,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.validator,
    required this.maxLength,
  });

  final String title;
  final String label;
  final String initialValue;
  final FormFieldValidator<String> validator;
  final int? maxLength;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: widget.maxLength,
          textCapitalization: TextCapitalization.sentences,
          // Grey fill so the field stands out on the white dialog.
          decoration: InputDecoration(
            labelText: widget.label,
            fillColor: AppColors.surfaceMuted,
          ),
          validator: widget.validator,
          onFieldSubmitted: (_) => _submit(),
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

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Prints an error to the debug console so failures are not silently lost.
void logError(String what, Object error, StackTrace stack) {
  debugPrint('$what: $error\n$stack');
}

/// Runs a database write, then shows [success] or a friendly error message.
/// Used by every screen that saves something from a menu or dialog.
Future<void> runWithFeedback(
  BuildContext context,
  Future<void> Function() action, {
  required String success,
  String failure = 'Could not save the change.',
}) async {
  try {
    await action();
    if (context.mounted) showMessage(context, success);
  } catch (error, stack) {
    logError(failure, error, stack);
    if (context.mounted) showMessage(context, failure);
  }
}

/// Centered card for empty lists and load errors.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: AppText.sora(18)),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppText.manrope(14, color: AppColors.textMuted),
                ),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
