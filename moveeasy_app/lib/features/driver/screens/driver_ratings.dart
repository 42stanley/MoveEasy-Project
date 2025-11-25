import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/review_item.dart';

class DriverRatingsScreen extends StatefulWidget {
  const DriverRatingsScreen({super.key});

  @override
  State<DriverRatingsScreen> createState() => _DriverRatingsScreenState();
}

class _DriverRatingsScreenState extends State<DriverRatingsScreen> {
  @override
  Widget build(BuildContext context) {
    final driverId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ratings & Reviews', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Overall Rating & Reviews
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('driverId', isEqualTo: driverId)
                  .orderBy('timestamp', descending: true) // Newest first
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reviews = snapshot.data?.docs ?? [];
                
                // Calculate average rating
                double totalRating = 0.0;
                for (var doc in reviews) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalRating += (data['rating'] ?? 0).toDouble();
                }
                final avgRating = reviews.isEmpty ? 0.0 : totalRating / reviews.length;

                return Column(
                  children: [
                    // Overall Rating
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          const Text('Overall Rating', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Icon(Icons.star, color: Colors.amber[600], size: 40),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Based on ${reviews.length} reviews', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reviews List
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Recent Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    
                    if (reviews.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Center(child: Text('No reviews yet', style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ...reviews.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final timestamp = data['timestamp'] as Timestamp?;
                        final dateStr = timestamp != null
                            ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
                            : 'N/A';
                        
                        return ReviewItem(
                          name: data['passengerName'] ?? 'Passenger',
                          comment: data['comment'] ?? '',
                          rating: (data['rating'] ?? 0).toDouble(),
                          date: dateStr,
                        );
                      }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
