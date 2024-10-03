import 'package:ai/services/theme_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Utils/ShColors.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, dynamic> userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        userData = userDoc.data() as Map<String, dynamic>;
        isLoading = false;
      });
    }
  }

  Future<void> _resetPassword(BuildContext context) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _auth.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent.'),duration: Duration(seconds: 1)),
        );
      } catch (e) {
        print('Error sending password reset email: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending email. Please try again.'),duration: Duration(seconds: 1)),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    bool shouldLogout = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            'Confirm Logout',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: sh_title_font, // Adjust this to your theme color
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: Colors.grey[800]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: sh_btn), // Adjust color if needed
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.red ), // Adjust color if needed
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout) {
      try {
        await _auth.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout Successful.'),duration: Duration(seconds: 1)),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } catch (e) {
        print('Error signing out: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out. Please try again.'),duration: Duration(seconds: 1)),
        );
      }
    }
  }

  Future<void> _editUserDetail(BuildContext context, String field, String currentValue) async {
    TextEditingController controller = TextEditingController(text: currentValue);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor, // Use app theme background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Rounded corners
          ),
          title: Text(
            'Edit $field',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: sh_title_font, // Use your title font color
            ),
          ),
          content: Container(
            width: double.maxFinite, // Make the dialog full-width
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter new $field',
                hintStyle: TextStyle(color: Colors.grey), // Hint text color
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                  borderSide: BorderSide(color: Colors.grey), // Border color
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: sh_title_font), // Focused border color
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String newValue = controller.text.trim(); // Trim whitespace

                // Validation
                if (_validateField(field, newValue)) {
                  User? user = _auth.currentUser;
                  String fieldName;

                  switch (field) {
                    case 'Username':
                      fieldName = 'name';
                      break;
                    case 'Email':
                      fieldName = 'email';
                      break;
                    case 'Phone Number':
                      fieldName = 'mobileNumber';
                      break;
                    default:
                      fieldName = '';
                  }

                  try {
                    await _firestore.collection('users').doc(user?.uid).update({fieldName: newValue});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$field updated successfully.'),duration: Duration(seconds: 1)),
                    );
                    Navigator.pop(context); // Close dialog after successful update
                    _fetchUserData(); // Fetch updated data and refresh the UI
                  } catch (e) {
                    print('Error updating $field: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating $field. Please try again.'),duration: Duration(seconds: 1)),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid $field.'),duration: Duration(seconds: 1)),
                  );
                }
              },
              child: Text('Save', style: TextStyle(color: sh_btn)), // Button text color
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.red)), // Cancel button color
            ),
          ],
        );
      },
    );
  }

  // Validation method for Username, Email, and Phone Number
  bool _validateField(String field, String value) {
    switch (field) {
      case 'Username':
        return value.isNotEmpty && value.length > 3; // Example: Username must be at least 4 characters
      case 'Email':
        return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value);
      case 'Phone Number':
        return RegExp(r"^\+?[0-9]{10,13}$").hasMatch(value); // Example: International phone numbers with 10-13 digits
      default:
        return false;
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isEditable = false}) {
    return GestureDetector(
      onTap: isEditable ? () => _editUserDetail(context, label, value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.grey[800]),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    User? user = _auth.currentUser;

    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [bluegrey1, sh_title_font], begin: Alignment.topRight, end: Alignment.bottomLeft),
          ),
        ),
        backgroundColor: themeNotifier.isDarkMode ? Colors.black : sh_appbar,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('MY ACCOUNT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sh_title_font)),
          Divider(),

          // Tappable Rows
          _buildDetailRow(context, 'Username', userData['name'] ?? '', isEditable: true),
          Divider(),
          _buildDetailRow(context, 'Email', userData['email'] ?? '', isEditable: true),
          Divider(),
          _buildDetailRow(context, 'Phone Number', userData['mobileNumber'] ?? 'N/A', isEditable: true),
          Divider(),

          // Reset Password Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Password', style: TextStyle(fontSize: 18)),
              ElevatedButton(
                onPressed: () => _resetPassword(context),
                child: Text('Reset Password'),
                style: ElevatedButton.styleFrom(
                  primary: sh_btn,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),

          SizedBox(height: height * 0.5),

          // Logout Button
          Center(
            child: ElevatedButton(
              onPressed: () => _logout(context),
              child: Text('Logout'),
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: width * 0.2, vertical: height * 0.02), // Responsive padding
                textStyle: TextStyle(fontSize: width * 0.05), // Responsive text size
              ),
            ),
          ),

        ],
      ),
    );
  }
}
