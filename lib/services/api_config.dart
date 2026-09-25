// lib/services/api_config.dart
class ApiConfig {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AQ.Ab8RN6KGVfW1dcdWqX3-DIT1aMlHGU9KPcJAZqOT-acJUL9g2A', // Fallback for local testing so it never drops as null
  );
}