import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Utils/ShColors.dart';
import '../services/theme_notifier.dart';

class ResultDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String recognizedText;
  final List<Map<String, dynamic>> detectedObjects;

  ResultDetailScreen({
    required this.imageUrl,
    required this.recognizedText,
    required this.detectedObjects,
  });

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Result Details'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [bluegrey1, sh_title_font], begin: Alignment.topRight, end: Alignment.bottomLeft),
          ),
        ),
        backgroundColor: themeNotifier.isDarkMode ? Colors.black : sh_appbar,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display Image
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
              // Display Recognized Text
              _buildRecognizedTextSection(),
              SizedBox(height: 20),
              // Display Detected Objects
              _buildDetectedObjectsSection(),
            ],
          ),
        ),
      ),
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
              recognizedText,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
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
          style: TextStyle(fontSize: 16, color: Colors.grey),
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
}
