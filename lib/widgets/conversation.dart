import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/chat_provider.dart';
import 'message.dart';

/// **ConversationView** - Scrollable message display with auto-scroll management
///
/// This widget renders the main conversation area where messages appear.
/// It handles intelligent scrolling, loading states, and provides a smooth
/// chat experience with proper message spacing and flow.
///
/// ## Key Features:
/// - **Auto-Scroll**: Automatically scrolls to bottom for new messages
/// - **Smart Scrolling**: Detects user scrolling and preserves position when needed
/// - **Scroll-to-Bottom FAB**: Appears when user scrolls up from recent messages
/// - **Loading Integration**: Listens to ChatProvider streaming state
/// - **Message Rendering**: Uses MessageView for consistent message presentation
///
/// ## Scrolling Behavior:
/// - **New Messages**: Automatically scrolls to bottom
/// - **User Scroll**: Preserves scroll position, shows scroll-to-bottom button
/// - **Streaming Responses**: Follows AI response as it streams in
/// - **Performance**: Efficient ListView with proper item builders
///
/// ## State Management:
/// - Watches `ChatProvider.messages` for conversation updates
/// - Automatically responds to new messages and streaming states
/// - Manages scroll controller and position detection
/// - Triggers UI updates for scroll indicators
///
/// ## Customization Examples:
/// ```dart
/// // Add message grouping:
/// class GroupedConversationView extends ConversationView {
///   Widget _buildMessageGroup(List<Message> consecutiveMessages) {
///     // Group consecutive messages from same sender
///   }
/// }
///
/// // Add message search:
/// class SearchableConversationView extends ConversationView {
///   final String? searchQuery;
///
///   @override
///   Widget _buildMessage(Message message) {
///     return HighlightedMessageView(
///       message: message,
///       searchQuery: searchQuery,
///     );
///   }
/// }
///
/// // Add infinite scroll:
/// class PaginatedConversationView extends ConversationView {
///   final Function()? onLoadMoreMessages;
///
///   @override
///   Widget build(BuildContext context) {
///     return NotificationListener<ScrollNotification>(
///       onNotification: _handleScrollForPagination,
///       child: super.build(context),
///     );
///   }
/// }
/// ```
class ConversationView extends StatefulWidget {
  const ConversationView({super.key});

  @override
  State<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final isAtBottom =
        _scrollController.offset >=
        _scrollController.position.maxScrollExtent - 100;

    if (_showScrollToBottom == isAtBottom) {
      setState(() {
        _showScrollToBottom = !isAtBottom;
      });
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messages = chatProvider.messages;

        // Auto-scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollToBottom();
          }
        });

        if (messages.isEmpty) {
          return const Center(
            child: Text(
              'No messages yet. Start a conversation!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + 1,
              itemBuilder: (context, index) {
                // Add extra space at the bottom as the last item
                if (index == messages.length) {
                  return const SizedBox(height: 60);
                }

                return Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: MessageView(message: messages[index]),
                    ),
                  ),
                );
              },
            ),
            if (_showScrollToBottom)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: _scrollToBottom,
                  splashColor: Colors.transparent,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
          ],
        );
      },
    );
  }
}
