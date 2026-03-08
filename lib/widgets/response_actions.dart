import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// **ResponseActions** - Interactive action buttons for AI assistant messages
///
/// Provides a horizontal row of action buttons that appear below AI responses,
/// enabling users to interact with and provide feedback on AI messages.
/// These actions help improve user experience and gather usage data.
///
/// ## Available Actions:
/// - **Copy**: Copy message content to clipboard (built-in functionality)
/// - **Thumbs Up/Down**: Feedback on response quality (callback-based)
/// - **Share**: Share message content (callback-based)
///
/// ## UI Behavior:
/// - **Hover Effects**: Buttons become visible/prominent on message hover
/// - **Copy Feedback**: Visual confirmation when content is copied
/// - **Responsive**: Adapts button spacing based on available width
/// - **Accessibility**: Proper tooltips and keyboard navigation
///
/// ## State Management:
/// - Built-in copy state management with auto-reset after 2 seconds
/// - Callback-based for external actions (thumbs up/down, sharing)
/// - No dependency on providers - purely callback-driven
///
/// ## Integration Pattern:
/// ```dart
/// // In MessageView:
/// ResponseActions(
///   messageContent: message.content,
///   onThumbsUp: () => analyticsService.recordFeedback(message.id, 'positive'),
///   onThumbsDown: () => showFeedbackDialog(message),
///   onShare: () => shareContent(message.content),
/// )
/// ```
///
/// ## Customization Examples:
/// ```dart
/// // Add regenerate action:
/// class ExtendedResponseActions extends ResponseActions {
///   final VoidCallback? onRegenerate;
///
///   @override
///   Widget build(BuildContext context) {
///     return Row([
///       IconButton(icon: Icon(LucideIcons.refresh), onPressed: onRegenerate),
///       ...super.build(context).children,
///     ]);
///   }
/// }
///
/// // Add bookmark action:
/// class BookmarkResponseActions extends ResponseActions {
///   final bool isBookmarked;
///   final VoidCallback? onToggleBookmark;
///
///   Widget _buildBookmarkButton() => IconButton(
///     icon: Icon(isBookmarked ? LucideIcons.bookmark : LucideIcons.bookmarkPlus),
///     onPressed: onToggleBookmark,
///   );
/// }
/// ```
class ResponseActions extends StatefulWidget {
  final String messageContent;
  final VoidCallback? onThumbsUp;
  final VoidCallback? onThumbsDown;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  const ResponseActions({
    super.key,
    required this.messageContent,
    this.onThumbsUp,
    this.onThumbsDown,
    this.onCopy,
    this.onShare,
  });

  @override
  State<ResponseActions> createState() => _ResponseActionsState();
}

class _ResponseActionsState extends State<ResponseActions> {
  bool _copied = false;

  void _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.messageContent));
    setState(() {
      _copied = true;
    });
    widget.onCopy?.call();

    // Reset the copied state after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: LucideIcons.refreshCw,
          tooltip: 'Regenerate',
          onPressed: () {
            // TODO: Implement regenerate functionality
          },
        ),
        const SizedBox(width: 4),
        _ActionButton(
          icon: LucideIcons.thumbsUp,
          tooltip: 'Good response',
          onPressed: widget.onThumbsUp,
        ),
        const SizedBox(width: 4),
        _ActionButton(
          icon: LucideIcons.thumbsDown,
          tooltip: 'Poor response',
          onPressed: widget.onThumbsDown,
        ),
        const SizedBox(width: 4),
        _ActionButton(
          icon: _copied ? LucideIcons.check : LucideIcons.copy,
          tooltip: _copied ? 'Copied!' : 'Copy',
          onPressed: _handleCopy,
        ),
        const SizedBox(width: 4),
        _ActionButton(
          icon: LucideIcons.share,
          tooltip: 'Share',
          onPressed: widget.onShare,
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: widget.onPressed,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.08)
                  : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
