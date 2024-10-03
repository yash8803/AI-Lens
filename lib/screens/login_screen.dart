import 'package:ai/screens/home_screen.dart';
import 'package:ai/screens/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Utils/ShColors.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _email = '';
  String _password = '';

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        print('User logged in: ${userCredential.user?.uid}');
        _showSnackBar('Login successful!');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      } catch (e) {
        print('Login error: $e');
        _showSnackBar('Login failed. Please try again.');
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
        title: Text('Login'),
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
          child: AutofillGroup(
            child: ListView(
              children: [
                Text(
                  'Welcome Back!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: sh_title_font),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                TextFormField(
                  autofillHints: [AutofillHints.email], // Enable autofill for email
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: sh_card,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: bluegrey5),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    labelText: 'Email',
                    labelStyle: TextStyle(color: sh_appbar),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email.';
                    }
                    // Regular expression for basic email validation
                    String pattern =
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
                    RegExp regex = RegExp(pattern);
                    if (!regex.hasMatch(value)) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                  onSaved: (value) => _email = value!,
                ),

                // TextFormField(
                //   autofillHints: [AutofillHints.email], // Enable autofill for email
                //   decoration: InputDecoration(
                //     filled: true,
                //     fillColor: sh_card,
                //     enabledBorder: OutlineInputBorder(
                //       borderSide: BorderSide(color: bluegrey5),
                //       borderRadius: BorderRadius.circular(10.0),
                //     ),
                //     focusedBorder: OutlineInputBorder(
                //       borderSide: BorderSide(color: Colors.black),
                //       borderRadius: BorderRadius.circular(10.0),
                //     ),
                //     labelText: 'Email',
                //     labelStyle: TextStyle(color: sh_appbar),
                //   ),
                //
                //   validator: (value) => value!.isEmpty ? 'Please enter your email.' : null,
                //   onSaved: (value) => _email = value!,
                // ),
                SizedBox(height: 16),
                TextFormField(
                  autofillHints: [AutofillHints.password], // Enable autofill for password
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: sh_card,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: bluegrey5),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    labelText: 'Password',
                    labelStyle: TextStyle(color: sh_appbar),
                  ),
                  validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters long.' : null,
                  onSaved: (value) => _password = value!,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: sh_btn,
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: _login,
                  child: Text(
                    'Login',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrationScreen()));
                  },
                  child: Text(
                    'Don’t have an account? Register here',
                    style: TextStyle(color: bluegrey5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

