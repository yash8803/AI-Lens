import 'package:ai/services/theme_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Utils/ShColors.dart';
import 'login_screen.dart';
import 'recognition_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Lens', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [bluegrey1, sh_title_font], begin: Alignment.topRight, end: Alignment.bottomLeft),
          ),
        ),
        backgroundColor: themeNotifier.isDarkMode ? Colors.black : sh_appbar,
        actions: [
          IconButton(
            icon: Icon(Icons.settings,),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching user data.'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('User data not found.'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome , ${userData['name']} !!!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: themeNotifier.isDarkMode ? Colors.red : sh_title_font,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Capture images and recognize text and objects using AI.',
                  style: TextStyle(
                    fontSize: 16,
                    color: themeNotifier.isDarkMode ? Colors.grey[300] : bluegrey5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RecognitionScreen()),
                    );
                  },
                  child: Text('Start Recognition'),
                  style: ElevatedButton.styleFrom(
                    primary: sh_btn,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}