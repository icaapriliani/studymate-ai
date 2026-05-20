import 'package:flutter/material.dart';
import '../domain/repositories/gemini_repository.dart';
import '../domain/repositories/chat_repository.dart';
import '../models/chat_model.dart';
import '../models/conversation_model.dart';

/// State management for the AI Tutor Chat Feature using [ChangeNotifier].
/// Decoupled from concrete implementations by depending on [GeminiRepository] and [ChatRepository].
class AIChatProvider extends ChangeNotifier {
  final GeminiRepository _geminiRepository;
  final ChatRepository _chatRepository;

  AIChatProvider({
    required GeminiRepository geminiRepository,
    required ChatRepository chatRepository,
  })  : _geminiRepository = geminiRepository,
        _chatRepository = chatRepository;

  final List<ChatMessage> _messages = [];
  final List<ConversationModel> _conversations = [];
  String? _activeConversationId;
  bool _isLoading = false;
  bool _isHistoryLoading = false;
  String? _errorMessage;

  /// Unmodifiable list of chat messages for the active conversation.
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Unmodifiable list of all conversations for the authenticated user.
  List<ConversationModel> get conversations => List.unmodifiable(_conversations);

  /// The currently active conversation ID (null signifies a blank new chat session).
  String? get activeConversationId => _activeConversationId;

  /// Status of whether the AI is currently thinking/generating a response.
  bool get isLoading => _isLoading;

  /// Status of whether conversation history is loading from Firestore.
  bool get isHistoryLoading => _isHistoryLoading;

  /// Holds the current user-friendly error message in Indonesian, if any.
  String? get errorMessage => _errorMessage;

  /// Loads all conversation documents for the user from Firestore.
  Future<void> loadConversations(String uid) async {
    if (uid.isEmpty) return;

    _isHistoryLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[StudyMate AI Provider] Memuat daftar percakapan untuk UID: $uid');
      final list = await _chatRepository.getConversations(uid);
      _conversations.clear();
      _conversations.addAll(list);
      debugPrint('[StudyMate AI Provider] Berhasil memuat ${_conversations.length} percakapan.');
    } catch (e, stackTrace) {
      debugPrint('[StudyMate AI Provider] Gagal memuat daftar percakapan: $e');
      debugPrint('[StudyMate AI Provider] StackTrace:\n$stackTrace');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  /// Sets the active conversation, clears memory, and loads all its messages from Firestore.
  Future<void> selectConversation(String uid, String conversationId) async {
    if (uid.isEmpty || conversationId.isEmpty) return;

    _activeConversationId = conversationId;
    _messages.clear();
    _isLoading = true; // Show loading spinner during message retrieval
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[StudyMate AI Provider] Memuat pesan untuk percakapan: $conversationId');
      final history = await _chatRepository.getConversationMessages(uid, conversationId);
      _messages.clear();
      _messages.addAll(history);
      debugPrint('[StudyMate AI Provider] Berhasil memuat ${history.length} pesan.');
    } catch (e, stackTrace) {
      debugPrint('[StudyMate AI Provider] Gagal memuat pesan percakapan: $e');
      debugPrint('[StudyMate AI Provider] StackTrace:\n$stackTrace');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initiates a brand-new local chat session without saving anything yet (Lazy Creation).
  void startNewChat() {
    _activeConversationId = null;
    _messages.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
    debugPrint('[StudyMate AI Provider] Memulai obrolan baru (Lazy Mode).');
  }

  /// Deletes a specific conversation from Firestore and local lists.
  /// If the deleted conversation was the active one, it automatically starts a new chat.
  Future<void> deleteConversation(String uid, String conversationId) async {
    if (uid.isEmpty || conversationId.isEmpty) return;

    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[StudyMate AI Provider] Menghapus percakapan: $conversationId');
      await _chatRepository.deleteConversation(uid, conversationId);
      
      _conversations.removeWhere((c) => c.id == conversationId);

      if (_activeConversationId == conversationId) {
        startNewChat();
      } else {
        notifyListeners();
      }
      debugPrint('[StudyMate AI Provider] Percakapan berhasil dihapus.');
    } catch (e, stackTrace) {
      debugPrint('[StudyMate AI Provider] Gagal menghapus percakapan: $e');
      debugPrint('[StudyMate AI Provider] StackTrace:\n$stackTrace');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Loads the active conversation or fallback list (Backward Compatibility).
  @Deprecated('Gunakan loadConversations dan selectConversation sebagai gantinya')
  Future<void> loadChatHistory(String uid) async {
    await loadConversations(uid);
    if (_conversations.isNotEmpty) {
      await selectConversation(uid, _conversations.first.id);
    } else {
      startNewChat();
    }
  }

  /// Sends a user message, lazily creates conversation in Firestore if first message,
  /// saves to Firestore, calls Gemini AI, and saves AI response.
  Future<void> sendMessage(String prompt, String uid) async {
    final cleanedPrompt = prompt.trim();
    if (cleanedPrompt.isEmpty) {
      _errorMessage = 'Pertanyaan tidak boleh kosong. Silakan ketik sesuatu untuk mulai belajar!';
      notifyListeners();
      return;
    }

    _errorMessage = null;
    
    // Create and add UserMessage locally for optimistic UI response
    final userMessage = UserMessage(
      text: cleanedPrompt,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners(); // Notify UI to render user's message and show loading indicator

    try {
      // 1. If no active conversation exists, lazily create one in Firestore first
      if (_activeConversationId == null && uid.isNotEmpty) {
        final title = cleanedPrompt.length > 30 ? '${cleanedPrompt.substring(0, 30)}...' : cleanedPrompt;
        debugPrint('[StudyMate AI Provider] Membuat percakapan baru di Firestore dengan judul: "$title"');
        final newConversationId = await _chatRepository.createConversation(uid, title);
        _activeConversationId = newConversationId;
        
        // Refresh conversations list asynchronously so drawer has the new item
        _chatRepository.getConversations(uid).then((list) {
          _conversations.clear();
          _conversations.addAll(list);
          notifyListeners();
        }).catchError((e) {
          debugPrint('[StudyMate AI Provider] Gagal memuat ulang daftar percakapan setelah pembuatan: $e');
        });
      }

      final conversationId = _activeConversationId;

      // 2. Persist UserMessage in Firestore asynchronously (do not block Gemini API call)
      if (uid.isNotEmpty && conversationId != null) {
        _chatRepository.saveConversationMessage(uid, conversationId, userMessage).catchError((error) {
          debugPrint('[StudyMate AI Provider] Gagal menyimpan pesan user ke Firestore: $error');
        });
      }

      // 3. Fetch response from Gemini AI Repository
      final aiResponseText = await _geminiRepository.getAIResponse(cleanedPrompt);

      // 4. Create AIMessage
      final aiMessage = AIMessage(
        text: aiResponseText,
        timestamp: DateTime.now(),
      );

      // 5. Persist AIMessage in Firestore asynchronously
      if (uid.isNotEmpty && conversationId != null) {
        _chatRepository.saveConversationMessage(uid, conversationId, aiMessage).catchError((error) {
          debugPrint('[StudyMate AI Provider] Gagal menyimpan pesan AI ke Firestore: $error');
        });
        
        // Touch updatedAt of local conversation in drawer and re-order list
        final index = _conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          final oldConv = _conversations.removeAt(index);
          _conversations.insert(0, ConversationModel(
            id: oldConv.id,
            title: oldConv.title,
            createdAt: oldConv.createdAt,
            updatedAt: DateTime.now(),
          ));
        }
      }

      // 6. Add AIMessage to the list
      _messages.add(aiMessage);
    } catch (e, stackTrace) {
      // Print the caught error at provider level
      debugPrint('[StudyMate AI Provider] Terjadi error saat memproses sendMessage:');
      debugPrint('[StudyMate AI Provider] Exception Asli: $e');
      debugPrint('[StudyMate AI Provider] StackTrace:\n$stackTrace');

      // Capture the user-friendly Indonesian error message
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      // Turn off loading and notify UI for optimal rebuilds
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the active chat session history locally (Resets state back to New Chat).
  void clearChat() {
    startNewChat();
  }
}
