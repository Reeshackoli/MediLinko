import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Simple healthcare chatbot service using Groq API
class HealthcareChatService {
  // API key loaded from compile-time environment variable
  // Build with: flutter build apk --dart-define=GROQ_API_KEY=your_key_here
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  /// System prompt to make the AI focus on healthcare
  static const String _systemPrompt = '''
You are MediLinko Health Assistant, a friendly and knowledgeable healthcare chatbot. Your role is to:

1. Provide general health information and wellness tips
2. Help users understand common symptoms and when to seek medical attention
3. Offer guidance on healthy lifestyle choices, nutrition, and exercise
4. Explain common medical terms in simple language
5. Remind users about medication adherence and health checkups

IMPORTANT GUIDELINES:
- Always recommend consulting a healthcare professional for diagnosis and treatment
- Never prescribe medications or provide specific medical diagnoses
- Be empathetic and supportive in your responses
- Keep responses concise and easy to understand
- If asked about emergencies, always advise calling emergency services immediately
- Maintain patient privacy and confidentiality

You are NOT a replacement for professional medical advice. Always encourage users to consult with their doctors for specific health concerns.
''';

  /// Send a message to the chatbot and get a response
  static Future<String> sendMessage(String userMessage, List<Map<String, String>> chatHistory) async {
    // Check if API key is configured
    if (_apiKey.isEmpty) {
      return 'Health Assistant is not configured. Please contact support.';
    }
    
    try {
      // Build messages array with system prompt and chat history
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': _systemPrompt},
        ...chatHistory,
        {'role': 'user', 'content': userMessage},
      ];

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;
        return content ?? 'Sorry, I couldn\'t generate a response. Please try again.';
      } else {
        debugPrint('❌ Groq API Error: ${response.statusCode} - ${response.body}');
        return 'Sorry, I\'m having trouble connecting right now. Please try again later.';
      }
    } catch (e) {
      debugPrint('❌ Chat error: $e');
      return 'Sorry, something went wrong. Please check your internet connection and try again.';
    }
  }
}

/// Chat message model
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
