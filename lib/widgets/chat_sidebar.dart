import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../data/models.dart';
import '../presentation/providers/chat_provider.dart';

/// **ChatSidebar** - Navigation and conversation management panel
///
/// The sidebar provides access to conversation history, model selection, and
/// conversation management actions. It adapts between drawer (mobile) and
/// fixed sidebar (desktop) presentations.
///
/// ## Core Functions:
/// - **Conversation List**: Display and navigate between chat threads
/// - **Model Selection**: Dropdown for switching AI models
/// - **Conversation Actions**: Delete conversations, create new threads
/// - **Quick Access**: "New Chat" button for immediate conversation creation
///
/// ## UI Structure:
/// ```
/// Header (New Chat + Model Selector)
/// ├── New Chat Button
/// └── Model Dropdown
///
/// Conversation List (Scrollable)
/// ├── Active Conversation (highlighted)
/// ├── Previous Conversations
/// └── Delete Actions (swipe/hover)
/// ```
///
/// ## Responsive Behavior:
/// - **Mobile**: Displayed as a drawer (triggered by menu button)
/// - **Desktop**: Fixed sidebar with collapse/expand animation
/// - **Width**: Fixed 350px for consistent layout
///
/// ## State Integration:
/// - Watches `ChatProvider` for conversation updates
/// - Updates immediately when conversations are added/removed
/// - Highlights currently selected conversation
/// - Shows conversation counts and last update times
///
/// ## Customization Examples:
/// ```dart
/// // Add conversation search:
/// class SearchableChatSidebar extends ChatSidebar {
///   final TextEditingController searchController;
///
///   List<Conversation> _filterConversations(List<Conversation> conversations) {
///     // Filter by search term
///   }
/// }
///
/// // Add conversation folders:
/// class FolderChatSidebar extends ChatSidebar {
///   final Map<String, List<Conversation>> conversationFolders;
///
///   @override
///   Widget _buildConversationList(BuildContext context) {
///     // Group conversations by folders
///   }
/// }
///
/// // Add conversation export:
/// class ExportableChatSidebar extends ChatSidebar {
///   Widget _buildConversationActions(Conversation conversation) {
///     return Row([
///       IconButton(icon: Icon(LucideIcons.download), onPressed: () => exportConversation()),
///       IconButton(icon: Icon(LucideIcons.trash), onPressed: () => deleteConversation()),
///     ]);
///   }
/// }
/// ```
class ChatSidebar extends StatelessWidget {
  final VoidCallback? onClose;

  const ChatSidebar({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 4),
          Expanded(child: _buildConversationList(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56, // Match the top bar height
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          if (onClose != null) ...[
            IconButton(
              onPressed: onClose,
              icon: const Icon(LucideIcons.panelLeft, size: 16),
              tooltip: 'Close sidebar',
              style: IconButton.styleFrom(
                splashFactory: NoSplash.splashFactory,
                backgroundColor: Colors.transparent,
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(30, 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ] else ...[
            const SizedBox(
              width: 8,
            ), // Align with main content when no close button
          ],
          Expanded(
            child: Text(
              'Chats',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              context.read<ChatProvider>().createNewConversation();
            },
            icon: const Icon(LucideIcons.plus, size: 18),
            tooltip: 'New Chat',
            style: IconButton.styleFrom(
              splashFactory: NoSplash.splashFactory,
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              padding: const EdgeInsets.all(5),
              minimumSize: const Size(30, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.conversations.isEmpty) {
          return const Center(
            child: Text(
              'No conversations yet',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: chatProvider.conversations.length,
          itemBuilder: (context, index) {
            final conversation = chatProvider.conversations[index];
            final isSelected =
                conversation.id == chatProvider.selectedConversationId;

            return _buildConversationItem(
              context,
              conversation,
              isSelected,
              () => chatProvider.selectConversation(conversation.id),
              () => chatProvider.deleteConversation(conversation.id),
            );
          },
        );
      },
    );
  }

  Widget _buildConversationItem(
    BuildContext context,
    Conversation conversation,
    bool isSelected,
    VoidCallback onTap,
    VoidCallback onDelete,
  ) {
    return _ConversationItem(
      conversation: conversation,
      isSelected: isSelected,
      onTap: onTap,
      onDelete: onDelete,
    );
  }
}

class _ConversationItem extends StatefulWidget {
  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationItem({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_ConversationItem> createState() => _ConversationItemState();
}

class _ConversationItemState extends State<_ConversationItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.5)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: ListTile(
          onTap: widget.onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
          title: Text(
            widget.conversation.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
              color: widget.isSelected
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _formatLastUpdated(widget.conversation.lastUpdated),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          trailing: widget.conversation.messages.isNotEmpty && _isHovered
              ? IconButton(
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSecondary.withValues(alpha: 0.6),
                  ),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete conversation',
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                )
              : null,
        ),
      ),
    );
  }

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}
