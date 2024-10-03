import 'package:ai/screens/result_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';

import '../Utils/ShColors.dart';
import '../services/theme_notifier.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late Future<List<Map<String, dynamic>>> _historyFuture;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  // Track deleted items
  List<String> _deletedItemIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final userId = FirebaseAuth.instance.currentUser?.uid; // Get the current user's ID
    if (userId == null) {
      _showSnackBar('User is not authenticated.');
      return []; // Return empty list if no user is authenticated
    }

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('results')
          .where('userId', isEqualTo: userId) // Filter results for the current user
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        String recognizedText = data['recognizedText'] ?? '';
        List<Map<String, dynamic>> detectedObjects =
            (data['detectedObjects'] as List<dynamic>?)?.map((object) {
              return {
                'name': object['name'] ?? 'Unknown',
                'confidence': object['confidence'] ?? 0.0,
                'boundingPoly': object['boundingPoly'] ?? {},
              };
            }).toList() ?? [];
        return {
          'id': doc.id,
          'imageUrl': data['imageUrl'] ?? '',
          'recognizedText': recognizedText,
          'detectedObjects': detectedObjects,
          'timestamp': data['timestamp'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching history: $e');
      _showSnackBar('Error fetching history. Please try again.');
      return []; // Return empty list on error
    }
  }

  Future<void> _deleteHistoryItem(String docId, String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        await _storage.refFromURL(imageUrl).delete();
      }
      await _firestore.collection('results').doc(docId).delete();
    } catch (e) {
      print('Error deleting image from storage: $e');
      throw e;
    }
  }



  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _confirmDelete(String docId, String imageUrl) async {
    final shouldDelete = await _showConfirmationDialog(
        'Confirm Delete', 'Are you sure you want to delete this history item?');
    if (shouldDelete == true) {
      setState(() {
        _deletedItemIds.add(docId);
        _isLoading = true;
      });

      await _deleteHistoryItem(docId, imageUrl);

      // Wait for a moment to allow fade-out animation to complete
      await Future.delayed(Duration(milliseconds: 300));

      setState(() {
        _isLoading = false;
        _historyFuture =
            _fetchHistory(); // Refresh the history list after deletion
      });
    }
  }

  Future<void> _deleteAllHistory() async {
    final shouldDeleteAll = await _showConfirmationDialog('Confirm Delete All',
        'Are you sure you want to delete all history items?');
    if (shouldDeleteAll == true) {
      setState(() {
        _isLoading = true;
      });

      List<String> failedDeletions = []; // To track any failed deletions
      final snapshot = await _firestore.collection('results').get();

      for (var doc in snapshot.docs) {
        String imageUrl = doc.data()['imageUrl'] ?? '';

        // Use a helper function to handle the deletion and snackbar display
        await _deleteHistoryItem(doc.id, imageUrl).then((_) {

        }).catchError((error) {
          failedDeletions.add(doc.id); // Collect failed deletions
          _showSnackBar('Error deleting item ${doc.id}.');
        });
      }

      setState(() {
        _isLoading = false;
        _historyFuture = _fetchHistory(); // Refresh the history list after deletion
      });

      // Show a summary snackbar after all deletions
      if (failedDeletions.isEmpty) {
        _showSnackBar('All history items deleted successfully!');
      } else {
        _showSnackBar('Some items could not be deleted.');
      }
    }
  }



  Future<bool?> _showConfirmationDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel',style: TextStyle(color: bluegrey5),)),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Delete',style: TextStyle(color: Colors.redAccent),)),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [bluegrey1, sh_title_font], begin: Alignment.topRight, end: Alignment.bottomLeft),
          ),
        ),
        backgroundColor: themeNotifier.isDarkMode ? Colors.black : sh_appbar,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever , color: bluegrey5,),
            onPressed: _deleteAllHistory,
            tooltip: 'Delete All History',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: sh_appbar,));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No history found.'));
          }

          return RefreshIndicator(
            color: sh_appbar,
            onRefresh: () async{
              setState(() {
                _historyFuture = _fetchHistory();
              });
            },
            child: Stack(
              children: [
                ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final result = snapshot.data![index];
                    String formattedDate = _formatTimestamp(result['timestamp']);
                    String imageUrl = result['imageUrl'] ?? '';
                    String recognizedText = result['recognizedText'] ?? '';
                    List<Map<String, dynamic>> detectedObjects =
                        List<Map<String, dynamic>>.from(
                            result['detectedObjects'] ?? []);

                    // Check if this item is marked for deletion
                    final isDeleted = _deletedItemIds.contains(result['id']);

                    return AnimatedOpacity(
                      opacity: isDeleted ? 0.0 : 1.0,
                      duration: Duration(milliseconds: 300), // Fade-out duration
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to the detail screen when tapped
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResultDetailScreen(
                                imageUrl: imageUrl,
                                recognizedText: recognizedText,
                                detectedObjects: detectedObjects,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          color: sh_card,
                          shadowColor: sh_title_font,
                          margin: EdgeInsets.all(8.0),
                          elevation: 4,
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  imageUrl,
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        color: sh_appbar,
                                        value:
                                            loadingProgress.expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    (loadingProgress
                                                            .expectedTotalBytes ??
                                                        1)
                                                : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                        'assets/placeholder_image.jpg',
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover);
                                  },
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: ListTile(
                                  title: Text(
                                    formattedDate,
                                    style: TextStyle(
                                        color: themeNotifier.isDarkMode ? Colors.red : sh_title_font,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Text: ${recognizedText.length > 50 ? recognizedText.substring(0, 50) + '...' : recognizedText}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Objects: ${detectedObjects.length > 0 ? detectedObjects.length.toString() : '0'}',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color:sh_track_red ),
                                onPressed: () {
                                  _confirmDelete(result['id'], imageUrl);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (_isLoading) // Show loading indicator over the list
                  Center(
                    child: CircularProgressIndicator(
                      color: sh_appbar,
                      valueColor: AlwaysStoppedAnimation<Color>(sh_appbar),
                      strokeWidth: 6,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown Date';
    DateTime date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildLabels(List<dynamic> labels) {
    String labelText = labels.map((label) {
      double confidence = label['confidence'] is String
          ? double.tryParse(label['confidence'].toString()) ?? 0.0
          : label['confidence'] ?? 0.0;
      return '${label['label'] ?? 'Unknown'} (${confidence.toStringAsFixed(2)}%)';
    }).join(', ');
    return Text(
      labelText,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
