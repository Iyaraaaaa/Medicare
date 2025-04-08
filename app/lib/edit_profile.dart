import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseHelper {
  Future<Map<String, dynamic>> getProfileByEmail(String email) async {
    // Mock implementation
    return {'name': 'John Doe', 'email': email, 'password': '123456'};
  }

  Future<void> insertProfile(Map<String, dynamic> profileData) async {
    // Mock implementation
    print('Profile data saved: $profileData');
  }
}

class EditProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userImage;

  const EditProfilePage({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.userImage,
  }) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Load existing profile data from the database
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _dbHelper.getProfileByEmail(widget.userEmail);
      nameController.text = profile['name'] ?? widget.userName;
      emailController.text = profile['email'] ?? widget.userEmail;
      passwordController.text = profile['password'] ?? '';
    } catch (e) {
      _showErrorSnackbar('Failed to load profile: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Pick image from gallery and validate size
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length() / 1024 / 1024; // MB
        if (fileSize > 5) {
          _showErrorSnackbar('Image size should be less than 5MB');
          return;
        }
        setState(() => _image = file);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: ${e.toString()}');
    }
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadImage(File image) async {
    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid ?? 'unknown_user';
      final fileName = 'profile_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref(fileName);

      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});

      if (snapshot.state == TaskState.success) {
        return await snapshot.ref.getDownloadURL();
      }
      return null;
    } on FirebaseException catch (e) {
      _showErrorSnackbar('Storage error: ${e.message}');
      return null;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Update the email with email verification
  Future<void> _updateEmail(String newEmail) async {
    try {
      if (_auth.currentUser?.email == newEmail) {
        _showErrorSnackbar('This is your current email address.');
        return;
      }

      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
      _showSuccessSnackbar('Verification email sent to $newEmail');
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar('Email update failed: ${e.message}');
    }
  }

  // Update the password
  Future<void> _updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      _showSuccessSnackbar('Password updated successfully');
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar('Password update failed: ${e.message}');
    }
  }

  // Show an error message
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Show a success message
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // Save changes to the profile
  Future<void> _saveChanges() async {
    if (nameController.text.isEmpty) {
      _showErrorSnackbar('Name is required');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text)) {
      _showErrorSnackbar('Please enter a valid email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update email if changed
      if (emailController.text != widget.userEmail) {
        await _updateEmail(emailController.text);
      }

      // Update password if valid
      if (passwordController.text.isNotEmpty && passwordController.text.length >= 6) {
        await _updatePassword(passwordController.text);
      } else if (passwordController.text.isNotEmpty) {
        _showErrorSnackbar('Password should be at least 6 characters');
        return;
      }

      // Upload new profile image if selected
      String? imageUrl = widget.userImage;
      if (_image != null) {
        imageUrl = await _uploadImage(_image!);
        if (imageUrl == null) return;
      }

      // Save profile data
      final profileData = {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'imagePath': imageUrl ?? '',
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await _dbHelper.insertProfile(profileData);

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', nameController.text);
      await prefs.setString('userEmail', emailController.text);
      if (imageUrl != null) {
        await prefs.setString('userImage', imageUrl);
      }

      _showSuccessSnackbar('Profile updated successfully!');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackbar('Failed to save changes: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileImage(),
                  const SizedBox(height: 20),
                  _buildFormFields(),
                  const SizedBox(height: 25),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.blue.shade100,
          backgroundImage: _getImageProvider(),
          child: _image == null && widget.userImage.isEmpty
              ? const Icon(Icons.person, size: 50, color: Colors.white)
              : null,
        ),
        FloatingActionButton.small(
          onPressed: _pickImage,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.camera_alt, size: 20),
        ),
      ],
    );
  }

  ImageProvider _getImageProvider() {
    if (_image != null) return FileImage(_image!);
    if (widget.userImage.isNotEmpty) {
      if (widget.userImage.startsWith('http')) {
        return NetworkImage(widget.userImage);
      }
      return FileImage(File(widget.userImage));
    }
    return const AssetImage('assets/images/default_profile.png');
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: nameController,
          decoration: _inputDecoration('Name', Icons.person),
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: emailController,
          decoration: _inputDecoration('Email', Icons.email),
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: passwordController,
          obscureText: !_isPasswordVisible,
          decoration: _inputDecoration(
            'Password', Icons.lock, 
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.blue),
      prefixIcon: Icon(icon, color: Colors.blue),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveChanges,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text('Save Changes'),
    );
  }
}
