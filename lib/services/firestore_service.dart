import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection reference for Users
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // Collection reference for User's Chats (Backward Compatibility)
  CollectionReference<Map<String, dynamic>> _chatsCollection(String uid) =>
      _usersCollection.doc(uid).collection('chats');

  // Collection reference for User's Conversations (Multi-Conversation System)
  CollectionReference<Map<String, dynamic>> _conversationsCollection(String uid) =>
      _usersCollection.doc(uid).collection('conversations');

  // Collection reference for Conversation's Messages (Multi-Conversation System)
  CollectionReference<Map<String, dynamic>> _messagesCollection(String uid, String conversationId) =>
      _conversationsCollection(uid).doc(conversationId).collection('messages');

  /// Creates a new conversation document in Firestore and returns its ID.
  Future<String> createConversation(String uid, String title) async {
    try {
      final docRef = await _conversationsCollection(uid).add({
        'title': title,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Updates the conversation's updatedAt timestamp and optionally its title.
  Future<void> updateConversation(String uid, String conversationId, {String? title}) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (title != null) {
        updates['title'] = title;
      }
      await _conversationsCollection(uid).doc(conversationId).update(updates);
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves all conversations for the specified user ordered by updatedAt descending.
  Future<List<Map<String, dynamic>>> getConversations(String uid) async {
    try {
      final snapshot = await _conversationsCollection(uid)
          .orderBy('updatedAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a specific conversation document.
  Future<void> deleteConversation(String uid, String conversationId) async {
    try {
      await _conversationsCollection(uid).doc(conversationId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Saves a chat message to a specific conversation subcollection.
  Future<void> saveConversationMessage(
    String uid,
    String conversationId,
    String text,
    String sender,
    DateTime timestamp,
  ) async {
    try {
      await _messagesCollection(uid, conversationId).add({
        'text': text,
        'sender': sender,
        'timestamp': Timestamp.fromDate(timestamp),
      });
      // Automatically touch/update the parent conversation's updatedAt timestamp
      await updateConversation(uid, conversationId);
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves all messages for a specific conversation ordered chronologically.
  Future<List<Map<String, dynamic>>> getConversationMessages(String uid, String conversationId) async {
    try {
      final snapshot = await _messagesCollection(uid, conversationId)
          .orderBy('timestamp', descending: false)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Save chat message to Firestore
  Future<void> saveChatMessage(
    String uid,
    String text,
    String sender,
    DateTime timestamp,
  ) async {
    try {
      await _chatsCollection(uid).add({
        'text': text,
        'sender': sender,
        'timestamp': Timestamp.fromDate(timestamp),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get all chat messages ordered by timestamp
  Future<List<Map<String, dynamic>>> getChatMessages(String uid) async {
    try {
      final snapshot = await _chatsCollection(uid)
          .orderBy('timestamp', descending: false)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Save/Update user profile
  Future<void> saveUserProfile(UserModel userModel) async {
    try {
      await _usersCollection.doc(userModel.uid).set(
            userModel.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final snapshot = await _usersCollection.doc(uid).get();
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromFirestore(snapshot.data()!, snapshot.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
