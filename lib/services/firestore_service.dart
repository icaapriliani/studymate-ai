import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection reference for Users
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

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
