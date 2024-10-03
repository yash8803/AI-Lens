// import 'package:camera/camera.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
//
// class RealTimeFaceDetectionScreen extends StatefulWidget {
//   @override
//   _RealTimeFaceDetectionScreenState createState() => _RealTimeFaceDetectionScreenState();
// }
//
// class _RealTimeFaceDetectionScreenState extends State<RealTimeFaceDetectionScreen> {
//   late CameraController _cameraController;
//   late FaceDetector _faceDetector;
//   List<Face> _faces = [];
//   bool _isDetecting = false; // To avoid multiple detections simultaneously
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//     _faceDetector = FaceDetector(
//       options: FaceDetectorOptions(
//         enableClassification: true,
//         minFaceSize: 0.1,
//       ),
//     );
//   }
//
//   Future<void> _initializeCamera() async {
//     final cameras = await availableCameras();
//     _cameraController = CameraController(cameras[0], ResolutionPreset.high);
//     await _cameraController.initialize();
//     _cameraController.startImageStream(_processCameraImage);
//     setState(() {});
//   }
//
//   Future<void> _processCameraImage(CameraImage image) async {
//     if (_isDetecting) return; // Prevent multiple detections
//     _isDetecting = true;
//
//     try {
//       // Convert CameraImage to InputImage
//       final WriteBuffer allBytes = WriteBuffer();
//       for (final Plane plane in image.planes) {
//         allBytes.putUint8List(plane.bytes);
//       }
//       final bytes = allBytes.done().buffer.asUint8List();
//       final size = Size(image.width.toDouble(), image.height.toDouble());
//
//       // Create InputImage using fromBytes
//       final inputImage = InputImage.fromBytes(
//         bytes: bytes,
//         metadata: InputImageMetadata(
//           size: size,
//           rotation: InputImageRotation.rotation0deg, // Adjust based on camera orientation
//           format: InputImageFormat.yuv420,
//           planeData: image.planes.map((Plane plane) {
//             return InputImagePlaneMetadata(
//               bytes: plane.bytes.lengthInBytes,
//               bytesPerRow: plane.bytesPerRow,
//               height: plane.height,
//               width: plane.width,
//             );
//           }).toList(),
//         ),
//       );
//
//       // Detect faces
//       final List<Face> faces = await _faceDetector.processImage(inputImage);
//       setState(() {
//         _faces = faces;
//       });
//     } catch (e) {
//       print("Error processing image: $e");
//     } finally {
//       _isDetecting = false; // Allow the next detection
//     }
//   }
//
//   @override
//   void dispose() {
//     _cameraController.dispose();
//     _faceDetector.close();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Real-Time Face Detection')),
//       body: Column(
//         children: [
//           Expanded(
//             child: _cameraController.value.isInitialized
//                 ? CameraPreview(_cameraController)
//                 : Center(child: CircularProgressIndicator()),
//           ),
//           // Optionally display detected faces
//           Container(
//             padding: EdgeInsets.all(16),
//             child: Text('Detected Faces: ${_faces.length}'),
//           ),
//         ],
//       ),
//     );
//   }
// }
