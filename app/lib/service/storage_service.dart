import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'dart:io';
import 'package:path/path.dart' as path;

final FirebaseStorage _storage = FirebaseStorage.instance;

Future<String> uploadProfileImage(
  String userId, 
  File imageFile, 
  {Function(double progress)? onProgressUpdate}
) async {
  try {
    // Validate file exists
    if (!await imageFile.exists()) {
      throw Exception('Selected file does not exist');
    }

    // Validate file size (max 5MB)
    final fileSize = await imageFile.length() / 1024 / 1024;
    if (fileSize > 5) {
      throw Exception('Image size must be less than 5MB');
    }

    // Extract file extension and determine content type
    final fileExtension = path.extension(imageFile.path).toLowerCase();
    String contentType = 'image/jpeg'; // Default content type

    if (fileExtension == '.png') {
      contentType = 'image/png';
    } else if (fileExtension == '.jpg' || fileExtension == '.jpeg') {
      contentType = 'image/jpeg';
    }

    // Create reference with user-specific path and timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref()
      .child('profile_images')
      .child(userId)
      .child('$timestamp-profile_picture$fileExtension');

    // Set metadata with dynamic content type
    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {
        'uploaded_by': userId,
        'uploaded_at': timestamp.toString(),
      },
    );

    // Start upload task
    final uploadTask = ref.putFile(imageFile, metadata);

    // Listen for progress updates
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      onProgressUpdate?.call(progress);
    },
    onError: (e) => print('Upload error: $e'));

    // Wait for completion
    final snapshot = await uploadTask;

    // Verify upload was successful
    if (snapshot.state != TaskState.success) {
      throw Exception('Upload failed with state: ${snapshot.state}');
    }

    // Get download URL
    return await snapshot.ref.getDownloadURL();
  } on FirebaseException catch (e) {
    print('Firebase Storage Error [${e.code}]: ${e.message}');
    rethrow;
  } catch (e) {
    print('Upload Error: $e');
    rethrow;
  }
}
