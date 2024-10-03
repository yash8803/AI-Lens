import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

class DatabaseHelper {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImage(File imageFile) async {
    try {
      // Read the file as bytes
      Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode the image using the 'image' package
      img.Image? decodedImage = img.decodeImage(imageBytes);

      if (decodedImage != null) {
        // Resize the image to a width of 600px while maintaining aspect ratio
        img.Image resizedImage = img.copyResize(decodedImage, width: 600);

        // Encode the resized image back to bytes
        Uint8List resizedBytes = Uint8List.fromList(img.encodeJpg(resizedImage));

        // Compress the image further (optional)
        Uint8List compressedImage = await FlutterImageCompress.compressWithList(
          resizedBytes,
          quality: 80, // Set compression quality (higher means better quality, larger size)
        );

        // Upload to Firebase Storage
        String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        TaskSnapshot uploadTask = await _storage.ref('uploads/$fileName').putData(compressedImage);

        // Get the download URL
        String downloadUrl = await uploadTask.ref.getDownloadURL();
        return downloadUrl;
      } else {
        throw Exception('Failed to decode image.');
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
