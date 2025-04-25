import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'doctor_home.dart';
import 'doctor.dart';
import 'schedule.dart';
import 'edit_profile.dart';
import 'notifications.dart';
import 'privacy.dart';
import 'about_us.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  HomePage({required this.onThemeChanged, required this.isDarkMode});

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

  final List<String> _titles = ['Home', 'Doctors', 'Schedule'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "User Name";
      _userEmail = prefs.getString('userEmail') ?? "user@example.com";
      _userImage = prefs.getString('userImage') ?? 'assets/images/empty.jpg';
    });
  }

  ImageProvider _getImageProvider() {
    if (_userImage.isEmpty) {
      return AssetImage('assets/images/empty.jpg');
    } else if (_userImage.startsWith('http')) {
      return NetworkImage(_userImage);
    } else {
      return AssetImage(_userImage);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: () {
              widget.onThemeChanged(!widget.isDarkMode);
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
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

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(_userName, style: TextStyle(fontWeight: FontWeight.bold)),
                accountEmail: Text(_userEmail),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: _getImageProvider(),
                  onBackgroundImageError: (exception, stackTrace) {
                    print('Failed to load image: $exception');
                  },
                ),
                decoration: BoxDecoration(
                  color: Colors.blue, // Removed background image, kept solid color
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
          _buildDrawerItem(Icons.info, 'About Us', Colors.teal, AboutUsPage()),
          _buildDrawerItem(Icons.logout, 'Log Out', Colors.amber, LoginPage(), isLogout: true),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Color iconColor, Widget page, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      tileColor: isLogout 
          ? (widget.isDarkMode ? Colors.deepPurple : Colors.amber.shade100)  // Amazing Log Out color
          : null,
      textColor: widget.isDarkMode ? Colors.white : Colors.black, // Adjust text color for dark mode
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
