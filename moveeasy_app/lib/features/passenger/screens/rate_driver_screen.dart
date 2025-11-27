import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RateDriverScreen extends StatefulWidget {
  final String requestId;
  final String driverId;
  final String driverName;

  const RateDriverScreen({
    super.key,
    required this.requestId,
    required this.driverId,
    required this.driverName,
  });

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _submitting = false;

  final List<String> _feedbackOptions = [
    'Safe Driving',
    'Clean Car',
    'Polite Driver',
    'Good Music',
    'On Time',
  ];
  final Set<String> _selectedFeedback = {};

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      // Fetch passenger details
      final user = FirebaseAuth.instance.currentUser;
      String passengerName = 'Passenger';
      
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          passengerName = userDoc.data()?['name'] ?? 'Passenger';
        }
      }

      await FirebaseFirestore.instance.collection('reviews').add({
        'requestId': widget.requestId,
        'driverId': widget.driverId,
        'passengerId': user?.uid,
        'passengerName': passengerName,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'tags': _selectedFeedback.toList(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
        // Return to dashboard (pop until first route)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Your Trip')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.purple[100],
              child: Text(
                widget.driverName.isNotEmpty ? widget.driverName[0] : 'D',
                style: TextStyle(fontSize: 32, color: Colors.purple[700]),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How was your ride with ${widget.driverName}?',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Feedback Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _feedbackOptions.map((option) {
                final isSelected = _selectedFeedback.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFeedback.add(option);
                      } else {
                        _selectedFeedback.remove(option);
                      }
                    });
                  },
                  selectedColor: Colors.purple[100],
                  checkmarkColor: Colors.purple,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Comment Field
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Additional Comments (Optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SUBMIT REVIEW', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
