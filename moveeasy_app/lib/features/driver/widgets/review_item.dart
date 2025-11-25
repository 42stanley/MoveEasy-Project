import 'package:flutter/material.dart';

class ReviewItem extends StatelessWidget {
  final String name;
  final String comment;
  final int rating;
  final String date;

  const ReviewItem({
    super.key,
    required this.name,
    required this.comment,
    required this.rating,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber[600],
                size: 16,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(comment, style: TextStyle(color: Colors.grey[800])),
        ],
      ),
    );
  }
}
