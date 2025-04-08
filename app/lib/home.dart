import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'doctor_home.dart';
import 'doctor.dart';
import 'schedule.dart';
import 'edit_profile.dart';
import 'notifications.dart';
import 'privacy.dart';
import 'permission.dart';
import 'about_us.dart';
import 'login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseHelper {
  final CollectionReference profileCollection =
      FirebaseFirestore.instance.collection('user_profiles');

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? "unknown_user";

  // Insert or update profile
  Future<void> insertProfile(Map<String, dynamic> profileData) async {
    try {
      await profileCollection.doc(userId).set(profileData, SetOptions(merge: true));
    } catch (e) {
      print("Error inserting profile: $e");
      rethrow;
    }
  }

  // Get profile by email
  Future<Map<String, dynamic>> getProfileByEmail(String email) async {
    try {
      final querySnapshot = await profileCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print("Error fetching profile by email: $e");
      return {};
    }
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _userName = "User Name";
  String _userEmail = "user@example.com";
  String _userImage = '';

  final List<Widget> _pages = [
    DoctorHomePage(),
    DoctorPage(),
    SchedulePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "User Name";
      _userEmail = prefs.getString('userEmail') ?? "user@example.com";
      _userImage = prefs.getString('userImage') ?? 'assets/images/empty.jpg';
    });
  }

  // Get profile image
  ImageProvider _getImageProvider() {
    if (_userImage.isEmpty) {
      return AssetImage('assets/images/empty.jpg');
    } else if (_userImage.startsWith('http')) {
      return NetworkImage(_userImage);
    } else {
      return AssetImage(_userImage); // Local asset image
    }
  }

  // Handle bottom navigation bar tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Channeling App'),
        backgroundColor: const Color.fromARGB(255, 238, 222, 222),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 238, 222, 222), Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital), label: 'Doctors'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
      drawer: _buildDrawer(),
    );
  }

  // Build the Drawer widget
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                accountEmail: Text(_userEmail),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: _getImageProvider(),
                  onBackgroundImageError: (exception, stackTrace) {
                    print('Failed to load image: $exception');
                  },
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color.fromARGB(255, 180, 228, 200), Colors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: IconButton(
                  icon: Icon(Icons.edit, color: Colors.white),
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(
                          userName: _userName,
                          userEmail: _userEmail,
                          userImage: _userImage,
                        ),
                      ),
                    );
                    if (result == true) {
                      await _loadUserData();
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
          ),
          _buildDrawerItem(Icons.notifications, 'Notifications', Colors.purple, NotificationsPage()),
          _buildDrawerItem(Icons.privacy_tip, 'Privacy', Colors.green, PrivacyPage()),
          _buildDrawerItem(Icons.settings, 'Permission', Colors.orange, PermissionPage()),
          _buildDrawerItem(Icons.info, 'About Us', Colors.teal, AboutUsPage()),
          _buildDrawerItem(Icons.logout, 'Log Out', Colors.red, LoginPage(), isLogout: true),
        ],
      ),
    );
  }

  // Helper function for drawer items
  Widget _buildDrawerItem(IconData icon, String title, Color iconColor, Widget page, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      tileColor: isLogout ? Colors.red.shade50 : null,
      onTap: () async {
        if (isLogout) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        }
      },
    );
  }
}
