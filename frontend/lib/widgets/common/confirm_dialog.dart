import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../buttons/app_button.dart';

/// Shared confirmation dialog used before leaving an active interview.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (destructive ? AppColors.danger : AppColors.primary)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppTokens.r3),
                  ),
                  child: Icon(
                    destructive
                        ? Icons.logout_rounded
                        : Icons.info_outline_rounded,
                    size: 19,
                    color: destructive ? AppColors.danger : AppColors.primaryBright,
                  ),
                ),
                const SizedBox(width: AppTokens.s3),
                Expanded(child: Text(title, style: AppTypography.title)),
              ],
            ),
            const SizedBox(height: AppTokens.s4),
            Text(message, style: AppTypography.body),
            const SizedBox(height: AppTokens.s6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: cancelLabel,
                  variant: ButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: AppTokens.s3),
                AppButton(
                  label: confirmLabel,
                  variant: destructive ? ButtonVariant.danger : ButtonVariant.primary,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
