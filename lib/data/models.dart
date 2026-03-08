/// **Core Data Models for AI Chat Template**
///
/// This file defines the fundamental data structures that power the chat application.
/// All models are designed to be simple, serializable, and extensible.

/// Defines whether a message comes from the user or AI assistant
enum MessageRole { user, assistant }

/// **Message** - Core chat message model
///
/// Represents a single message in a conversation thread. Messages are immutable
/// and contain all necessary metadata for rendering and persistence.
///
/// ## Design Notes:
/// - `content` supports Markdown formatting for rich text rendering
/// - `id` should be unique within the conversation scope
/// - `timestamp` enables proper message ordering and time displays
///
/// ## Extension Examples:
/// ```dart
/// // Add message metadata:
/// class ExtendedMessage extends Message {
///   final Map<String, dynamic>? metadata;
///   final List<String>? attachments;
/// }
///
/// // Add message reactions:
/// class ReactableMessage extends Message {
///   final Map<String, int> reactions;
/// }
/// ```
class Message {
  final String id;
  final MessageRole role;
  final String content; // markdown/plaintext; rich parts later
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

/// **Conversation** - Container for a chat thread
///
/// Groups related messages together and maintains conversation metadata.
/// Conversations are mutable to support real-time updates during chat.
///
/// ## Usage Pattern:
/// - Create new conversations via `ChatProvider.createNewConversation()`
/// - Messages are appended during chat interactions
/// - `title` is auto-generated from first message or can be customized
/// - `lastUpdated` drives conversation sorting in sidebar
///
/// ## Extension Ideas:
/// ```dart
/// // Add conversation settings:
/// class ExtendedConversation extends Conversation {
///   final String? systemPrompt;
///   final Map<String, dynamic>? settings;
/// }
///
/// // Add sharing and collaboration:
/// class SharedConversation extends Conversation {
///   final List<String> participantIds;
///   final bool isPublic;
/// }
/// ```
class Conversation {
  final String id;
  String title; // Mutable - auto-generated or user-customized
  final List<Message> messages; // Mutable - messages added during chat
  DateTime lastUpdated; // Mutable - updated on each interaction

  Conversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.lastUpdated,
  });
}

class SourceLink {
  final String id;
  final String title;
  final String url;
  final String snippet;
  const SourceLink({
    required this.id,
    required this.title,
    required this.url,
    required this.snippet,
  });
}

class ModelInfo {
  final String id;
  final String label;
  const ModelInfo({required this.id, required this.label});
}

enum TaskStatus { pending, inProgress, complete, failed }

class TaskItem {
  final String id;
  final String title;
  final TaskStatus status;
  final double progress; // 0..1
  final String? details;
  const TaskItem({
    required this.id,
    required this.title,
    this.status = TaskStatus.pending,
    this.progress = 0.0,
    this.details,
  });
}

class ToolUiPart {
  final String type;
  final String title;
  final String content;
  const ToolUiPart({
    required this.type,
    required this.title,
    required this.content,
  });
}

/// **ChatStatus** - Tracks the current state of chat interactions
///
/// Used by `ChatProvider` and UI widgets to coordinate loading states,
/// disable inputs during processing, and show appropriate indicators.
///
/// ## States:
/// - `idle`: Ready for new messages
/// - `submitting`: Processing user input (brief state)
/// - `streaming`: Receiving AI response in real-time
/// - `error`: Failed interaction (temporary state)
///
/// ## Usage in Widgets:
/// ```dart
/// // Disable send button during processing:
/// final isProcessing = chatProvider.status != ChatStatus.idle;
///
/// // Show loading indicator:
/// if (chatProvider.status == ChatStatus.streaming) {
///   return LoadingIndicator();
/// }
///
/// // Show error state:
/// if (chatProvider.status == ChatStatus.error) {
///   return ErrorWidget();
/// }
/// ```
enum ChatStatus { idle, submitting, streaming, error }
