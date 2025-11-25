import 'package:flutter/material.dart';
import '../widgets/review_item.dart';

class DriverRatingsScreen extends StatelessWidget {
  const DriverRatingsScreen({super.key});

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
                      const Text('4.8', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Icon(Icons.star, color: Colors.amber[600], size: 40),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Based on 124 reviews', style: TextStyle(color: Colors.grey)),
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
            const ReviewItem(name: 'John Doe', comment: 'Great driver, very smooth ride!', rating: 5, date: 'Today'),
            const ReviewItem(name: 'Jane Smith', comment: 'Arrived on time, clean bus.', rating: 5, date: 'Yesterday'),
            const ReviewItem(name: 'Michael Brown', comment: 'A bit fast on the corners.', rating: 4, date: '2 days ago'),
            const ReviewItem(name: 'Sarah Wilson', comment: 'Very polite and helpful.', rating: 5, date: 'Last week'),
          ],
        ),
      ),
    );
  }
}
