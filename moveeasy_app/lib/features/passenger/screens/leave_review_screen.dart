import 'package:flutter/material.dart';
import '../../shared/services/ride_service.dart';

class LeaveReviewScreen extends StatefulWidget {
  final String driverId; // In a real app, this would be passed from the trip history
  const LeaveReviewScreen({super.key, required this.driverId});

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  final _commentController = TextEditingController();
  final _rideService = RideService();
  double _rating = 5.0;
  bool _loading = false;

  Future<void> _submitReview() async {
    setState(() => _loading = true);
    try {
      await _rideService.submitReview(
        driverId: widget.driverId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review Submitted!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Your Trip')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('How was your ride?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                  onPressed: () => setState(() => _rating = index + 1.0),
                );
              }),
            ),
            const SizedBox(height: 32),

            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Leave a comment (optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('SUBMIT REVIEW'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
