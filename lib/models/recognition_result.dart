import 'package:cloud_firestore/cloud_firestore.dart';

class RecognitionResult {
  final String imageUrl;
  final List<dynamic> labels;

  RecognitionResult({required this.imageUrl, required this.labels});

  factory RecognitionResult.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return RecognitionResult(
      imageUrl: data['imageUrl'] ?? '',
      labels: data['labels'] ?? [],
    );
  }
}
