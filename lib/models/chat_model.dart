/// Base model for all chat messages in the StudyMate AI application.
/// Uses Dart 3 [sealed class] to represent different types of messages.
sealed class ChatMessage {
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.timestamp,
  });
}

/// Represents a message sent by the user (student).
class UserMessage extends ChatMessage {
  const UserMessage({
    required super.text,
    required super.timestamp,
  });
}

/// Represents a message sent by the AI Tutor (StudyMate AI).
class AIMessage extends ChatMessage {
  const AIMessage({
    required super.text,
    required super.timestamp,
  });
}
