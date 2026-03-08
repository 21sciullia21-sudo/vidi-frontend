import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart';
import '../../core/config.dart';
import 'mock_responses_service.dart';

/// **OpenRouterService** - Direct API client for OpenRouter.ai
///
/// Handles both real AI API calls and mock responses for development/demo purposes.
/// This service is primarily used in development mode (`BackendProvider.direct`).
///
/// ## Key Features:
/// - **Dual Mode Operation**: Real API calls or mock responses based on key availability
/// - **Streaming Support**: Real-time response streaming via Server-Sent Events
/// - **Error Handling**: Comprehensive error handling with user-friendly messages
/// - **Security Awareness**: Built-in warnings about API key exposure
///
/// ## Mock Mode Behavior:
/// When `AppConfig.openRouterApiKey.isEmpty`:
/// - Uses `MockResponsesService` for realistic demo responses
/// - Simulates streaming delays and realistic response patterns
/// - Perfect for template previews and development without API keys
///
/// ## Production Security:
/// ⚠️  **CRITICAL**: This service makes direct client-side API calls
/// - Safe for development and local testing only
/// - For production web deployment, use Firebase/Supabase proxy instead
/// - See `ChatRepository` implementations for secure backend patterns
///
/// ## Extension Points:
/// ```dart
/// // Custom error handling:
/// class CustomOpenRouterService extends OpenRouterService {
///   @override
///   Future<String> sendMessage(...) async {
///     try {
///       return await super.sendMessage(...);
///     } on CustomException catch (e) {
///       // Handle specific error types
///     }
///   }
/// }
///
/// // Add request middleware:
/// class TrackedOpenRouterService extends OpenRouterService {
///   final RequestLogger logger;
///
///   @override
///   Stream<String> sendMessageStream(...) async* {
///     logger.logRequest(...);
///     yield* super.sendMessageStream(...);
///   }
/// }
/// ```
class OpenRouterService {
  static const Duration _timeout = Duration(seconds: 30);
  static final _mockService = MockResponsesService();

  bool get _isInMockMode => AppConfig.openRouterApiKey.isEmpty;

  /// Send a chat completion request to OpenRouter (or mock response if no API key)
  Future<String> sendMessage({
    required List<Message> messages,
    required String model,
  }) async {
    // Use mock responses when no API key is configured
    if (_isInMockMode) {
      await _mockService.simulateProcessingDelay();
      final mockStream = _mockService.generateMockResponse();
      final chunks = <String>[];
      await for (final chunk in mockStream) {
        chunks.add(chunk);
      }
      return chunks.join(''); // Return complete mock response
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
              'model': model,
              'messages': messages.map(_messageToJson).toList(),
              'temperature': 0.7,
              'max_tokens': 2048,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;

        if (content != null && content.isNotEmpty) {
          return content;
        } else {
          throw Exception('Empty response from API');
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        throw Exception('API Error (${response.statusCode}): $errorMessage');
      }
    } on TimeoutException {
      throw Exception('Request timeout. Please try again.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to send message: $e');
    }
  }

  /// Send a streaming chat completion request to OpenRouter (or mock stream if no API key)
  Stream<String> sendMessageStream({
    required List<Message> messages,
    required String model,
  }) async* {
    // Use mock streaming when no API key is configured
    if (_isInMockMode) {
      await _mockService.simulateProcessingDelay();
      yield* _mockService.generateMockResponse();
      return;
    }

    http.Client? client;
    try {
      final request = http.Request(
        'POST',
        Uri.parse('${AppConfig.openRouterBaseUrl}/chat/completions'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer ${AppConfig.openRouterApiKey}',
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'HTTP-Referer': AppConfig.appUrl,
        'X-Title': AppConfig.appName,
      });

      request.body = jsonEncode({
        'model': model,
        'messages': messages.map(_messageToJson).toList(),
        'temperature': 0.7,
        'max_tokens': 2048,
        'stream': true,
      });

      client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        final errorData = jsonDecode(errorBody);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        throw Exception('API Error (${response.statusCode}): $errorMessage');
      }

      // Robust SSE buffering per OpenRouter docs
      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;

        while (true) {
          final lineEnd = buffer.indexOf('\n');
          if (lineEnd == -1) break;

          final line = buffer.substring(0, lineEnd).trim();
          buffer = buffer.substring(lineEnd + 1);

          // Ignore SSE comments like ": OPENROUTER PROCESSING"
          if (line.isEmpty || line.startsWith(':')) continue;

          if (line.startsWith('data: ')) {
            final data = line.substring(6);

            if (data.trim() == '[DONE]') {
              return;
            }

            try {
              final json = jsonDecode(data);
              final content =
                  json['choices']?[0]?['delta']?['content'] as String?;
              if (content != null) {
                yield content;
              }
            } catch (_) {
              // Ignore non-JSON lines
            }
          }
        }
      }
    } on TimeoutException {
      throw Exception('Request timeout. Please try again.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to stream message: $e');
    } finally {
      client?.close();
    }
  }

  /// Convert Message to OpenRouter API format
  Map<String, dynamic> _messageToJson(Message message) {
    return {
      'role': message.role == MessageRole.user ? 'user' : 'assistant',
      'content': message.content,
    };
  }

  /// Test API key validity
  Future<bool> testApiKey() async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.openRouterBaseUrl}/models'),
            headers: {
              'Authorization': 'Bearer ${AppConfig.openRouterApiKey}',
            },
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
