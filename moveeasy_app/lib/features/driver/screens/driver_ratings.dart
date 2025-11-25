import 'package:flutter/material.dart';
import '../widgets/review_item.dart';
import '../services/driver_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverRatingsScreen extends StatefulWidget {
  const DriverRatingsScreen({super.key});

  @override
  State<DriverRatingsScreen> createState() => _DriverRatingsScreenState();
}

class _DriverRatingsScreenState extends State<DriverRatingsScreen> {
  final _driverService = DriverService();
  late Future<Map<String, dynamic>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'driver1';
    _reviewsFuture = _driverService.getDriverReviews(uid);
  }

  @override
  Widget build(BuildContext context) {
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
            FutureBuilder<Map<String, dynamic>>(
              future: _reviewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data ?? {"rating": 0.0, "count": 0, "reviews": []};
                final reviews = data['reviews'] as List;

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
                              Text('${data['rating']}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Icon(Icons.star, color: Colors.amber[600], size: 40),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Based on ${data['count']} reviews', style: const TextStyle(color: Colors.grey)),
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
                    ...reviews.map((r) => ReviewItem(
                      name: r['name'],
                      comment: r['comment'],
                      rating: r['rating'],
                      date: r['date'],
                    )),
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
