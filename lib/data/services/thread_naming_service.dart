import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config.dart';
import 'mock_responses_service.dart';

class ThreadNamingService {
  static const Duration _timeout = Duration(seconds: 10);
  static const String _namingModel = 'google/gemini-2.5-flash-lite';
  static final _mockService = MockResponsesService();

  bool get _isInMockMode => AppConfig.openRouterApiKey.isEmpty;

  /// Generate a concise thread name based on the first prompt (or mock name if no API key)
  Future<String> generateThreadName(String firstPrompt) async {
    // Use mock thread names when no API key is configured
    if (_isInMockMode) {
      await _mockService.simulateProcessingDelay();
      return _mockService.generateMockThreadName();
    }

    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.openRouterBaseUrl}/chat/completions'),
            headers: {
              'Authorization': 'Bearer ${AppConfig.openRouterApiKey}',
              'Content-Type': 'application/json',
              'HTTP-Referer': AppConfig.appUrl,
              'X-Title': AppConfig.appName,
            },
            body: jsonEncode({
              'model': _namingModel,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a helpful assistant that creates concise, descriptive names for chat conversations. Generate a short (2-5 words), clear title that captures the main topic or intent of the user\'s message. Do not use quotes, punctuation, or extra formatting. Just return the title.',
                },
                {
                  'role': 'user',
                  'content':
                      'Create a title for this conversation based on this message: "$firstPrompt"',
                },
              ],
              'temperature': 0.3,
              'max_tokens': 20,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;

        if (content != null && content.isNotEmpty) {
          // Clean up the generated name
          String cleanName = content.trim();
          // Remove quotes
          cleanName = cleanName.replaceAll('"', '');
          cleanName = cleanName.replaceAll("'", '');
          cleanName = cleanName.replaceAll('`', '');
          // Remove special characters except letters, numbers, spaces, and hyphens
          cleanName = cleanName.replaceAll(RegExp(r'[^\w\s-]'), '');
          cleanName = cleanName.trim();

          // Fallback if cleaning resulted in empty string
          return cleanName.isNotEmpty
              ? cleanName
              : _generateFallbackTitle(firstPrompt);
        } else {
          return _generateFallbackTitle(firstPrompt);
        }
      } else {
        // API error, use fallback
        return _generateFallbackTitle(firstPrompt);
      }
    } on TimeoutException {
      // Timeout, use fallback
      return _generateFallbackTitle(firstPrompt);
    } catch (e) {
      // Any other error, use fallback
      return _generateFallbackTitle(firstPrompt);
    }
  }

  /// Fallback title generation when API fails
  String _generateFallbackTitle(String content) {
    // Simple title generation from first message
    final words = content.split(' ');
    if (words.length <= 4) return content;
    return '${words.take(4).join(' ')}...';
  }
}
