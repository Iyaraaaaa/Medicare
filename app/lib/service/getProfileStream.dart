import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;

class DatabaseHelper {
  final CollectionReference profileCollection = FirebaseFirestore.instance.collection('user_profiles');

  // Get the current user's ID from FirebaseAuth
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  // Insert or update user profile in Firestore
  Future<void> insertProfile(Map<String, dynamic> profileData) async {
    if (userId == null) {
      throw Exception('User is not logged in');
    }

    try {
      // Merge the provided profile data with the existing data (if any)
      await profileCollection.doc(userId!).set(profileData, SetOptions(merge: true));
    } catch (e) {
      print("Error inserting profile: $e");
      throw Exception('Failed to update profile: $e');
    }
  }

  // Stream to listen to profile updates in Firestore
  Stream<Map<String, dynamic>> getProfileStream() {
    if (userId == null) {
      throw Exception('User is not logged in');
    }

    return profileCollection
        .doc(userId!) // Use the dynamic user ID here
        .snapshots()
        .map((doc) {
          // Check if the document exists and has data
          if (doc.exists && doc.data() != null) {
            return doc.data() as Map<String, dynamic>;
          } else {
            return {}; // Return empty map if profile data doesn't exist
          }
        });
  }

  // Retrieve a specific profile field if needed
  Future<String?> getProfileField(String field) async {
    if (userId == null) {
      throw Exception('User is not logged in');
    }

    try {
      final doc = await profileCollection.doc(userId!).get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>?)?[field] as String?;
      }
      return null; // Return null if the field doesn't exist
    } catch (e) {
      throw Exception('Failed to fetch profile field: $e');
    }
  }
}
