import 'package:flutter/foundation.dart';
import '../../data/models.dart';
import '../../data/services/thread_naming_service.dart';
import '../../core/config.dart';
import '../../data/repositories.dart';
import '../../data/services/openrouter_service.dart';

/// **ChatProvider** - Core state management for the AI chat application
///
/// This provider manages all chat-related state including conversations, messages,
/// streaming responses, and AI model selection. It follows the Repository pattern
/// to abstract away the specific AI service implementation.
///
/// ## Key Responsibilities:
/// - **Conversation Management**: Create, select, delete conversations
/// - **Message Handling**: Add user messages and stream AI responses
/// - **State Coordination**: Manage chat status (idle, streaming, error)
/// - **Model Selection**: Handle AI model switching
/// - **Real-time Streaming**: Coordinate streaming responses with UI updates
///
/// ## Architecture Notes:
/// - Uses Repository pattern via `ChatRepository` for service abstraction
/// - Handles both mock responses (no API key) and real AI responses
/// - Manages conversation persistence in memory (extend for database storage)
/// - Implements optimistic UI updates during streaming
///
/// ## Extension Points:
/// - **Custom Backends**: Implement new `ChatRepository` implementations
/// - **Persistence**: Add database storage by overriding conversation methods
/// - **Message Types**: Extend `Message` model for rich content (images, files)
/// - **State Persistence**: Add SharedPreferences or Hive for conversation persistence
///
/// ## Usage Example:
/// ```dart
/// // In your widget:
/// final chatProvider = context.watch<ChatProvider>();
///
/// // Send a message:
/// await chatProvider.sendMessage('Hello AI!', 'openai/gpt-4o-mini');
///
/// // Access current conversation:
/// final messages = chatProvider.messages;
/// final isStreaming = chatProvider.status == ChatStatus.streaming;
/// ```
class ChatProvider extends ChangeNotifier {
  final List<Conversation> _conversations = [];
  String? _selectedConversationId;
  ChatStatus _status = ChatStatus.idle;
  String _currentModelId = 'openai/gpt-4o-mini';
  final ThreadNamingService _namingService;
  final ChatRepository _chatRepository;

  // For canceling streaming requests
  bool _shouldCancelStream = false;

  /// Creates a new ChatProvider instance
  ///
  /// **Parameters:**
  /// - `namingService`: Optional custom service for generating thread names
  /// - `chatRepository`: Optional custom repository for AI interactions
  ///
  /// **Default Behavior:**
  /// - Uses `ThreadNamingService()` for automatic thread naming
  /// - Selects repository based on `AppConfig.backendProvider`:
  ///   - `direct`: OpenRouter client calls (dev only)
  ///   - `firebase`: Firebase Function proxy (production)
  ///   - `supabase`: Supabase Edge Function proxy (production)
  ChatProvider({
    ThreadNamingService? namingService,
    ChatRepository? chatRepository,
  }) : _namingService = namingService ?? ThreadNamingService(),
       _chatRepository = chatRepository ?? _defaultRepository();

  static ChatRepository _defaultRepository() {
    switch (AppConfig.backendProvider) {
      case BackendProvider.direct:
        return OpenRouterChatRepository(OpenRouterService());
      case BackendProvider.firebase:
        return FirebaseChatRepository(AppConfig.firebaseProxyUrl);
      case BackendProvider.supabase:
        return SupabaseChatRepository(AppConfig.supabaseEdgeFunctionUrl);
    }
  }

  List<Conversation> get conversations {
    // Sort conversations by lastUpdated, most recent first
    final sortedConversations = List<Conversation>.from(_conversations);
    sortedConversations.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    return sortedConversations;
  }

  String? get selectedConversationId => _selectedConversationId;
  ChatStatus get status => _status;
  String get currentModelId => _currentModelId;

  Conversation? get selectedConversation => _selectedConversationId != null
      ? _conversations.where((c) => c.id == _selectedConversationId).firstOrNull
      : null;

  List<Message> get messages => selectedConversation?.messages ?? [];

  void setStatus(ChatStatus status) {
    _status = status;
    notifyListeners();
  }

  void stopGeneration() {
    if (_status == ChatStatus.streaming) {
      _shouldCancelStream = true;
      _status = ChatStatus.idle;
      notifyListeners();
    }
  }

  void selectConversation(String? conversationId) {
    _selectedConversationId = conversationId;
    notifyListeners();
  }

  void createNewConversation() {
    final newConversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      messages: [],
      lastUpdated: DateTime.now(),
    );
    _conversations.add(newConversation);
    _selectedConversationId = newConversation.id;
    notifyListeners();
  }

  void setModel(String modelId) {
    _currentModelId = modelId;
    notifyListeners();
  }

  void deleteConversation(String conversationId) {
    _conversations.removeWhere((c) => c.id == conversationId);
    if (_selectedConversationId == conversationId) {
      _selectedConversationId = _conversations.isNotEmpty
          ? _conversations.first.id
          : null;
    }
    notifyListeners();
  }

  /// Sends a user message and generates an AI response
  ///
  /// **Core Flow:**
  /// 1. Validates input and prevents concurrent sends
  /// 2. Creates new conversation if none selected
  /// 3. Adds user message to conversation
  /// 4. Generates thread title (first message only)
  /// 5. Streams AI response in real-time
  ///
  /// **Parameters:**
  /// - `content`: User's message text (trimmed automatically)
  /// - `modelId`: AI model to use (e.g., 'openai/gpt-4o-mini')
  ///
  /// **State Changes:**
  /// - Updates `_status` to `streaming` during AI response
  /// - Modifies `_conversations` with new messages
  /// - Triggers `notifyListeners()` for UI updates
  ///
  /// **Error Handling:**
  /// - Network failures show error message in chat
  /// - API key issues trigger configuration prompts (or mock mode)
  /// - Streaming can be cancelled via `stopGeneration()`
  ///
  /// **Mock Mode:**
  /// When no API key is configured, generates realistic mock responses
  /// with simulated streaming delays for demonstration purposes.
  Future<void> sendMessage(String content, String modelId) async {
    if (content.trim().isEmpty) return;

    // Prevent duplicate sends
    if (_status != ChatStatus.idle) return;

    // Create conversation if none selected
    if (_selectedConversationId == null) {
      createNewConversation();
    }

    final conversation = selectedConversation;
    if (conversation == null) return;

    // 1. Add user message
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content.trim(),
      timestamp: DateTime.now(),
    );

    conversation.messages.add(userMessage);

    // Update conversation title if it's the first message
    if (conversation.messages.length == 1) {
      _generateTitle(content, conversation);
    }

    conversation.lastUpdated = DateTime.now();
    notifyListeners();

    // 2. Generate AI response
    await _generateAiResponse(conversation, modelId);
  }

  Future<void> _generateTitle(String content, Conversation conversation) async {
    try {
      // Use AI naming service for better titles
      final aiGeneratedTitle = await _namingService.generateThreadName(content);
      conversation.title = aiGeneratedTitle;
      conversation.lastUpdated = DateTime.now();
      notifyListeners();
    } catch (e) {
      // Fallback to simple title generation if AI service fails
      final words = content.split(' ');
      conversation.title = words.length <= 4
          ? content
          : '${words.take(4).join(' ')}...';
      notifyListeners();
    }
  }

  Future<void> _generateAiResponse(
    Conversation conversation,
    String modelId,
  ) async {
    _shouldCancelStream = false;
    setStatus(ChatStatus.streaming);
    notifyListeners();

    try {
      // Stream response via repository
      final responseStream = _chatRepository.streamChat(
        history: conversation.messages,
        modelId: modelId,
      );

      // Create AI message and start streaming into it
      final aiMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
      );

      conversation.messages.add(aiMessage);
      conversation.lastUpdated = DateTime.now();
      notifyListeners();

      String accumulatedContent = '';

      await for (final event in responseStream) {
        if (_shouldCancelStream) break;

        if (event is ResponseChunk) {
          accumulatedContent += event.text;
        } else if (event is ChatError) {
          throw Exception(event.message);
        } else if (event is Finished) {
          break;
        }

        // Update the AI message by replacing the last message
        conversation.messages[conversation.messages.length - 1] = Message(
          id: aiMessage.id,
          role: MessageRole.assistant,
          content: accumulatedContent,
          timestamp: aiMessage.timestamp,
        );
        notifyListeners();
      }

      if (_shouldCancelStream && accumulatedContent.isNotEmpty) {
        conversation.messages[conversation.messages.length - 1] = Message(
          id: aiMessage.id,
          role: MessageRole.assistant,
          content: '$accumulatedContent\n\n*[Response stopped by user]*',
          timestamp: aiMessage.timestamp,
        );
        notifyListeners();
      }
    } catch (e) {
      // Replace placeholder if it's still empty, otherwise add error message
      if (conversation.messages.isNotEmpty &&
          conversation.messages.last.role == MessageRole.assistant &&
          conversation.messages.last.content.isEmpty) {
        conversation.messages[conversation.messages.length - 1] = Message(
          id: conversation.messages.last.id,
          role: MessageRole.assistant,
          content:
              '❌ **Error**: ${e.toString()}\n\nPlease check your API key configuration and try again.',
          timestamp: DateTime.now(),
        );
      } else {
        final errorMessage = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.assistant,
          content:
              '❌ **Error**: ${e.toString()}\n\nPlease check your API key configuration and try again.',
          timestamp: DateTime.now(),
        );
        conversation.messages.add(errorMessage);
      }
    }

    setStatus(ChatStatus.idle);
    conversation.lastUpdated = DateTime.now();
    notifyListeners();
  }
}
