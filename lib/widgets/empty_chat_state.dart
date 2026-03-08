import 'package:flutter/material.dart';
import 'prompt_input.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/chat_provider.dart';
import '../core/config.dart';

/// **EmptyChatState** - Welcome screen for new conversations
///
/// This widget appears when no conversation is selected or when the selected
/// conversation has no messages yet. It provides an inviting entry point
/// for starting new conversations with a centered prompt input.
///
/// ## Key Features:
/// - **Welcoming Interface**: Clean, centered design for first impression
/// - **Immediate Interaction**: Full-featured input ready for first message
/// - **Model Selection**: Users can choose AI model before starting chat
/// - **Auto-Conversation Creation**: Creates new conversation on first message
/// - **Responsive Design**: Adapts layout for different screen sizes
///
/// ## User Experience:
/// - **Zero Friction**: No setup required - just start typing
/// - **Clear Intent**: Obvious call-to-action for beginning conversation
/// - **Feature Discovery**: Shows available models and capabilities upfront
/// - **Seamless Transition**: Smooth flow from empty state to active conversation
///
/// ## State Integration:
/// - Watches `ChatProvider` for model selection state
/// - Automatically creates conversation on first message submit
/// - Integrates with same model selection as sidebar
/// - Maintains consistency with main chat interface
///
/// ## Layout Structure:
/// ```
/// Centered Container (max width 850px)
/// └── Vertical Column
///     ├── PromptInputComplete (with model selector)
///     └── Spacing (60px bottom margin)
/// ```
///
/// ## Customization Examples:
/// ```dart
/// // Add welcome message:
/// class WelcomeEmptyChatState extends EmptyChatState {
///   @override
///   Widget build(BuildContext context) {
///     return Column([
///       Text('Welcome to AI Chat!', style: Theme.of(context).textTheme.headlineMedium),
///       SizedBox(height: 24),
///       super.build(context),
///     ]);
///   }
/// }
///
/// // Add suggested prompts:
/// class SuggestedEmptyChatState extends EmptyChatState {
///   final List<String> suggestedPrompts;
///
///   Widget _buildSuggestedPrompts() => Wrap(
///     children: suggestedPrompts.map((prompt) =>
///       ActionChip(
///         label: Text(prompt),
///         onPressed: () => _startChatWithPrompt(prompt),
///       )
///     ).toList(),
///   );
/// }
///
/// // Add template gallery:
/// class TemplateEmptyChatState extends EmptyChatState {
///   final List<ChatTemplate> templates;
///
///   Widget _buildTemplateCards() {
///     // Show conversation starter templates
///   }
/// }
/// ```
class EmptyChatState extends StatelessWidget {
  const EmptyChatState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 850),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return PromptInputComplete(
                  modelId: chatProvider.currentModelId,
                  models: AppConfig.availableModels,
                  onModelChanged: (String newModelId) {
                    chatProvider.setModel(newModelId);
                  },
                  onAddAttachment: () {
                    // TODO: Implement file attachment
                  },
                  // When submitting from empty state, start a new chat
                  onSubmit: (prompt, modelId) {
                    // If no conversation, create one before sending
                    if (chatProvider.selectedConversationId == null) {
                      chatProvider.createNewConversation();
                    }
                    chatProvider.sendMessage(prompt, modelId);
                  },
                );
              },
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
