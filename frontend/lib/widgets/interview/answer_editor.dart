import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../buttons/app_button.dart';

/// Large professional answer editor.
///
/// Supports Ctrl+Enter to submit, clear action and a word counter.
class AnswerEditor extends StatefulWidget {
  const AnswerEditor({
    super.key,
    required this.onSubmit,
    this.enabled = true,
    this.busy = false,
    this.autofocus = true,
  });

  final ValueChanged<String> onSubmit;
  final bool enabled;
  final bool busy;

  /// Autofocus only on desktop-class screens (set by the parent).
  final bool autofocus;

  @override
  State<AnswerEditor> createState() => _AnswerEditorState();
}

class _AnswerEditorState extends State<AnswerEditor> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int get _wordCount {
    final t = _controller.text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && widget.enabled && !widget.busy) {
      widget.onSubmit(text);
    }
  }

  void _clear() {
    _controller.clear();
    _focusNode.requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),
      autofocus: false,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter) &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _submit();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: AppDecor.well(radius: AppTokens.r5),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              enabled: widget.enabled && !widget.busy,
              minLines: 9,
              maxLines: 16,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
              style: AppTypography.bodyLarge.copyWith(height: 1.7),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText:
                    'Explain your approach as if you were answering a senior engineer…\n'
                    'Structure matters: architecture, trade-offs, failure modes.',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                contentPadding: EdgeInsets.all(AppTokens.s4),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s3),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s2 + 2,
                  vertical: AppTokens.s1 + 1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppTokens.r2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shortcut_rounded, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Ctrl + Enter to submit',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_wordCount > 0)
                Text(
                  '$_wordCount words',
                  style: AppTypography.caption,
                ),
              const SizedBox(width: AppTokens.s3),
              AppButton(
                label: 'Clear',
                variant: ButtonVariant.ghost,
                icon: Icons.delete_outline_rounded,
                onPressed: widget.busy ? null : _clear,
              ),
              const SizedBox(width: AppTokens.s2),
              AppButton(
                label: 'Submit Answer',
                icon: Icons.arrow_upward_rounded,
                loading: widget.busy,
                onPressed: widget.busy ? null : _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
