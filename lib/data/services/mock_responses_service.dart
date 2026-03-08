import 'dart:async';
import 'dart:math';
import '../models.dart';

/// **MockResponsesService** - Provides realistic demo responses for development
///
/// This service generates mock AI responses when no API key is configured,
/// enabling the template to work out-of-the-box for demos and development.
/// Responses simulate real AI behavior including streaming delays and varied content.
///
/// ## Key Features:
/// - **Realistic Streaming**: Word-by-word delivery with variable delays
/// - **Diverse Content**: Pool of responses covering different conversation styles
/// - **Educational Value**: Mock responses explain template features and setup
/// - **Demonstration Ready**: Perfect for showcasing template capabilities
///
/// ## Technical Implementation:
/// - Yields incremental chunks (individual words) for proper streaming
/// - Variable delays based on punctuation and word length
/// - Random response selection for conversation variety
/// - Thread name generation for conversation organization
///
/// ## Integration:
/// - Automatically used by `OpenRouterService` when `AppConfig.openRouterApiKey.isEmpty`
/// - Integrated into `ThreadNamingService` for consistent mock experience
/// - Designed to be indistinguishable from real API responses in UI
///
/// ## Customization Examples:
/// ```dart
/// // Add domain-specific responses:
/// class CustomMockService extends MockResponsesService {
///   static const List<String> _domainResponses = [
///     'Here\'s help with your Flutter development...',
///     'Let me explain this design pattern...',
///   ];
/// }
///
/// // Add conversation context:
/// class ContextualMockService extends MockResponsesService {
///   String generateContextualResponse(List<Message> history) {
///     // Generate responses based on conversation history
///   }
/// }
/// ```
class MockResponsesService {
  static final _random = Random();

  // Pool of realistic mock responses for different types of prompts
  static const List<String> _mockResponses = [
    '''This is a **mock response** from the AI Chat Template demo.

To get real AI responses, you'll need to:
1. Set your OpenRouter API key in `lib/core/config.dart` (local testing only)
2. Or use `flutter run --dart-define=OPENROUTER_API_KEY=your_key`
3. For production, implement a backend proxy to keep API keys secure

Here's what a real response might look like:

```dart
// Example Flutter code
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Hello World'),
    );
  }
}
```

This template demonstrates streaming responses, theme switching, and clean architecture patterns.''',

    '''Hello! I'm a **mock AI assistant** running in demo mode.

This AI Chat Template showcases:
- 🔄 **Streaming responses** (like this one!)
- 🎨 **Theme switching** (try the theme button!)
- 🏗️ **Clean architecture** with Provider state management
- 📱 **Responsive design** for all screen sizes

To enable real AI responses:
- Add your OpenRouter API key to the configuration
- Over 20+ models available including GPT-5, Claude 4, and Gemini 2.5

**Pro tip**: Check out the other templates in the gallery - Dashboard and Shadcn UI Playground!''',

    '''I'm demonstrating the **mock mode** of this AI chat template.

Key features you can explore right now:
- Type messages and see streaming responses
- Toggle between light/dark/system themes 🌙☀️🖥️
- Responsive layout adapts to your screen
- Clean, modern UI design

When you add your API key, you'll get:
- Real AI conversations with 20+ models
- Intelligent thread naming
- Actual streaming from OpenRouter API

This template is perfect for building AI chat applications with Flutter!''',

    '''Welcome to the **AI Chat Template** preview! 

This is a fully functional chat interface running in mock mode. Here's what makes this template special:

**🚀 Features:**
- Stream-based responses for real-time feel
- Provider-based state management
- Theme persistence across sessions
- Clean, extensible architecture

**🔧 Customization:**
- Easy to swap AI providers
- Modular component structure
- Configurable models and settings
- Ready for production with proper backend setup

Try exploring the code structure - it's designed to be developer-friendly and maintainable!''',

    '''Hi there! You're experiencing the **demo mode** of this AI chat application.

**What you're seeing:**
- Mock streaming responses (this message is being "typed" in real-time)
- Professional chat UI with modern design
- Theme switching between light, dark, and system modes

**What you get with API setup:**
- Real conversations with advanced AI models
- Intelligent automatic thread naming  
- Full OpenRouter integration with 20+ models

**Perfect for:**
- Customer support chatbots
- Educational tools
- Personal AI assistants
- Any chat-based application

The code is clean, well-documented, and production-ready!''',
  ];

  static const List<String> _mockThreadNames = [
    'Flutter Development Help',
    'UI Design Discussion',
    'Mock API Integration',
    'Template Configuration',
    'Theme Implementation',
    'State Management Guide',
    'Component Architecture',
    'Development Workflow',
    'Code Review Session',
    'Feature Planning',
  ];

  /// Generate a mock response with realistic streaming delay
  /// Yields incremental chunks (individual words/tokens) for proper streaming
  Stream<String> generateMockResponse() async* {
    final response = _mockResponses[_random.nextInt(_mockResponses.length)];
    final words = response.split(' ');

    // Stream individual words with realistic typing delay
    for (int i = 0; i < words.length; i++) {
      // Yield just the new word (with space prefix except for first word)
      final chunk = i == 0 ? words[i] : ' ${words[i]}';
      yield chunk;

      // Vary delay based on word length and punctuation
      int baseDelay = 20;
      if (words[i].contains('\n')) baseDelay += 200;
      if (words[i].contains('.') ||
          words[i].contains('!') ||
          words[i].contains('?'))
        baseDelay += 300;
      if (words[i].length > 6) baseDelay += 20;

      // Add random variation
      final delayMs = baseDelay + _random.nextInt(30);
      await Future.delayed(Duration(milliseconds: delayMs));
    }
  }

  /// Generate a mock thread name
  String generateMockThreadName() {
    return _mockThreadNames[_random.nextInt(_mockThreadNames.length)];
  }

  /// Simulate processing delay
  Future<void> simulateProcessingDelay() async {
    await Future.delayed(Duration(milliseconds: 200 + _random.nextInt(300)));
  }
}
