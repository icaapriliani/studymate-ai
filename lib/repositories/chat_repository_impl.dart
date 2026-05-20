import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/repositories/chat_repository.dart';
import '../models/chat_model.dart';
import '../models/conversation_model.dart';
import '../services/firestore_service.dart';

/// Implementation of the [ChatRepository] following Clean Architecture.
/// Integrates with [FirestoreService] and handles Firestore-specific error translation.
class ChatRepositoryImpl implements ChatRepository {
  final FirestoreService _firestoreService;

  ChatRepositoryImpl({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  @override
  Future<void> saveMessage(String uid, ChatMessage message) async {
    try {
      final sender = message is UserMessage ? 'user' : 'ai';
      await _firestoreService.saveChatMessage(
        uid,
        message.text,
        sender,
        message.timestamp,
      );
    } catch (e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String uid) async {
    try {
      final rawMessages = await _firestoreService.getChatMessages(uid);
      final List<ChatMessage> chatMessages = [];
      
      for (final raw in rawMessages) {
        final text = raw['text'] as String? ?? '';
        final sender = raw['sender'] as String? ?? 'user';
        final timestampField = raw['timestamp'];
        
        DateTime timestamp;
        if (timestampField is Timestamp) {
          timestamp = timestampField.toDate();
        } else {
          timestamp = DateTime.now();
        }

        if (sender == 'user') {
          chatMessages.add(UserMessage(text: text, timestamp: timestamp));
        } else {
          chatMessages.add(AIMessage(text: text, timestamp: timestamp));
        }
      }
      
      return chatMessages;
    } catch (e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  @override
  Future<List<ConversationModel>> getConversations(String uid) async {
    try {
      final rawConversations = await _firestoreService.getConversations(uid);
      return rawConversations
          .map((data) => ConversationModel.fromFirestore(data, data['id'] as String))
          .toList();
    } catch (e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  @override
  Future<String> createConversation(String uid, String title) async {
    try {
      return await _firestoreService.createConversation(uid, title);
    } catch (e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  @override
  Future<void> updateConversationTitle(String uid, String conversationId, String title) async {
    try {
      await _firestoreService.updateConversation(uid, conversationId, title: title);
    } catch (e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  @override
  Future<void> saveConversationMessage(String uid, String conversationId, ChatMessage message) async {
    try {
      final sender = message is UserMessage ? 'user' : 'ai';
      await _firestoreService.saveConversationMessage(
        uid,
        conversationId,
        message.text,
        sender,
        message.timestamp,
      );
    } catch (e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  @override
  Future<List<ChatMessage>> getConversationMessages(String uid, String conversationId) async {
    try {
      final rawMessages = await _firestoreService.getConversationMessages(uid, conversationId);
      final List<ChatMessage> chatMessages = [];
      
      for (final raw in rawMessages) {
        final text = raw['text'] as String? ?? '';
        final sender = raw['sender'] as String? ?? 'user';
        final timestampField = raw['timestamp'];
        
        DateTime timestamp;
        if (timestampField is Timestamp) {
          timestamp = timestampField.toDate();
        } else {
          timestamp = DateTime.now();
        }

        if (sender == 'user') {
          chatMessages.add(UserMessage(text: text, timestamp: timestamp));
        } else {
          chatMessages.add(AIMessage(text: text, timestamp: timestamp));
        }
      }
      
      return chatMessages;
    } catch (e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  @override
  Future<void> deleteConversation(String uid, String conversationId) async {
    try {
      await _firestoreService.deleteConversation(uid, conversationId);
    } catch (e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  /// Low-level database error translation into helpful Indonesian messages.
  String _mapErrorToUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission_denied') || 
        errorString.contains('permission-denied') ||
        errorString.contains('rules')) {
      return 'Akses database ditolak. Harap pastikan aturan keamanan (Security Rules) Firestore Anda sudah dikonfigurasi ke publik/mode pengujian di Firebase Console.';
    }
    
    if (errorString.contains('api_disabled') || 
        errorString.contains('firestore api has not been used') ||
        errorString.contains('not-found')) {
      return 'Layanan Cloud Firestore belum diaktifkan pada proyek Firebase Anda. Harap buat database Firestore di Firebase Console.';
    }
    
    return 'Terjadi kesalahan sistem saat mengakses riwayat chat: $error';
  }
}
