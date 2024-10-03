import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart'; // For accessing local file storage
import 'package:http/http.dart' as http; // For downloading the image

import '../Utils/ShColors.dart';
import '../services/theme_notifier.dart';

class ResultScreen extends StatelessWidget {
  final String imageUrl;
  final String labels;
  final List<Map<String, dynamic>> detectedObjects;

  ResultScreen({
    required this.imageUrl,
    required this.labels,
    required this.detectedObjects,
  });

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recognition Results',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [bluegrey1, sh_title_font], begin: Alignment.topRight, end: Alignment.bottomLeft),
          ),
        ),
        backgroundColor: themeNotifier.isDarkMode ? Colors.black : sh_appbar,
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: bluegrey5),
            onPressed: () async {
              // Download image and share it with the recognized data
              await _shareImageWithContent(context);
            },
            tooltip: 'Share Results',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the image
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/placeholder_image.jpg', // Ensure this is properly registered in pubspec.yaml
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Display recognized text
              _buildRecognizedTextSection(),
              SizedBox(height: 20),
              // Display detected objects
              _buildDetectedObjectsSection(),
              SizedBox(height: 20),
              // Button to return home
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back to the home screen
                    Navigator.pop(context);
                  },
                  child: Text('Back to Home'),
                  style: ElevatedButton.styleFrom(
                    primary: sh_btn, // Background color
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetectedObjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detected Objects:',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: sh_title_font,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 10),
        detectedObjects.isNotEmpty
            ? ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: detectedObjects.length,
          itemBuilder: (context, index) {
            final object = detectedObjects[index];
            double confidence = object['confidence'] is String
                ? double.tryParse(object['confidence']) ?? 0.0
                : double.parse(object['confidence'].toString());

            return Card(
              margin: EdgeInsets.symmetric(vertical: 5),
              elevation: 2,
              child: ListTile(
                leading: Icon(Icons.label_important, color: _getConfidenceColor(confidence)),
                title: Text(
                  object['name'] ?? 'Unknown',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Confidence: ${confidence.toStringAsFixed(2)}%'),
              ),
            );
          },
        )
            : Text(
          'No objects detected.',
          style: TextStyle(fontSize: 16, color: bluegrey5),
        ),
      ],
    );
  }

  Widget _buildRecognizedTextSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recognized Text:',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: sh_title_font,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sh_card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: bluegrey5),
          ),
          child: SingleChildScrollView(
            child: Text(
              labels.isNotEmpty ? labels : 'No text recognized.', // Handle empty labels
              style: TextStyle(fontSize: 16, color: bluegrey5),
            ),
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) {
      return Colors.green; // High confidence
    } else if (confidence >= 50) {
      return Colors.orange; // Medium confidence
    } else {
      return Colors.red; // Low confidence
    }
  }

  Future<void> _shareImageWithContent(BuildContext context) async {
    try {
      // Download the image from the provided URL
      final response = await http.get(Uri.parse(imageUrl));
      final documentDirectory = await getApplicationDocumentsDirectory();
      final imagePath = '${documentDirectory.path}/shared_image.png';
      final file = File(imagePath);
      await file.writeAsBytes(response.bodyBytes);

      // Prepare content to share
      String shareContent = 'Recognized Text:\n$labels\n\nDetected Objects:\n${detectedObjects.map((obj) => obj['name']).join(', ')}';

      // Share the image and the text content
      Share.shareFiles([imagePath], text: shareContent, subject: 'AI Lens Results');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing image: $e')));
    }
  }
}
