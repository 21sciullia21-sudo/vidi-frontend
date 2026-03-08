import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/prompt_input.dart';
import '../../widgets/conversation.dart';
import '../../widgets/chat_sidebar.dart';
import '../../widgets/empty_chat_state.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/config.dart';

/// **ChatPage** - Main layout and responsive container for the AI chat application
///
/// This is the root page component that orchestrates the entire chat experience.
/// It provides responsive layout management, sidebar navigation, and integrates
/// all major UI components into a cohesive interface.
///
/// ## Key Features:
/// - **Responsive Design**: Adapts between mobile drawer and desktop sidebar
/// - **Animated Transitions**: Smooth sidebar collapse/expand animations
/// - **Theme Integration**: Header with theme toggle button
/// - **Component Composition**: Combines sidebar, conversation, and input areas
/// - **Provider Integration**: Consumes `ChatProvider` and `ThemeProvider`
///
/// ## Layout Architecture:
/// ```
/// AppBar (theme toggle, title)
/// ├── Mobile: Drawer + Main Content
/// └── Desktop: Sidebar + Main Content
///     ├── ChatSidebar (conversations + models)
///     └── Content Area
///         ├── ConversationView OR EmptyState
///         └── PromptInput (always visible)
/// ```
///
/// ## Responsive Breakpoints:
/// - **Mobile** (< 768px): Drawer-based navigation
/// - **Desktop** (≥ 768px): Collapsible sidebar with animation
///
/// ## Customization Examples:
/// ```dart
/// // Add app bar actions:
/// actions: [
///   IconButton(
///     icon: Icon(LucideIcons.settings),
///     onPressed: () => showSettingsDialog(),
///   ),
///   // ... theme toggle
/// ]
///
/// // Customize sidebar behavior:
/// ChatSidebar(
///   showModelSelector: true,
///   enableConversationExport: true,
///   maxConversations: 50,
/// )
///
/// // Add floating action button:
/// floatingActionButton: FloatingActionButton(
///   onPressed: () => chatProvider.createNewConversation(),
///   child: Icon(LucideIcons.plus),
/// )
/// ```
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  bool _isSidebarCollapsed = true;
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      // On mobile, just open the drawer
      _scaffoldKey.currentState?.openDrawer();
    } else {
      // On desktop, use animated sidebar
      setState(() {
        _isSidebarCollapsed = !_isSidebarCollapsed;
      });

      if (_isSidebarCollapsed) {
        _sidebarAnimationController.reverse();
      } else {
        _sidebarAnimationController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768; // Mobile breakpoint

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? Drawer(
              width: 380,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: ChatSidebar(
                onClose: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _isSidebarCollapsed = true;
                  });
                },
              ),
            )
          : null,
      body: Row(
        children: [
          // Desktop sidebar
          if (!isMobile)
            AnimatedBuilder(
              animation: _sidebarAnimation,
              builder: (context, child) {
                return ClipRect(
                  child: SizeTransition(
                    sizeFactor: _sidebarAnimation,
                    axis: Axis.horizontal,
                    axisAlignment: -1,
                    child: ChatSidebar(onClose: _toggleSidebar),
                  ),
                );
              },
            ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, isMobile),
                Expanded(
                  child: Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      final hasSelectedChat =
                          chatProvider.selectedConversation != null;

                      if (!hasSelectedChat) {
                        return const EmptyChatState();
                      }

                      return _buildChatView(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isMobile) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            // Mobile: Always show menu button
            IconButton(
              onPressed: _toggleSidebar,
              icon: const Icon(LucideIcons.menu, size: 18),
              tooltip: 'Open sidebar',
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
          ] else ...[
            // Desktop: Animated menu button based on sidebar state
            AnimatedBuilder(
              animation: _sidebarAnimation,
              builder: (context, child) {
                final sidebarWidth = 280 * _sidebarAnimation.value;
                final showMenuButton =
                    sidebarWidth <
                    140; // Show menu when sidebar is mostly hidden

                if (showMenuButton) {
                  return IconButton(
                    onPressed: _toggleSidebar,
                    icon: const Icon(LucideIcons.menu, size: 18),
                    tooltip: 'Open sidebar',
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
                  );
                } else {
                  return const SizedBox(
                    width: 8,
                  ); // Spacing when sidebar is open
                }
              },
            ),
          ],
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final conversation = chatProvider.selectedConversation;
                if (conversation == null) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.title,
                          style:
                              Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Text(
                        '${conversation.messages.length} messages',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final IconData themeIcon;
              switch (themeProvider.themeMode) {
                case ThemeMode.system:
                  themeIcon = LucideIcons.monitor;
                  break;
                case ThemeMode.light:
                  themeIcon = LucideIcons.sun;
                  break;
                case ThemeMode.dark:
                  themeIcon = LucideIcons.moon;
                  break;
              }

              return IconButton(
                onPressed: () => themeProvider.toggleThemeMode(),
                icon: Icon(
                  themeIcon,
                  size: 18,
                ),
                tooltip: _getThemeTooltip(themeProvider.themeMode),
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatView(BuildContext context) {
    return Column(
      children: [
        const Expanded(child: ConversationView()),
        // Constrain suggestions and prompt input to max width
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return PromptInputComplete(
                  status: chatProvider.status,
                  modelId: chatProvider.currentModelId,
                  models: AppConfig.availableModels,
                  onSubmit: (prompt, modelId) {
                    chatProvider.sendMessage(prompt, modelId);
                  },
                  onStop: () {
                    chatProvider.stopGeneration();
                  },
                  onModelChanged: (String newModelId) {
                    chatProvider.setModel(newModelId);
                  },
                  onAddAttachment: () {
                    // TODO: Implement file attachment
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _getThemeTooltip(ThemeMode currentMode) {
    switch (currentMode) {
      case ThemeMode.system:
        return 'Switch to light theme';
      case ThemeMode.light:
        return 'Switch to dark theme';
      case ThemeMode.dark:
        return 'Switch to system theme';
    }
  }
}
