import 'package:flutter/material.dart';

class TripItem extends StatelessWidget {
  final String route;
  final String time;
  final String price;

  const TripItem({
    super.key,
    required this.route,
    required this.time,
    required this.price,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(route, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }
}
