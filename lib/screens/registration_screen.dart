import 'package:ai/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Utils/ShColors.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _email = '';
  String _password = '';
  String _name = '';
  String _mobileNumber = '';

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        // Create user with email and password
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        // Notify user of successful registration
        _showSnackBar('Registration successful!');

        // Navigate to home screen after successful registration
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));

        // Try saving user data in Firestore
        try {
          await _firestore.collection('users').doc(userCredential.user?.uid).set({
            'name': _name,
            'email': _email,
            'mobileNumber': _mobileNumber,
          });
          print('User data saved in Firestore: ${userCredential.user?.uid}');
        } catch (firestoreError) {
          print('Error saving user data in Firestore: $firestoreError');
          _showSnackBar('Registration successful, but failed to save user data.');
        }

      } catch (authError) {
        print('Registration error: $authError');
        _showSnackBar('Registration failed. Please try again.');
      }
    }
  }



  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [bluegrey1, sh_title_font], begin: Alignment.topRight, end: Alignment.bottomLeft),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Create an account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold , color: sh_title_font),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  filled: true, // To enable background color
                  fillColor: sh_card,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: bluegrey5), // Border color when not focused
                    borderRadius: BorderRadius.circular(10.0),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color:Colors.black), // Border color when focused
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  labelText: 'Name',
                  labelStyle: TextStyle( color: sh_appbar),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter your name.' : null,
                onSaved: (value) => _name = value!,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  filled: true, // To enable background color
                  fillColor: sh_card,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: bluegrey5), // Border color when not focused
                    borderRadius: BorderRadius.circular(10.0),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color:Colors.black), // Border color when focused
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  labelText: 'Mobile Number',
                  labelStyle: TextStyle( color: sh_appbar),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter your mobile number.' : null,
                onSaved: (value) => _mobileNumber = value!,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  filled: true, // To enable background color
                  fillColor: sh_card,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: bluegrey5), // Border color when not focused
                    borderRadius: BorderRadius.circular(10.0),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color:Colors.black), // Border color when focused
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  labelText: 'Email',
                  labelStyle: TextStyle( color: sh_appbar),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter your email.' : null,
                onSaved: (value) => _email = value!,
              ),
              SizedBox(height: 16),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  filled: true, // To enable background color
                  fillColor: sh_card,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: bluegrey5), // Border color when not focused
                    borderRadius: BorderRadius.circular(10.0),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color:Colors.black), // Border color when focused
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  labelText: 'Password',
                  labelStyle: TextStyle( color: sh_appbar),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters long.' : null,
                onSaved: (value) => _password = value!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: sh_btn, // Background color
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _register,
                child: Text(
                  'Register',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Go back to login screen
                },
                child: Text(
                  'Already have an account? Login here',
                  style: TextStyle(color: bluegrey5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
