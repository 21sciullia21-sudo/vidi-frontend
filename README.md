# AI Chat Template

An AI chat application template built with Flutter Web. Features clean architecture, dual-mode operation (mock/real AI), responsive design, and extensive customization options.

## 🚀 **Quick Start**

### **Instant Demo** (0 setup required)

The template works immediately with realistic mock responses - no API key needed!

### **Real AI Integration** (30 seconds)
1. Get your free API key from [OpenRouter.ai](https://openrouter.ai)
2. Add it to `lib/core/config.dart`:
   ```dart
   static const String testingOnlyOpenRouterApiKey = 'your-key-here';
   ```
3. Start chatting with 20+ AI models!

---

## 🏗️ **Architecture Overview**

### **Design Philosophy**
- **Demo-First**: Works out-of-the-box with no configuration
- **Security-Aware**: Safe patterns for development and production
- **Extension-Friendly**: Clear patterns for adding features
- **Provider-Based**: Reactive state management with clean separation

### **Layer Structure**
```
🎨 UI Layer (widgets/)
├── Layout: ChatPage, ChatSidebar, ConversationView
├── Messages: MessageView, Response, CodeBlock  
├── Input: PromptInput, PromptInputComplete
└── States: EmptyChatState, Loader

🧠 State Layer (presentation/)
├── ChatProvider (conversations, messages, streaming)
└── ThemeProvider (system/light/dark theme switching)

📡 Service Layer (data/)
├── Repositories (ChatRepository pattern for backend abstraction)
├── Services (OpenRouterService, ThreadNamingService, MockResponsesService)
└── Models (Message, Conversation, ChatStatus)

⚙️ Core Layer (core/)
└── AppConfig (API keys, backend selection, model configuration)
```

---

## 🎮 **Operation Modes**

### **🎭 Demo Mode** (Default - No API Key)
- **Instant Start**: Template works immediately with realistic mock responses
- **Full Feature Demo**: Streaming responses, theme switching, conversation management
- **Educational**: Mock responses explain template features and setup process
- **Perfect For**: Template previews, UI testing, client demonstrations

### **🧪 Development Mode** (API Key Configured)
- **Real AI**: Connect to 20+ models via OpenRouter.ai
- **Two Setup Options**:
  - **Quick**: Add key to `testingOnlyOpenRouterApiKey` in config.dart (never commit!)
  - **Secure**: Use `flutter run --dart-define=OPENROUTER_API_KEY=your_key`
- **Full Features**: Streaming responses, automatic thread naming, model switching

### **🚀 Production Mode** (Backend Proxy)
- **Security First**: API keys stored safely on backend servers
- **Backend Options**: Firebase Functions, Supabase Edge Functions, or custom proxy
- **Configuration**: Set `backendProvider` and configure proxy URLs in AppConfig
- **Scalable**: Ready for multi-user, high-traffic deployment

---

## 🧩 **Core Components**

### **ChatProvider** - State Management Hub
The central coordinator for all chat functionality:
- **Conversation Management**: Create, select, delete conversations
- **Message Handling**: Send messages and stream AI responses  
- **Status Coordination**: Track idle/streaming/error states
- **Model Selection**: Switch between AI models dynamically

**Key Methods:**
```dart
await chatProvider.sendMessage('Hello!', 'openai/gpt-4o-mini');
chatProvider.createNewConversation();
chatProvider.stopGeneration(); // Cancel streaming response
```

### **Repository Pattern** - Backend Abstraction
Clean abstraction for different AI service backends:
- **Direct Mode**: `OpenRouterChatRepository` for development
- **Firebase Mode**: `FirebaseChatRepository` for serverless production
- **Supabase Mode**: `SupabaseChatRepository` for alternative backend
- **Custom**: Implement `ChatRepository` for any backend

**Extension Example:**
```dart
class MyCustomChatRepository implements ChatRepository {
  @override
  Stream<ChatEvent> streamChat({required List<Message> history, required String modelId}) async* {
    // Your custom AI service integration here
    yield* myService.streamResponse(history).map(ResponseChunk.new);
    yield Finished();
  }
}
```

### **MockResponsesService** - Demo Mode Engine
Provides realistic demo experience without API requirements:
- **Streaming Simulation**: Word-by-word delivery with realistic delays
- **Diverse Content**: Pool of educational responses about template features
- **Thread Naming**: Generates realistic conversation titles
- **Seamless Integration**: Indistinguishable from real AI in UI

---

## 🎨 **Widget Architecture**

### **Component Hierarchy**
```
ChatPage (responsive layout)
├── AppBar (theme toggle + title)
├── ChatSidebar (conversations + models)
└── Main Content
    ├── ConversationView (message display)
    │   └── MessageView (individual messages)
    │       ├── Response (markdown rendering)
    │       │   └── CodeBlock (syntax highlighting)
    │       └── ResponseActions (copy, feedback)
    └── PromptInputComplete (user input + model selection)

EmptyChatState (welcome screen)
└── PromptInputComplete (centered input)
```

### **Widget Categories**

#### **🏗️ Layout & Navigation**
- **`ChatPage`**: Responsive layout with mobile drawer / desktop sidebar
- **`ChatSidebar`**: Conversation management and model selection
- **`ConversationView`**: Auto-scrolling message display with scroll-to-bottom

#### **💬 Message Display**
- **`MessageView`**: Role-based styling (user vs assistant messages)
- **`Response`**: Full markdown rendering with theme integration
- **`CodeBlock`**: Syntax highlighting with copy-to-clipboard functionality

#### **⌨️ User Interaction**
- **`PromptInputComplete`**: Full-featured input with model selector and shortcuts
- **`ResponseActions`**: Message actions (copy, thumbs up/down, share)
- **`EmptyChatState`**: Welcoming onboarding screen

#### **🎭 States & Feedback**
- **`Loader`**: Smooth spinning animation for loading states
- **Theme Integration**: All components respect light/dark/system themes

---

## 🔧 **Customization Guide**

### **Quick Customizations**

#### **Change App Branding**
```dart
// In main.dart:
MaterialApp(
  title: 'My AI Assistant', // Browser tab title
  // ... rest of config
)

// In AppConfig:
static const String appName = 'My AI Assistant';
```

#### **Add New AI Models**
```dart
// In AppConfig:
static const List<String> availableModels = [
  'openai/gpt-4o-mini',
  'anthropic/claude-3.5-sonnet', // Add new models here
  'my-custom/model-id',
];

static const Map<String, String> modelDisplayNames = {
  'my-custom/model-id': 'My Custom Model', // Add display names
};
```

#### **Customize Theme Colors**
```dart
// In theme.dart - modify the color constants:
class LightColors {
  static const primary = Color(0xFF6366F1); // Change to your brand color
  static const background = Color(0xFFFAFAFA); // Adjust background
  // ... other colors
}
```

### **Advanced Customizations**

#### **Add Message Persistence**
```dart
// Extend ChatProvider:
class PersistentChatProvider extends ChatProvider {
  late final HiveBox<Conversation> _conversationBox;
  
  @override
  List<Conversation> get conversations => _conversationBox.values.toList();
  
  @override
  void createNewConversation() {
    final conversation = Conversation(/* ... */);
    _conversationBox.put(conversation.id, conversation);
    super.createNewConversation();
  }
}
```

#### **Add Message Reactions**
```dart
// Extend Message model:
class ReactableMessage extends Message {
  final Map<String, int> reactions;
  const ReactableMessage({required super.id, /* ... */, this.reactions = const {}});
}

// Extend MessageView:
class ReactableMessageView extends MessageView {
  Widget _buildReactions() => Wrap(
    children: message.reactions.entries.map((entry) =>
      Chip(label: Text('${entry.key} ${entry.value}'))
    ).toList(),
  );
}
```

#### **Add File Attachments**
```dart
// Extend PromptInputComplete:
class FileAttachmentPromptInput extends PromptInputComplete {
  @override
  Widget _buildAttachmentButton() => IconButton(
    icon: Icon(LucideIcons.paperclip),
    onPressed: () async {
      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        _attachFile(result.files.first);
      }
    },
  );
}
```

### **Backend Integration Examples**

#### **Firebase Functions Proxy**
```dart
// In repositories.dart:
class FirebaseChatRepository implements ChatRepository {
  @override
  Stream<ChatEvent> streamChat({required List<Message> history, required String modelId}) async* {
    final response = await FirebaseFunctions.instance
        .httpsCallable('chatCompletion')
        .call({'messages': history.map((m) => m.toJson()).toList(), 'model': modelId});
    
    yield* _parseServerSentEvents(response.data['stream']);
  }
}
```

#### **Custom Backend Integration**
```dart
// Custom service implementation:
class MyAIServiceRepository implements ChatRepository {
  @override
  Stream<ChatEvent> streamChat({required List<Message> history, required String modelId}) async* {
    final request = http.Request('POST', Uri.parse('$baseUrl/chat/completions'));
    request.body = jsonEncode({
      'messages': history.map((m) => {'role': m.role.name, 'content': m.content}).toList(),
      'model': modelId,
      'stream': true,
    });
    
    final streamedResponse = await http.Client().send(request);
    yield* streamedResponse.stream
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .where((line) => line.startsWith('data: '))
        .map((line) => line.substring(6))
        .where((data) => data != '[DONE]')
        .map((data) => jsonDecode(data))
        .map((json) => ResponseChunk(json['choices'][0]['delta']['content'] ?? ''));
  }
}
```

---

## 📚 **File Structure & Responsibilities**

### **🧠 Core Components (`lib/core/`, `lib/data/`)**

#### **`lib/core/config.dart`** - Central Configuration
- **API Keys**: Development and production key management
- **Backend Selection**: Switch between direct/Firebase/Supabase modes
- **Model Configuration**: Available AI models and display names
- **Security Patterns**: Safe defaults with clear production guidance

#### **`lib/data/models.dart`** - Data Structures
- **`Message`**: Chat message with role, content, timestamp
- **`Conversation`**: Message container with title and metadata
- **`ChatStatus`**: State tracking (idle, streaming, error)
- **Extension Points**: Examples for rich content, reactions, sharing

#### **`lib/data/services/`** - External Integrations
- **`OpenRouterService`**: Direct AI API client with mock fallback
- **`ThreadNamingService`**: Automatic conversation title generation
- **`MockResponsesService`**: Realistic demo responses with streaming simulation

#### **`lib/data/repositories.dart`** - Backend Abstraction
- **`ChatRepository`**: Abstract interface for AI service implementations
- **Event System**: `ResponseChunk`, `ChatError`, `Finished` events for type-safe streaming
- **Backend Implementations**: OpenRouter, Firebase, Supabase repository patterns

### **🎨 Presentation Layer (`lib/presentation/`)**

#### **`lib/presentation/providers/`** - State Management
- **`ChatProvider`**: Core state management for conversations, messages, streaming
- **`ThemeProvider`**: Theme state (system/light/dark) with toggle cycling

#### **`lib/presentation/pages/`** - Page Components
- **`ChatPage`**: Main layout with responsive sidebar and theme integration

### **🧩 Widget Layer (`lib/widgets/`)**

#### **Layout & Navigation**
- **`ChatPage`**: Responsive layout (mobile drawer / desktop sidebar)
- **`ChatSidebar`**: Conversation list, model selection, "New Chat" button
- **`ConversationView`**: Auto-scrolling message display with smart scroll management

#### **Message Display**
- **`MessageView`**: Role-based message rendering (user vs assistant styling)
- **`Response`**: Markdown renderer with headers, lists, links, code blocks
- **`CodeBlock`**: Syntax highlighting with language detection and copy functionality

#### **User Input**
- **`PromptInput`**: Base input container with consistent styling
- **`PromptInputComplete`**: Full input with model selector, shortcuts, attachment placeholder

#### **Interactions & States**
- **`ResponseActions`**: Copy, thumbs up/down, share buttons for messages
- **`ActionsBar`**: Extended actions including retry/regenerate functionality  
- **`EmptyChatState`**: Welcome screen for starting new conversations
- **`Loader`**: Animated loading indicator for streaming and processing

#### **Theme Integration**
- **`theme.dart`**: Complete light/dark theme implementation with exact color mappings
- **Material Design 3**: Modern color system with proper contrast ratios
- **Typography**: Inter for UI text, JetBrains Mono for code blocks

---

### **File Organization**
- **Keep UI logic in widgets/** - focused, reusable components
- **Keep business logic in data/** - services and repositories
- **Keep state management in presentation/** - providers and pages
- **Keep configuration in core/** - centralized app settings

---

## 🔐 **Security Best Practices**

### **Development Security**
✅ **Safe for Local Development:**
- Set API key in `testingOnlyOpenRouterApiKey` for quick testing
- Use `--dart-define=OPENROUTER_API_KEY=key` for secure local runs
- Never commit API keys to version control

### **Production Security**  
⚠️ **CRITICAL for Web Deployment:**
- **Never deploy with `BackendProvider.direct`** - API keys become public!
- **Always use backend proxy** - Firebase Functions, Supabase Edge Functions, etc.
- **Server-Side API Keys** - store secrets on backend, not in Flutter web code
- **Repository Pattern** - swap out `OpenRouterChatRepository` for production backend

### **Recommended Production Setup**
```dart
// 1. Configure backend mode:
static const BackendProvider backendProvider = BackendProvider.firebase;
static const String firebaseProxyUrl = 'https://your-project.cloudfunctions.net/chatProxy';

// 2. Create Firebase Function:
export const chatProxy = functions.https.onCall(async (data, context) => {
  const apiKey = functions.config().openrouter.key; // Server-side secret
  return await fetch('https://openrouter.ai/api/v1/chat/completions', {
    headers: { 'Authorization': `Bearer ${apiKey}` },
    body: JSON.stringify(data)
  });
});
```

---

## 🎯 **Extension Patterns**

### **Adding New Features**

#### **Conversation Folders**
```dart
// Extend Conversation model:
class FolderConversation extends Conversation {
  final String? folderId;
  final Color? folderColor;
}

// Extend ChatSidebar:
class FolderChatSidebar extends ChatSidebar {
  Widget _buildFolderSection(String folderId, List<Conversation> conversations) {
    return ExpansionTile(
      title: Text(_getFolderName(folderId)),
      children: conversations.map((c) => _buildConversationTile(c)).toList(),
    );
  }
}
```

#### **Message Search**
```dart
// Extend ChatProvider:
class SearchableChatProvider extends ChatProvider {
  String _searchQuery = '';
  
  List<Message> searchMessages(String query) {
    return _conversations
        .expand((c) => c.messages)
        .where((m) => m.content.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
```

#### **Voice Input**
```dart
// Extend PromptInputComplete:
class VoicePromptInput extends PromptInputComplete {
  Widget _buildVoiceButton() => IconButton(
    icon: Icon(_isListening ? LucideIcons.micOff : LucideIcons.mic),
    onPressed: _toggleVoiceInput,
  );
  
  void _toggleVoiceInput() async {
    if (_isListening) {
      final result = await _speechToText.stop();
      _controller.text = result;
    } else {
      await _speechToText.listen();
    }
  }
}
```

### **Custom Theme Integration**
```dart
// Add custom theme tokens:
extension CustomThemeData on ThemeData {
  Color get chatBubbleColor => colorScheme.primaryContainer;
  TextStyle get timestampStyle => textTheme.bodySmall?.copyWith(
    color: colorScheme.onSurface.withValues(alpha: 0.6),
  ) ?? const TextStyle();
}

// Use in widgets:
Container(
  color: Theme.of(context).chatBubbleColor,
  child: Text('Message', style: Theme.of(context).timestampStyle),
)
```

---

## 📋 **Customization Checklist**

### **Before Customization**
- [ ] Run the template in demo mode to understand the experience
- [ ] Test with real API key to see full functionality
- [ ] Review the architecture documentation above
- [ ] Identify which components need modification

### **During Development**
- [ ] Follow the established file organization patterns
- [ ] Use the Provider pattern for state management
- [ ] Maintain theme integration for consistent design
- [ ] Add proper documentation for custom components
- [ ] Test both demo mode and real API integration

### **Before Deployment**
- [ ] Switch to production backend mode (`BackendProvider.firebase` or `supabase`)
- [ ] Configure secure backend proxy with server-side API keys
- [ ] Remove any test API keys from configuration files
- [ ] Test the production build thoroughly
- [ ] Verify mobile responsive design works correctly

---

## 🤝 **Contributing & Extension**

### **Code Style**
- Follow the existing documentation patterns for new components
- Use comprehensive class documentation with examples
- Include extension points and customization guidance
- Maintain security awareness in all API integrations

### **Architecture Principles**
- **Separation of Concerns**: Keep UI, state, and data layers distinct
- **Provider Pattern**: Use for all state management
- **Repository Pattern**: Abstract external service integrations
- **Theme Integration**: Use theme-aware styling throughout
- **Security First**: Never expose API keys in client-side web code

### **Extension Guidelines**
- Extend existing components rather than modifying source
- Document architectural decisions and design rationale
- Provide concrete examples for common customizations
- Consider both human developers and AI agents as users of your documentation

---
