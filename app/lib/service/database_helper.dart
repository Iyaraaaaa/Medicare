import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class ProfileHelper {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> updateProfileImage() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user signed in.');
    }

    // Pick image from gallery or camera
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery); // Or use ImageSource.camera

    if (image == null) {
      throw Exception('No image selected.');
    }

    try {
      // Upload the image to Firebase Storage
      final storageRef = _storage.ref().child('profile_images/${user.uid}');
      final uploadTask = storageRef.putFile(File(image.path));

      // Show progress (optional, such as with a loading spinner)
      final snapshot = await uploadTask.whenComplete(() => null);

      // Get image URL after upload is complete
      final imageUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore with image URL
      await _firestore.collection('user_profiles').doc(user.uid).set({
        'profile_image': imageUrl,
      }, SetOptions(merge: true));

      // Optionally, you can also update the profile image URL in local storage (e.g., SharedPreferences) if needed.

    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }
}
