import '../../models/chat_model.dart';
import '../../models/conversation_model.dart';

/// Contract for the Chat Repository following Clean Architecture.
/// Manages loading and saving of permanent chat history to a database.
abstract class ChatRepository {
  /// Saves a [message] under the specified user [uid] (Backward Compatibility).
  Future<void> saveMessage(String uid, ChatMessage message);

  /// Loads the chronological list of [ChatMessage]s for the specified user [uid] (Backward Compatibility).
  Future<List<ChatMessage>> getChatHistory(String uid);

  /// Retrieves the list of all conversations for the user [uid].
  Future<List<ConversationModel>> getConversations(String uid);

  /// Creates a new conversation in Firestore with the given [title]. Returns the generated conversation ID.
  Future<String> createConversation(String uid, String title);

  /// Updates the title of the conversation.
  Future<void> updateConversationTitle(String uid, String conversationId, String title);

  /// Saves a [message] under the specified [conversationId] for user [uid].
  Future<void> saveConversationMessage(String uid, String conversationId, ChatMessage message);

  /// Loads the chronological list of [ChatMessage]s for the specified [conversationId].
  Future<List<ChatMessage>> getConversationMessages(String uid, String conversationId);

  /// Deletes a specific conversation.
  Future<void> deleteConversation(String uid, String conversationId);
}
