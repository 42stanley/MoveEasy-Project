import 'package:flutter/material.dart';
import '../widgets/trip_item.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Earnings', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Earnings Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green[700]!, Colors.green[500]!]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Column(
                children: [
                  Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('KES 12,450', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _EarningStat(label: 'Today', value: 'KES 4,500'),
                      _EarningStat(label: 'This Week', value: 'KES 28,000'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Chart Placeholder
            const Text('Weekly Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Text('Chart Placeholder', style: TextStyle(color: Colors.grey[400])),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Transactions
            const Text('Recent Trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // Note: TripItem doesn't support isPositive yet, so we'll just use it as is for now or update it later.
            // For now, I'll keep the local _buildTransactionItem if it has unique logic, OR update TripItem.
            // Actually, TripItem is simple. Let's use it for standard trips.
            const TripItem(route: 'Trip to CBD', time: 'Today, 10:30 AM', price: '+ KES 450'),
            const TripItem(route: 'Trip to Westlands', time: 'Today, 09:15 AM', price: '+ KES 300'),
            // _buildTransactionItem('Weekly Payout', 'Yesterday', '- KES 15,000', isPositive: false), // Complex case
            const TripItem(route: 'Trip to Kawangware', time: 'Yesterday, 04:00 PM', price: '+ KES 200'),
          ],
        ),
      ),
    );
  }
}

class _EarningStat extends StatelessWidget {
  final String label;
  final String value;

  const _EarningStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
