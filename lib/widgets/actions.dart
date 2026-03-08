import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// **ActionsBar** - Comprehensive action buttons for message interactions
///
/// Provides a full suite of interaction buttons for AI responses including
/// retry, feedback, copy, and sharing actions. This widget serves as an
/// alternative to `ResponseActions` with additional retry functionality.
///
/// ## Available Actions:
/// - **Retry**: Regenerate the AI response (refresh icon)
/// - **Like/Dislike**: Thumbs up/down feedback buttons
/// - **Copy**: Copy message content to clipboard
/// - **Share**: Share message content externally
///
/// ## Usage Pattern:
/// This widget is typically used in message containers where all actions
/// are needed. For simpler use cases, consider `ResponseActions` instead.
///
/// ## Integration Example:
/// ```dart
/// // In extended MessageView:
/// ActionsBar(
///   onRetry: () => chatProvider.regenerateResponse(message.id),
///   onLike: () => feedbackService.recordPositive(message.id),
///   onDislike: () => feedbackService.recordNegative(message.id),
///   onCopy: () => Clipboard.setData(ClipboardData(text: message.content)),
///   onShare: () => Share.share(message.content),
/// )
/// ```
///
/// ## Customization Examples:
/// ```dart
/// // Add edit action:
/// class EditableActionsBar extends ActionsBar {
///   final VoidCallback? onEdit;
///
///   @override
///   List<Widget> get actions => [
///     IconButton(icon: Icon(LucideIcons.edit), onPressed: onEdit),
///     ...super.actions,
///   ];
/// }
///
/// // Add analytics tracking:
/// class TrackedActionsBar extends ActionsBar {
///   @override
///   void onRetry() {
///     analytics.track('message_retry');
///     widget.onRetry?.call();
///   }
/// }
/// ```
class ActionsBar extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  const ActionsBar({
    super.key,
    this.onRetry,
    this.onLike,
    this.onDislike,
    this.onCopy,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(LucideIcons.refreshCw, size: 16),
          onPressed: onRetry,
          tooltip: 'Retry',
        ),
        IconButton(
          icon: const Icon(LucideIcons.thumbsUp, size: 16),
          onPressed: onLike,
          tooltip: 'Like',
        ),
        IconButton(
          icon: const Icon(LucideIcons.thumbsDown, size: 16),
          onPressed: onDislike,
          tooltip: 'Dislike',
        ),
        IconButton(
          icon: const Icon(LucideIcons.copy, size: 16),
          onPressed: onCopy,
          tooltip: 'Copy',
        ),
        IconButton(
          icon: const Icon(LucideIcons.share, size: 16),
          onPressed: onShare,
          tooltip: 'Share',
        ),
      ],
    );
  }
}
