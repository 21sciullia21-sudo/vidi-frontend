import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../presentation/providers/chat_provider.dart';
import 'response.dart';
import 'response_actions.dart';
import 'loader.dart';

/// **MessageView** - Renders individual chat messages with role-based styling
///
/// This widget handles the visual presentation of both user and AI assistant messages.
/// It provides different styling, alignment, and interactive features based on the
/// message role, creating a clear conversation flow.
///
/// ## Message Types:
/// - **User Messages**: Right-aligned, primary color, simple text rendering
/// - **Assistant Messages**: Left-aligned, markdown support, interactive actions
///
/// ## Key Features:
/// - **Role-Based Styling**: Different visual treatment for user vs assistant
/// - **Markdown Rendering**: Rich text support for AI responses (via `ResponseWidget`)
/// - **Interactive Actions**: Copy, share, feedback buttons for assistant messages
/// - **Responsive Design**: Proper constraints and alignment for all screen sizes
/// - **Loading States**: Shows streaming indicator for incomplete responses
///
/// ## Integration Points:
/// - Uses `ResponseWidget` for markdown rendering and syntax highlighting
/// - Integrates `ResponseActions` for message interaction buttons
/// - Connects to `ChatProvider` for streaming status detection
/// - Follows theme colors for consistent visual hierarchy
///
/// ## Styling Patterns:
/// ```dart
/// // User messages:
/// - Right-aligned with left margin
/// - Primary container background
/// - Maximum width constraint (600px)
/// - Simple text rendering
///
/// // Assistant messages:
/// - Left-aligned with right margin
/// - Surface container background
/// - Markdown content rendering
/// - Action buttons (copy, feedback)
/// ```
///
/// ## Customization Examples:
/// ```dart
/// // Add message timestamps:
/// class TimestampedMessageView extends MessageView {
///   @override
///   Widget _buildUserMessage(BuildContext context) {
///     return Column(
///       children: [
///         super._buildUserMessage(context),
///         Text(DateFormat.Hm().format(message.timestamp)),
///       ],
///     );
///   }
/// }
///
/// // Add avatar support:
/// class AvatarMessageView extends MessageView {
///   final String? userAvatarUrl;
///   final Widget? assistantAvatar;
/// }
///
/// // Add message reactions:
/// class ReactionMessageView extends MessageView {
///   final Map<String, int> reactions;
///   final Function(String emoji) onReaction;
/// }
/// ```
class MessageView extends StatelessWidget {
  final Message message;
  const MessageView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    if (isUser) {
      return _buildUserMessage(context);
    } else {
      return _buildAssistantMessage(context);
    }
  }

  Widget _buildUserMessage(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(left: 48),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final isLastMessage =
            chatProvider.messages.isNotEmpty &&
            chatProvider.messages.last.id == message.id;
        final isStreaming =
            chatProvider.status == ChatStatus.streaming && isLastMessage;

        return Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Assistant label
              Text(
                'Assistant',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              // Message content with markdown rendering or streaming indicator
              if (isStreaming && message.content.isEmpty)
                _buildStreamingIndicator(context)
              else
                Response(markdown: message.content),

              // Show typing indicator if currently streaming this message
              if (isLastMessage &&
                  chatProvider.status == ChatStatus.streaming &&
                  message.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildTypingIndicator(context),
                ),

              const SizedBox(height: 12),
              // Action buttons (only show when not streaming or empty)
              if (!isStreaming && message.content.isNotEmpty)
                ResponseActions(
                  messageContent: message.content,
                  onThumbsUp: () {
                    // TODO: Implement feedback tracking
                    debugPrint('Thumbs up for message: ${message.id}');
                  },
                  onThumbsDown: () {
                    // TODO: Implement feedback tracking
                    debugPrint('Thumbs down for message: ${message.id}');
                  },
                  onCopy: () {
                    debugPrint('Copied message: ${message.id}');
                  },
                  onShare: () {
                    // TODO: Implement share functionality
                    debugPrint('Share message: ${message.id}');
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreamingIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 1.5),
            child: Loader(size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            'Thinking...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 1.5),
          child: Loader(size: 12),
        ),
        const SizedBox(width: 6),
        Text(
          'Generating...',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
