import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:ai/screens/result_screen.dart';
import 'package:ai/screens/history_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

import '../Utils/ShColors.dart';
import '../services/theme_notifier.dart';

class RecognitionScreen extends StatefulWidget {
  @override
  _RecognitionScreenState createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen>
    with SingleTickerProviderStateMixin {
  File? _image;
  bool _isLoading = false;
  final picker = ImagePicker();
  final String apiKey =
      'Enter Your API Key'; // Enter your Google Cloud Vision API Key
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userName;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _image = null;
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _fetchUserName();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchUserName() async {
    User? user = _auth.currentUser; // Get the current user
    if (user != null) {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        userName = userDoc['name']; // Assuming 'name' is the field in Firestore
      });
    }
  }

  Future<File> _resizeImage(File file) async {
    return await compute(_resizeAndEncodeImage, file);
  }

  static Future<File> _resizeAndEncodeImage(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    img.Image resizedImage = img.copyResize(image!, width: 600);
    final resizedFile = File(file.path)
      ..writeAsBytesSync(img.encodeJpg(resizedImage, quality: 150));
    return resizedFile;
  }

  Future<void> _getImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Set the selected image
      });
      //    _showImageOptions(); // Show options for the selected image
    }
  }

  Future<void> _getImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Set the selected image
      });
      //    _showImageOptions(); // Show options for the selected image
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _image = imageFile;
      _isLoading = true;
    });

    // Resize the image
    File resizedImage = await _resizeImage(imageFile);
    try {
      String imageUrl = await uploadImageToStorage(resizedImage);
      await _detectFeatures(resizedImage, imageUrl);
    } catch (e) {
      print("Error: $e");
      _showErrorSnackBar('Failed to process image. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> uploadImageToStorage(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageReference =
    FirebaseStorage.instance.ref().child("images/$fileName.jpg");
    UploadTask uploadTask = storageReference.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _detectFeatures(File imageFile, String imageUrl) async {
    setState(() {
      _isLoading = true;
    });

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';

    final requestBody = jsonEncode({
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [
            {"type": "TEXT_DETECTION", "maxResults": 50},
            {"type": "OBJECT_LOCALIZATION", "maxResults": 15}
          ]
        }
      ]
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String recognizedText =
            data['responses'][0]['textAnnotations']?.first['description'] ??
                'No text found';
        List<Map<String, dynamic>> detectedObjects =
        (data['responses'][0]['localizedObjectAnnotations'] ?? [])
            .map<Map<String, dynamic>>((object) {
          return {
            'name': object['name'],
            'confidence': (object['score'] != null)
                ? (object['score'] * 100).toStringAsFixed(2)
                : '0.00',
            'boundingPoly': object['boundingPoly'] ?? {},
          };
        }).toList();

        // Get the current user
        User? user = _auth.currentUser; // Get the current user
        if (user != null) {
          // Save to Firestore with user ID
          await _firestore.collection('results').add({
            'userId': user.uid, // Store the UID
            'imageUrl': imageUrl,
            'recognizedText': recognizedText,
            'detectedObjects': detectedObjects,
            'timestamp': FieldValue.serverTimestamp(),
          }).catchError((error) {
            print(".............Error saving to Firestore: $error");
          });

          // Navigate to the ResultScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                imageUrl: imageUrl,
                labels: recognizedText,
                detectedObjects: detectedObjects,
              ),
            ),
          ).then((_) {
            setState(() {
              _image = null; // Reset image
            });
          });
        } else {
          _showErrorSnackBar('User not authenticated.');
        }
      } else {
        print("Error: ${response.body}");
        _showErrorSnackBar(
            'Failed to detect features: ${response.reasonPhrase}');
      }
    } catch (e) {
      print("Failed to detect features: $e");
      _showErrorSnackBar(
          'An error occurred during feature detection: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: bluegrey5),
            onPressed: _navigateToHistory,
            tooltip: 'History',
          ),
        ],
        title: Text('AI Lens',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [bluegrey1, sh_title_font],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft),
          ),
        ),
        backgroundColor: themeNotifier.isDarkMode ? Colors.black : sh_appbar,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting Section

                  // Image Section
                  Center(
                    child: _image == null
                        ? GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text('Image Selection Needed'),
                          duration: Duration(seconds: 1),
                        ));
                      },
                      child: Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "No image selected.",
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                        : GestureDetector(
                      onTap: _showImageOptions,
                      child: Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: bluegrey5, width: 2),
                          image: DecorationImage(
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Instructions Section
                  _buildInstructionsCard(),
                ],
              ),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 20),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instructions:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: sh_title_font,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '1. Tap the camera icon to take a photo or select an image from your gallery.\n'
                  '2. Make sure the image is clear and well-lit for better recognition results.\n'
                  '3. After selecting an image, tap on preview image and select given options.\n'
                  '4. Review the results displayed on the next screen.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.black45),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'For best results, avoid using images with too much background clutter.',
                    style: TextStyle(fontSize: 14, color: Colors.black38),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: () {
            _getImageFromCamera();
          },
          tooltip: 'Take Photo',
          heroTag: 'camera',
          child: Icon(Icons.camera_alt),
          backgroundColor: themeNotifier.isDarkMode ? Colors.black : sh_btn,
        ),
        SizedBox(height: 16),
        FloatingActionButton(
          onPressed: () {
            _getImageFromGallery();
          },
          tooltip: 'Select from Gallery',
          heroTag: 'gallery',
          child: Icon(Icons.photo_library),
          backgroundColor: themeNotifier.isDarkMode ? Colors.black : sh_btn,
        ),
      ],
    );
  }

  void _showImageOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)), // Rounded corners

          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Wrap content
              children: [
                // Title
                Text(
                  "Choose an Action",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10), // Spacing
                // Instruction Text
                Text(
                  "What would you like to do with this image?",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20), // Spacing

                // Process Image Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: sh_btn, // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10), // Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _processImage(_image!); // Process the image
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check,
                          color: Colors.white), // Icon for processing
                      SizedBox(width: 8),
                      Text("Process Image",
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                SizedBox(height: 10), // Spacing

                // Remove Image Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.redAccent, // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10), // Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                  onPressed: () {
                    setState(() {
                      _image = null; // Remove the image
                    });
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete,
                          color: Colors.white), // Icon for removal
                      SizedBox(width: 8),
                      Text("Remove Image",
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                SizedBox(height: 10), // Spacing

                // Cancel Button
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(sh_appbar),
                strokeWidth: 6,
              ),
              SizedBox(height: 20),
              Text(
                'Processing image...',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryScreen()),
    ).then((_) {
      setState(() {
        _image = null; // Reset image when returning from history
      });
    });
  }
}
